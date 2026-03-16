import AVFoundation

struct CameraAuthorizationService {
    func currentState() -> CameraAuthorizationState {
        map(status: AVCaptureDevice.authorizationStatus(for: .video))
    }

    func requestAccess() async -> CameraAuthorizationState {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized, .denied, .restricted:
            return map(status: status)
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .ready : .denied
        @unknown default:
            return .denied
        }
    }

    func map(status: AVAuthorizationStatus) -> CameraAuthorizationState {
        switch status {
        case .authorized:
            return .ready
        case .notDetermined:
            return .needsPermission
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
}
