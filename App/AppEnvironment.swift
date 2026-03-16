import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    let metricKitObserver: MetricKitObserver
    let cameraAuthorizationService: CameraAuthorizationService
    let poseDetectionService: PoseDetectionService
    let lightingAnalysisService: LightingAnalysisService
    let motionGuidanceService: MotionGuidanceService
    let sessionStore: SessionStore
    let photoLibraryExporter: PhotoLibraryExporter
    let captureOrchestrator: CaptureOrchestrator
    let cameraSessionController: CameraSessionController
    let cameraShellViewModel: CameraShellViewModel

    init() {
        let metricKitObserver = MetricKitObserver()
        let authorizationService = CameraAuthorizationService()
        let poseDetectionService = PoseDetectionService()
        let lightingAnalysisService = LightingAnalysisService()
        let motionGuidanceService = MotionGuidanceService()
        let sessionStore = SessionStore()
        let photoLibraryExporter = PhotoLibraryExporter()
        let captureOrchestrator = CaptureOrchestrator()
        let sessionController = CameraSessionController(
            poseDetectionService: poseDetectionService,
            lightingAnalysisService: lightingAnalysisService
        )

        self.metricKitObserver = metricKitObserver
        cameraAuthorizationService = authorizationService
        self.poseDetectionService = poseDetectionService
        self.lightingAnalysisService = lightingAnalysisService
        self.motionGuidanceService = motionGuidanceService
        self.sessionStore = sessionStore
        self.photoLibraryExporter = photoLibraryExporter
        self.captureOrchestrator = captureOrchestrator
        cameraSessionController = sessionController
        cameraShellViewModel = CameraShellViewModel(
            authorizationService: authorizationService,
            cameraSessionController: sessionController,
            motionGuidanceService: motionGuidanceService,
            sessionStore: sessionStore,
            photoLibraryExporter: photoLibraryExporter,
            captureOrchestrator: captureOrchestrator
        )
    }
}
