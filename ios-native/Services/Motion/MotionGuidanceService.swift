import AVFoundation
import CoreMotion
import Foundation

final class MotionGuidanceService: ObservableObject {
    @Published private(set) var currentState: MotionGuidanceState?

    private let motionManager = CMMotionManager()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.boyfriendcam.native.motion"
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private var previewOrientation: AVCaptureVideoOrientation = .portrait

    func updateReferenceOrientation(_ orientation: AVCaptureVideoOrientation) {
        previewOrientation = orientation
    }

    func startIfNeeded() {
        guard motionManager.isDeviceMotionAvailable else {
            return
        }

        guard !motionManager.isDeviceMotionActive else {
            return
        }

        motionManager.deviceMotionUpdateInterval = 1 / 15
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let nextState = self.makeState(from: motion)

            DispatchQueue.main.async {
                if self.currentState != nextState {
                    self.currentState = nextState
                }
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    private func makeState(from motion: CMDeviceMotion) -> MotionGuidanceState {
        let rawRollDegrees = motion.attitude.roll * 180 / .pi
        let rawPitchDegrees = motion.attitude.pitch * 180 / .pi
        let gravityX = motion.gravity.x
        let gravityY = motion.gravity.y

        let normalizedRollDegrees: Double
        let normalizedPitchDegrees: Double

        switch previewOrientation {
        case .portraitUpsideDown:
            normalizedRollDegrees = -rawRollDegrees
            normalizedPitchDegrees = -rawPitchDegrees
        default:
            normalizedRollDegrees = rawRollDegrees
            normalizedPitchDegrees = rawPitchDegrees
        }

        let levelState: LevelState
        if abs(normalizedRollDegrees) <= 4 {
            levelState = .level
        } else if normalizedRollDegrees < 0 {
            levelState = .tiltedLeft
        } else {
            levelState = .tiltedRight
        }

        let phoneTiltSignal = Self.phoneTiltSignal(
            normalizedPitchDegrees: normalizedPitchDegrees,
            normalizedRollDegrees: normalizedRollDegrees
        )

        let dominantAxisIsVertical = abs(gravityY) >= abs(gravityX)
        let isPortraitUpsideDown = dominantAxisIsVertical && gravityY >= 0.45
        let isPortraitUpright = dominantAxisIsVertical && gravityY <= -0.45

        return MotionGuidanceState(
            rollDegrees: normalizedRollDegrees,
            pitchDegrees: rawPitchDegrees,
            normalizedPitchDegrees: normalizedPitchDegrees,
            levelState: levelState,
            phoneTiltSignal: phoneTiltSignal,
            isPortraitUpright: isPortraitUpright,
            isPortraitUpsideDown: isPortraitUpsideDown
        )
    }

    static func phoneTiltSignal(
        normalizedPitchDegrees: Double,
        normalizedRollDegrees: Double
    ) -> PhoneTiltPromptSignal? {
        if normalizedPitchDegrees <= -18 {
            return .tiltPhoneDown
        }

        if normalizedPitchDegrees >= 18 {
            return .tiltPhoneUp
        }

        if abs(normalizedRollDegrees) > 4 {
            return .levelPhone
        }

        return nil
    }
}
