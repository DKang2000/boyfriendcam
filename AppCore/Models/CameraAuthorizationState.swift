enum CameraAuthorizationState: Equatable {
    case checking
    case denied
    case needsPermission
    case ready
    case restricted

    var allowsCameraUsage: Bool {
        self == .ready
    }
}
