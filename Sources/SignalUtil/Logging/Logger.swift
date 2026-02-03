import os

struct Logger <Payload> where Payload: Equatable, Payload: Sendable {
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

    func log (
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

    private func prepareMessage (
        _ level: LogLevel,
        _ source: String?,
        _ text: String,
        _ signal: Signal<Payload>?,
    ) -> String {
        let prefix = "messaging-util [\(level)]"
        let level = String(describing: level)
        let payload = String(describing: Payload.self)
        let location = "\(name) – \(fileId):\(line)"
        let signal = signal?.description ?? "nil"

        let result = [prefix, payload, location, source, text, signal]
            .compactMap { $0 }
            .joined(separator: " | ")

        return result
    }
}
