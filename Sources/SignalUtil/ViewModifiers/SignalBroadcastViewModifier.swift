import Combine
import SwiftUI

struct SignalBroadcastViewModifier <Payload, PayloadPublisher>: ViewModifier
where
Payload: Sendable,
Payload: Equatable,
PayloadPublisher: Publisher<Payload, Never>
{
    private let logger: Logger<Payload>
    @Environment(\.signalLogLevel) private var minLogLevel: LogLevel

    private let eventCompletionHandler: (Signal<Payload>, Error?) -> Void
    private let payloadPublisher: PayloadPublisher
    
    @StateObject private var signalPublisher: Reference<CurrentValueSubject<Signal<Payload>?, Never>> = .init(.init(nil))

    init (
        payloadPublisher: PayloadPublisher,
        fileId: String,
        line: Int,
        eventCompletionHandler: @escaping (Signal<Payload>, Error?) -> Void
    ) {
        self.eventCompletionHandler = eventCompletionHandler
        self.payloadPublisher = payloadPublisher
        self.logger = .init(name: "signalBroadcast", fileId: fileId, line: line)
    }

    func body (content: Content) -> some View {
        content
            .onReceive(payloadPublisher, perform: onNewSignal(payload:))
            .onReceive(signalPublisher.referencedValue, perform: onSignalChanged)
            .environmentObject(signalPublisher)
    }

    private func onNewSignal (payload: Payload) {
        let newId = String(UUID().uuidString.prefix(8))
        let signal = Signal(id: newId, status: .dispatching, payload: payload)

        handleNewSignal(signal)
    }

    private func handleNewSignal (_ signal: Signal<Payload>) {
        logger.log(
            .trace,
            nil,
            "New signal",
            signal,
            minLevel: minLogLevel
        )

        if
            self.signalPublisher.referencedValue.value != nil &&
            self.signalPublisher.referencedValue.value?.status.isCompleted == false
        {
            logger.log(
                .trace,
                nil,
                "Current signal interrupted",
                self.signalPublisher.referencedValue.value,
                minLevel: minLogLevel
            )

            self.signalPublisher.referencedValue.send(
                self.signalPublisher.referencedValue.value?.setStatus(.completed(InterruptedError()))
            )
        }

        self.signalPublisher.referencedValue.send(signal)
    }

    private func onSignalChanged (_ signal: Signal<Payload>?) {
        if let signal, signal.status.isCompleted {
            logger.log(
                .trace,
                nil,
                "Signal completed",
                signal,
                minLevel: minLogLevel
            )

            eventCompletionHandler(signal, signal.status.error)
        }
    }
}

public extension View {
    func signalBroadcast <Payload, PayloadPublisher> (
        _ payloadPublisher: PayloadPublisher,
        fileId: String = #fileID,
        line: Int = #line,
        onEventCompletion: @escaping (Signal<Payload>, Error?) -> Void = { _, _ in }
    ) -> some View
    where
    Payload: Sendable,
    PayloadPublisher: Publisher<Payload, Never>
    {
        modifier(
            SignalBroadcastViewModifier<Payload, PayloadPublisher>(
                payloadPublisher: payloadPublisher,
                fileId: fileId,
                line: line,
                eventCompletionHandler: onEventCompletion
            )
        )
    }
}
