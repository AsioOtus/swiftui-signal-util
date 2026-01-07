public typealias SignalHandler <Payload> = (Signal<Payload>) async throws -> (ProcessingAction, Payload) where Payload: Equatable
