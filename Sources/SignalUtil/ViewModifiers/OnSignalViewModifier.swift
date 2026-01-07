import SwiftUI

struct OnSignalViewModifier <Payload>: ViewModifier where Payload: Sendable, Payload: Equatable {
    private let logger: Logger
    @Environment(\.signalLogLevel) private var minLogLevel: LogLevel

    @EnvironmentObject private var signalReference: Reference<Signal<Payload>?>
    @State private var lastReceivedSignal: Signal<Payload>?
    private let handler: SignalHandler<Payload>
    private let allowedPayloads: [Payload]?

    init (
        allowedPayloads: [Payload]?,
        fileId: String,
        line: Int,
        handler: @escaping SignalHandler<Payload>
    ) {
        self.allowedPayloads = allowedPayloads
        self.handler = handler
        self.logger = .init(name: "onSignal", fileId: fileId, line: line)
    }

    func body (content: Content) -> some View {
        content
            .onChange(of: signalReference.referencedValue) {
                handle($0, "onChange")
            }
            .onAppear {
                handle("onAppear")
            }
    }

    private func handle (_ source: String) {
        handle(signalReference.referencedValue, source)
    }

    private func handle (_ signal: Signal<Payload>?, _ source: String) {
        guard let signal = signal else {
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
                "Duplicated signal",
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
                "Processing signal",
                signal,
                minLevel: minLogLevel
            )
            return
        }

        if signal.status.isCompleted {
            logger.log(
                .debug,
                source,
                "Completed signal",
                signal,
                minLevel: minLogLevel
            )
            return
        }

        lastReceivedSignal = signal

        logger.log(
            .debug,
            source,
            "Signal handling started - environment state",
            signalReference.referencedValue,
            minLevel: minLogLevel
        )

        let processingSignal = signal.setStatus(.processing)
        signalReference.referencedValue = processingSignal

        logger.log(
            .info,
            source,
            "Signal handling started",
            processingSignal,
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
                "Handled signal - environment state",
                signalReference.referencedValue,
                minLevel: minLogLevel
            )

            signalReference.referencedValue = handledSignal

            logger.log(
                .info,
                source,
                "Handled signal",
                handledSignal,
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
