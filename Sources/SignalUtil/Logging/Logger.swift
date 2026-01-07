import os

struct Logger {
    let logger: os.Logger
    let name: String
    let fileId: String
    let line: Int

    init (
        name: String,
        fileId: String,
        line: Int
    ) {
        self.name = name
        self.fileId = fileId
        self.line = line
        self.logger = .init()
    }

    func log <Payload> (
        _ level: LogLevel,
        _ source: String?,
        _ text: String,
        _ signal: Signal<Payload>?,
        minLevel: LogLevel
    ) {
        guard level.rawValue >= minLevel.rawValue else { return }
        let preparedMessage = prepareMessage(level, source, text, signal)

        switch level {
        case .all:      break
        case .notice:   logger.notice("\(preparedMessage)")
        case .debug:    logger.debug("\(preparedMessage)")
        case .trace:    logger.trace("\(preparedMessage)")
        case .info:     logger.info("\(preparedMessage)")
        case .error:    logger.error("\(preparedMessage)")
        case .warning:  logger.warning("\(preparedMessage)")
        case .fault:    logger.fault("\(preparedMessage)")
        case .critical: logger.critical("\(preparedMessage)")
        case .none:     break
        }
    }

    private func prepareMessage <Payload> (
        _ level: LogLevel,
        _ source: String?,
        _ text: String,
        _ signal: Signal<Payload>?,
    ) -> String {
        let level = String(describing: level)
        let location = "\(name) (\(fileId):\(line))"
        let signal = signal?.description ?? "nil"

        let result = ["messaging-util [\(level)]", location, source, text, signal]
            .compactMap { $0 }
            .joined(separator: " | ")

        return result
    }
}
