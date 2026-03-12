import VisionCamera

@objc(PoseLandmarksPlugin)
public class PoseLandmarksPlugin: FrameProcessorPlugin {
    private var mediaPipeFrameProcessor: MediaPipeFrameProcessor

    override public init(
        proxy: VisionCameraProxyHolder,
        options: [AnyHashable: Any]? = [:]
    ) {
        let numPoses = options?["numPoses"] as? Int
        let minPoseDetectionConfidence = options?["minPoseDetectionConfidence"] as? Float
        let minPosePresenceConfidence = options?["minPosePresenceConfidence"] as? Float
        let minTrackingConfidence = options?["minTrackingConfidence"] as? Float
        let modelPath = Bundle.main.path(
            forResource: "pose_landmarker_full",
            ofType: "task"
        )

        mediaPipeFrameProcessor = MediaPipeFrameProcessor(
            numPoses: numPoses,
            modelPath: modelPath,
            minTrackingConfidence: minTrackingConfidence,
            minPosePresenceConfidence: minPosePresenceConfidence,
            minPoseDetectionConfidence: minPoseDetectionConfidence
        )

        super.init(proxy: proxy, options: options)
    }

    override public func callback(
        _ frame: Frame,
        withArguments _: [AnyHashable: Any]?
    ) -> Any {
        mediaPipeFrameProcessor.process(frame)
    }
}
