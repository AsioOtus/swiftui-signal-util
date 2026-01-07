import SwiftUI

// MARK: - Return (ProcessingAction, Payload)
public extension View {
    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping (Signal<Payload>) async throws -> (ProcessingAction, Payload)
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line,
                handler: action
            )
        )
    }

    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping (Payload) async throws -> (ProcessingAction, Payload)
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) {
                try await action($0.payload)
            }
        )
    }

    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping () async throws -> (ProcessingAction, Payload)
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) { _ in
                try  await action()
            }
        )
    }
}

// MARK: - Return ProcessingAction
public extension View {
    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping (Signal<Payload>) async throws -> ProcessingAction
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) {
                let processingAction = try await action($0)
                return (processingAction, $0.payload)

            }
        )
    }

    func onSignal <Payload> (
        of _: Payload.Type,
        allowed: [Payload]? = nil,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping (Payload) async throws -> ProcessingAction
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) {
                let processingAction = try await action($0.payload)
                return (processingAction, $0.payload)

            }
        )
    }

    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping () async throws -> ProcessingAction
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) {
                let processingAction = try await action()
                return (processingAction, $0.payload)

            }
        )
    }
}

// MARK: - Return Payload
public extension View {
    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        isCompleting: Bool = false,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping (Signal<Payload>) async throws -> Payload
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) {
                let content = try await action($0)
                return (isCompleting ? .complete : .continue, content)
            }
        )
    }

    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        isCompleting: Bool = false,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping (Payload) async throws -> Payload
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) {
                let content = try await action($0.payload)
                return (isCompleting ? .complete : .continue, content)
            }
        )
    }

    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        isCompleting: Bool = false,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping () async throws -> Payload
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) { _ in
                let content = try await action()
                return (isCompleting ? .complete : .continue, content)
            }
        )
    }
}

// MARK: - Return Void
public extension View {
    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        isCompleting: Bool = false,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping (Signal<Payload>) async throws -> Void
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) {
                try await action($0)
                return (isCompleting ? .complete : .continue, $0.payload)
            }
        )
    }

    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        isCompleting: Bool = false,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping (Payload) async throws -> Void
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) {
                try await action($0.payload)
                return (isCompleting ? .complete : .continue, $0.payload)
            }
        )
    }

    func onSignal <Payload> (
        of _: Payload.Type = Payload.self,
        allowed: [Payload]? = nil,
        isCompleting: Bool = false,
        fileId: String = #fileID,
        line: Int = #line,
        perform action: @escaping () async throws -> Void
    ) -> some View where Payload: Sendable, Payload: Equatable {
        modifier(
            OnSignalViewModifier<Payload>(
                allowedPayloads: allowed,
                fileId: fileId,
                line: line
            ) {
                try await action()
                return (isCompleting ? .complete : .continue, $0.payload)
            }
        )
    }
}
