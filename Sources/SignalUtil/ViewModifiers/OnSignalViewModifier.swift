import SwiftUI

struct OnSignalViewModifier <Payload>: ViewModifier where Payload: Sendable, Payload: Equatable {
    private let logger: Logger
    @Environment(\.signalLogLevel) private var minLogLevel: LogLevel

    @EnvironmentObject private var signalReference: Reference<Signal<Payload>?>
    @State private var lastReceivedSignal: Signal<Payload>?
    private let handler: SignalHandler<Payload>
    private let allowedPayloads: [Payload]?

    private let location: String

    init (
        allowedPayloads: [Payload]?,
        fileId: String,
        line: Int,
        handler: @escaping SignalHandler<Payload>
    ) {
        self.allowedPayloads = allowedPayloads
        self.handler = handler
        self.logger = .init(name: "onSignal", fileId: fileId, line: line)
        self.location = "\(fileId):\(line)"
    }

    func body (content: Content) -> some View {
        content
            .onChange(of: signalReference.referencedValue) { _ in
                process("onChange")
            }
            .onAppear {
                process("onAppear")
            }
    }

    private func process (_ source: String) {
        guard let signal = signalReference.referencedValue else {
            logger.log(
                .notice,
                source,
                "nil signal",
                Signal<Payload>?.none,
                minLevel: minLogLevel
            )
            return
        }

        if signal.id == lastReceivedSignal?.id {
            logger.log(
                .notice,
                source,
                "Duplicate",
                signal,
                minLevel: minLogLevel
            )
            return
        }

        if let allowedPayloads, !allowedPayloads.contains(signal.payload) {
            logger.log(
                .notice,
                source,
                "Prohibited payload",
                signal,
                minLevel: minLogLevel
            )
            return
        }

        if signal.status.isProcessing {
            logger.log(
                .debug,
                source,
                "Already processing",
                signal,
                minLevel: minLogLevel
            )
            return
        }

        if signal.status.isCompleted {
            logger.log(
                .debug,
                source,
                "Already completed",
                signal,
                minLevel: minLogLevel
            )
            return
        }

        lastReceivedSignal = signal

        logger.log(
            .debug,
            source,
            "Processing started – pre",
            signal,
            minLevel: minLogLevel
        )

        let processingSignal = signal.setStatus(.processing(location))
        signalReference.referencedValue = processingSignal

        logger.log(
            .info,
            source,
            "Processing started – post",
            signalReference.referencedValue,
            minLevel: minLogLevel
        )

        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)

            let (processingAction, Payload) = await handle(signal)

            if lastReceivedSignal?.id == signal.id, lastReceivedSignal?.payload != Payload {
                lastReceivedSignal = nil
            }

            let handledSignal = Signal<Payload>(
                id: signal.id,
                status: processingAction.signalStatus,
                payload: Payload
            )

            logger.log(
                .debug,
                source,
                "Processing completed – pre",
                signalReference.referencedValue,
                minLevel: minLogLevel
            )

            signalReference.referencedValue = handledSignal

            logger.log(
                .info,
                source,
                "Processing completed – post",
                signalReference.referencedValue,
                minLevel: minLogLevel
            )
        }
    }

    private func handle (_ signal: Signal<Payload>) async -> (ProcessingAction, Payload) {
        do {
            return try await handler(signal)
        } catch {
            return (.fail(error), signal.payload)
        }
    }
}
