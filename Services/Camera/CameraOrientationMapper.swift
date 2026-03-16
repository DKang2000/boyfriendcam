import AVFoundation
import UIKit

enum CameraOrientationMapper {
    static func videoOrientation(
        for deviceOrientation: UIDeviceOrientation
    ) -> AVCaptureVideoOrientation? {
        switch deviceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return nil
        }
    }

    static func label(for deviceOrientation: UIDeviceOrientation) -> String {
        switch deviceOrientation {
        case .portrait:
            return "Portrait"
        case .portraitUpsideDown:
            return "Portrait Upside Down"
        case .landscapeLeft:
            return "Landscape Left"
        case .landscapeRight:
            return "Landscape Right"
        case .faceDown:
            return "Face Down"
        case .faceUp:
            return "Face Up"
        default:
            return "Unknown"
        }
    }
}
