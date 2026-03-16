import AVFoundation
import CoreGraphics
import ImageIO
import Vision

final class PoseDetectionService {
    private let minimumAnalysisInterval: Double
    private let requestHandler = VNSequenceRequestHandler()
    private let confidenceThreshold: CGFloat

    private var lastAnalysisTimestamp = CMTime.invalid

    init(
        framesPerSecond: Double = 5,
        confidenceThreshold: CGFloat = PoseFrameMapper.confidenceThreshold
    ) {
        minimumAnalysisInterval = 1 / max(framesPerSecond, 1)
        self.confidenceThreshold = confidenceThreshold
    }

    func process(
        sampleBuffer: CMSampleBuffer,
        orientation: AVCaptureVideoOrientation
    ) -> PoseFrame? {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        guard shouldAnalyzeFrame(at: timestamp) else {
            return nil
        }

        let request = VNDetectHumanBodyPoseRequest()

        do {
            try requestHandler.perform(
                [request],
                on: sampleBuffer,
                orientation: orientation.cgImagePropertyOrientationForVision
            )
        } catch {
            return PoseFrame(landmarks: [:], timestampSeconds: timestamp.seconds)
        }

        guard let observation = request.results?.first else {
            return PoseFrame(landmarks: [:], timestampSeconds: timestamp.seconds)
        }

        let recognizedPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
        do {
            recognizedPoints = try observation.recognizedPoints(.all)
        } catch {
            return PoseFrame(landmarks: [:], timestampSeconds: timestamp.seconds)
        }

        let candidates = PoseLandmarkName.allCases.reduce(into: [PoseLandmarkName: PoseLandmarkCandidate]()) {
            partialResult,
            landmarkName in
            guard
                let jointName = landmarkName.visionJointName,
                let point = recognizedPoints[jointName]
            else {
                return
            }

            partialResult[landmarkName] = PoseLandmarkCandidate(
                x: point.location.x,
                y: point.location.y,
                confidence: CGFloat(point.confidence)
            )
        }

        return PoseFrameMapper.map(
            candidates: candidates,
            timestampSeconds: timestamp.seconds,
            confidenceThreshold: confidenceThreshold
        )
    }

    private func shouldAnalyzeFrame(at timestamp: CMTime) -> Bool {
        if !lastAnalysisTimestamp.isValid {
            lastAnalysisTimestamp = timestamp
            return true
        }

        let elapsed = timestamp.seconds - lastAnalysisTimestamp.seconds
        guard elapsed >= minimumAnalysisInterval else {
            return false
        }

        lastAnalysisTimestamp = timestamp
        return true
    }
}

private extension PoseLandmarkName {
    var visionJointName: VNHumanBodyPoseObservation.JointName? {
        switch self {
        case .nose:
            return .nose
        case .leftEye:
            return .leftEye
        case .rightEye:
            return .rightEye
        case .leftEar:
            return .leftEar
        case .rightEar:
            return .rightEar
        case .leftShoulder:
            return .leftShoulder
        case .rightShoulder:
            return .rightShoulder
        case .leftElbow:
            return .leftElbow
        case .rightElbow:
            return .rightElbow
        case .leftWrist:
            return .leftWrist
        case .rightWrist:
            return .rightWrist
        case .leftHip:
            return .leftHip
        case .rightHip:
            return .rightHip
        case .leftKnee:
            return .leftKnee
        case .rightKnee:
            return .rightKnee
        case .leftAnkle:
            return .leftAnkle
        case .rightAnkle:
            return .rightAnkle
        case .leftEyeInner,
                .leftEyeOuter,
                .rightEyeInner,
                .rightEyeOuter,
                .leftMouth,
                .rightMouth,
                .leftPinky,
                .rightPinky,
                .leftIndex,
                .rightIndex,
                .leftThumb,
                .rightThumb,
                .leftHeel,
                .rightHeel,
                .leftFootIndex,
                .rightFootIndex:
            return nil
        }
    }
}

private extension AVCaptureVideoOrientation {
    var cgImagePropertyOrientationForVision: CGImagePropertyOrientation {
        switch self {
        case .portrait:
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeRight:
            return .down
        case .landscapeLeft:
            return .up
        @unknown default:
            return .right
        }
    }
}
