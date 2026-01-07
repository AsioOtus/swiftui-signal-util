import Combine
import SwiftUI

struct SignalBroadcastViewModifier <Payload, PayloadPublisher>: ViewModifier
where
Payload: Sendable,
Payload: Equatable,
PayloadPublisher: Publisher<Payload, Never>
{
    private let logger: Logger
    @Environment(\.signalLogLevel) private var minLogLevel: LogLevel

    private let eventCompletionHandler: (Signal<Payload>, Error?) -> Void
    private let payloadPublisher: PayloadPublisher
    
    @StateObject private var signal: Reference<Signal<Payload>?> = .init(nil)

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
            .onChange(of: signal.referencedValue, perform: onSignalChanged)
            .environmentObject(signal)
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

        if self.signal.referencedValue != nil && self.signal.referencedValue?.status.isCompleted == false {
            logger.log(
                .trace,
                nil,
                "Current signal interrupted",
                self.signal.referencedValue,
                minLevel: minLogLevel
            )

            self.signal.referencedValue = self.signal.referencedValue?.setStatus(.completed(InterruptedError()))
        }

        self.signal.referencedValue = signal
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
