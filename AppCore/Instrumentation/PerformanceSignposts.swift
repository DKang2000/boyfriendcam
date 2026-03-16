import OSLog
import MetricKit

enum PerformanceSignposts {
    private static let logger = Logger(
        subsystem: "com.boyfriendcam.native",
        category: "Performance"
    )

    private static let signposter = OSSignposter(logger: logger)

    static func beginInterval(_ name: StaticString) -> OSSignpostIntervalState {
        signposter.beginInterval(name)
    }

    static func endInterval(_ name: StaticString, _ state: OSSignpostIntervalState) {
        signposter.endInterval(name, state)
    }

    static func emitEvent(_ name: StaticString) {
        signposter.emitEvent(name)
    }
}

final class MetricKitObserver: NSObject, MXMetricManagerSubscriber {
    private let logger = Logger(
        subsystem: "com.boyfriendcam.native",
        category: "MetricKit"
    )

    override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }

    deinit {
        MXMetricManager.shared.remove(self)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        logger.notice("Received \(payloads.count, privacy: .public) MetricKit metric payload(s)")
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        logger.notice("Received \(payloads.count, privacy: .public) MetricKit diagnostic payload(s)")
    }
}
