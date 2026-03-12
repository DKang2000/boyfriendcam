import MediaPipeTasksVision
import VisionCamera

final class MediaPipeFrameProcessor {
    private let landmarkNames = [
        "nose", "leftEyeInner", "leftEye", "leftEyeOuter",
        "rightEyeInner", "rightEye", "rightEyeOuter", "leftEar",
        "rightEar", "leftMouth", "rightMouth", "leftShoulder",
        "rightShoulder", "leftElbow", "rightElbow", "leftWrist",
        "rightWrist", "leftPinky", "rightPinky", "leftIndex",
        "rightIndex", "leftThumb", "rightThumb", "leftHip",
        "rightHip", "leftKnee", "rightKnee", "leftAnkle",
        "rightAnkle", "leftHeel", "rightHeel", "leftFootIndex",
        "rightFootIndex"
    ]
    private let poseLandmarkerOptions: PoseLandmarkerOptions
    private lazy var poseLandmarker: PoseLandmarker? = {
        do {
            return try PoseLandmarker(options: self.poseLandmarkerOptions)
        } catch {
            return nil
        }
    }()

    init(
        numPoses: Int?,
        modelPath: String?,
        minTrackingConfidence: Float?,
        minPosePresenceConfidence: Float?,
        minPoseDetectionConfidence: Float?
    ) {
        poseLandmarkerOptions = PoseLandmarkerOptions()
        poseLandmarkerOptions.runningMode = .video

        if let numPoses {
            poseLandmarkerOptions.numPoses = numPoses
        }

        if let modelPath {
            poseLandmarkerOptions.baseOptions.modelAssetPath = modelPath
        }

        if let minTrackingConfidence {
            poseLandmarkerOptions.minTrackingConfidence = minTrackingConfidence
        }

        if let minPosePresenceConfidence {
            poseLandmarkerOptions.minPosePresenceConfidence = minPosePresenceConfidence
        }

        if let minPoseDetectionConfidence {
            poseLandmarkerOptions.minPoseDetectionConfidence = minPoseDetectionConfidence
        }
    }

    func process(_ frame: Frame) -> [[String: [String: Double]]] {
        do {
            let image = try MPImage(
                sampleBuffer: frame.buffer,
                orientation: frame.orientation
            )
            let result = try poseLandmarker?.detect(
                videoFrame: image,
                timestampInMilliseconds: Int(frame.timestamp)
            )

            return result?.landmarks.map { pose in
                pose.enumerated().reduce(
                    into: [String: [String: Double]]()
                ) { result, item in
                    let (index, landmark) = item
                    let landmarkName = landmarkNames[index]

                    result[landmarkName] = [
                        "x": Double(landmark.x),
                        "y": Double(landmark.y),
                        "z": Double(landmark.z),
                        "visibility": landmark.visibility?.doubleValue ?? 0.0,
                        "presence": landmark.presence?.doubleValue ?? 0.0
                    ]
                }
            } ?? []
        } catch {
            return []
        }
    }
}
