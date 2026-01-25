public enum SignalStatus: Sendable {
    case dispatching
    case processing(String)
    case completed(Error?)

    var isDispatching: Bool {
        if case .dispatching = self { true }
        else { false }
    }

    var isProcessing: Bool {
        if case .processing = self { true }
        else { false }
    }

    var isCompleted: Bool {
        if case .completed = self { true }
        else { false }
    }

    var error: Error? {
        if case .completed(let error) = self { error }
        else { nil }
    }
}

extension SignalStatus: Equatable {
    public static func == (lhs: SignalStatus, rhs: SignalStatus) -> Bool {
        switch (lhs, rhs) {
        case (.dispatching, .dispatching): true
        case (.processing, .processing): true
        case (.completed(.none), .completed(.none)): true
        case (.completed(.some(let lError)), .completed(.some(let rError))): type(of: lError) == type(of: rError)
        default: false
        }
    }
}
