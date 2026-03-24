import AVFoundation
import Combine
import CoreGraphics
import SwiftUI

@MainActor
final class CameraShellViewModel: ObservableObject {
    private enum SelectionPersistence {
        static let templateID = "camera.selectedTemplateID"
        static let persona = "camera.selectedPersona"
        static let captureMode = "camera.selectedCaptureMode"
        static let cropPreviewID = "camera.selectedCropPreviewID"
        static let zoomPreset = "camera.selectedZoomPreset"
    }

    @Published private(set) var authorizationState: CameraAuthorizationState = .checking
    @Published private(set) var isCapturingPhoto = false
    @Published private(set) var isSessionRunning = false
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var latestCapture: CapturedPhoto?
    @Published private(set) var latestPoseFrame: PoseFrame?
    @Published private(set) var latestLightingSummary: LightingAnalysisSummary?
    @Published private(set) var latestMotionGuidance: MotionGuidanceState?
    @Published private(set) var orientationLabel = "Portrait"
    @Published private(set) var previewOrientation: AVCaptureVideoOrientation = .portrait
    @Published private(set) var selectedExperienceMode: CameraExperienceMode = .coach
    @Published private(set) var selectedTemplateID: ShotTemplateID = .fullBody
    @Published private(set) var selectedPersona: CoachPersona = .nice
    @Published private(set) var selectedCaptureMode: CaptureMode = .single
    @Published private(set) var selectedCropPreviewID: CropPreviewID = .none
    @Published private(set) var selectedZoomPreset: CameraZoomPreset = .zoom1
    @Published private(set) var coachingSnapshot: CoachingSnapshot?
    @Published private(set) var historySessions: [CaptureSessionRecord] = []
    @Published var activeReviewSession: CaptureSessionRecord?
    @Published var isHistoryPresented = false
    @Published var isDebugOverlayEnabled = false
    @Published var isExportingSelection = false
    @Published var exportStatusMessage: String?
    @Published private(set) var isVoiceGuidanceEnabled = true

    let cameraSessionController: CameraSessionController

    private let authorizationService: CameraAuthorizationService
    private let motionGuidanceService: MotionGuidanceService
    private let sessionStore: SessionStore
    private let photoLibraryExporter: PhotoLibraryExporter
    private let captureOrchestrator: CaptureOrchestrator
    private let voiceGuidanceController = VoiceGuidanceController()
    private var cancellables = Set<AnyCancellable>()
    private var hasPrepared = false
    private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    private var promptSelectionState = PromptSelectionState()
    private var adaptiveCoachState = AdaptiveCoachState()
    private var lastLoggedUpsideDownLayout = false

    init(
        authorizationService: CameraAuthorizationService,
        cameraSessionController: CameraSessionController,
        motionGuidanceService: MotionGuidanceService,
        sessionStore: SessionStore,
        photoLibraryExporter: PhotoLibraryExporter,
        captureOrchestrator: CaptureOrchestrator
    ) {
        self.authorizationService = authorizationService
        self.cameraSessionController = cameraSessionController
        self.motionGuidanceService = motionGuidanceService
        self.sessionStore = sessionStore
        self.photoLibraryExporter = photoLibraryExporter
        self.captureOrchestrator = captureOrchestrator
        restorePersistedSelections()
        cameraSessionController.setZoomPreset(selectedZoomPreset)

        cameraSessionController.$isCapturingPhoto
            .receive(on: RunLoop.main)
            .assign(to: &$isCapturingPhoto)

        cameraSessionController.$isSessionRunning
            .receive(on: RunLoop.main)
            .assign(to: &$isSessionRunning)

        cameraSessionController.$lastErrorMessage
            .receive(on: RunLoop.main)
            .assign(to: &$lastErrorMessage)

        cameraSessionController.$latestCapture
            .receive(on: RunLoop.main)
            .assign(to: &$latestCapture)

        cameraSessionController.$latestLightingSummary
            .receive(on: RunLoop.main)
            .assign(to: &$latestLightingSummary)

        cameraSessionController.$latestPoseFrame
            .receive(on: RunLoop.main)
            .sink { [weak self] poseFrame in
                guard let self else { return }
                self.latestPoseFrame = poseFrame
                self.refreshCoaching()
            }
            .store(in: &cancellables)

        cameraSessionController.$orientationLabel
            .receive(on: RunLoop.main)
            .assign(to: &$orientationLabel)

        cameraSessionController.$previewOrientation
            .receive(on: RunLoop.main)
            .sink { [weak self] orientation in
                guard let self else { return }
                self.previewOrientation = orientation
                self.motionGuidanceService.updateReferenceOrientation(orientation)
                self.logUpsideDownLayoutIfNeeded()
            }
            .store(in: &cancellables)

        motionGuidanceService.$currentState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.latestMotionGuidance = state
                self.logUpsideDownLayoutIfNeeded()
                self.refreshCoaching()
            }
            .store(in: &cancellables)
    }

    var previewSession: AVCaptureSession {
        cameraSessionController.session
    }

    var selectedTemplate: ShotTemplate {
        ShotTemplateRegistry.template(for: selectedTemplateID)
    }

    var isTemplateMode: Bool {
        selectedExperienceMode == .templates
    }

    var liveCoachingTemplate: ShotTemplate {
        selectedTemplate.adapted(
            to: CropPreviewRegistry.configuration(for: selectedCropPreviewID),
            previewAspectRatio: 9.0 / 16.0
        )
    }

    var primaryPromptText: String {
        coachingSnapshot?.primaryPromptText ?? "Find your subject"
    }

    var secondaryPromptText: String? {
        coachingSnapshot?.secondaryPromptText
    }

    var isReadyForCapture: Bool {
        coachingSnapshot?.isReady ?? false
    }

    var smoothedScoreText: String? {
        guard let score = coachingSnapshot?.smoothedScore else {
            return nil
        }

        return String(format: "Score %.0f", score * 100)
    }

    var lightingStatusText: String? {
        guard let summary = latestLightingSummary else {
            return nil
        }

        guard summary.state != .balanced else {
            return nil
        }

        return summary.state.label
    }

    var levelGuideOffsetRatio: Double {
        let rollDegrees = latestMotionGuidance?.rollDegrees ?? 0
        return max(min(rollDegrees / 18, 1), -1)
    }

    var isUpsideDownLayout: Bool {
        previewOrientation == .portraitUpsideDown
            || latestMotionGuidance?.isPortraitUpsideDown == true
    }

    var subjectFocusPreviewPoint: CGPoint? {
        latestPoseFrame?.preferredSubjectFocusPoint()
    }

    var latestSessionThumbnailURL: URL? {
        activeReviewSession?.selectedFrame?.fileURL
            ?? historySessions.first?.selectedFrame?.fileURL
            ?? latestCapture?.fileURL
    }

    var overlayDebugModeLabel: String {
        let descriptor: PoseRenderDescriptor?

        if selectedExperienceMode == .coach {
            descriptor = latestPoseFrame?.coachRenderDescriptor()
        } else {
            descriptor = latestPoseFrame?.renderDescriptor(for: liveCoachingTemplate)
        }

        return descriptor == nil ? "fallback" : "adaptive"
    }

    func prepareIfNeeded() async {
        if hasPrepared {
            return
        }

        hasPrepared = true
        print("[CameraShellViewModel] prepareIfNeeded")

        if isRunningTests {
            authorizationState = .needsPermission
            return
        }

        authorizationState = authorizationService.currentState()
        print("[CameraShellViewModel] current authorization state = \(authorizationState)")

        if authorizationState.allowsCameraUsage {
            motionGuidanceService.startIfNeeded()
            cameraSessionController.startSession()
        }

        Task {
            await loadHistory()
        }
    }

    func requestCameraAccess() async {
        if isRunningTests {
            authorizationState = .needsPermission
            return
        }

        authorizationState = .checking
        print("[CameraShellViewModel] requestCameraAccess")
        authorizationState = await authorizationService.requestAccess()
        print("[CameraShellViewModel] requestCameraAccess result = \(authorizationState)")

        if authorizationState.allowsCameraUsage {
            motionGuidanceService.startIfNeeded()
            cameraSessionController.startSession()
        }

        Task {
            await loadHistory()
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        print("[CameraShellViewModel] scenePhase = \(String(describing: phase))")
        guard authorizationState.allowsCameraUsage else {
            return
        }

        switch phase {
        case .active:
            motionGuidanceService.startIfNeeded()
            cameraSessionController.startSession()
        case .background, .inactive:
            motionGuidanceService.stop()
            cameraSessionController.stopSession()
        @unknown default:
            motionGuidanceService.stop()
            cameraSessionController.stopSession()
        }
    }

    func capture() {
        Task {
            await captureSelectedMode()
        }
    }

    func selectTemplate(_ templateID: ShotTemplateID) {
        selectedTemplateID = templateID
        persistSelection(templateID.rawValue, forKey: SelectionPersistence.templateID)
        promptSelectionState = PromptSelectionState()
        refreshCoaching()
    }

    func selectExperienceMode(_ mode: CameraExperienceMode) {
        guard selectedExperienceMode != mode else {
            return
        }

        selectedExperienceMode = mode
        adaptiveCoachState = AdaptiveCoachState()
        promptSelectionState = PromptSelectionState()
        refreshCoaching()
    }

    func selectCaptureMode(_ mode: CaptureMode) {
        selectedCaptureMode = mode
        persistSelection(mode.rawValue, forKey: SelectionPersistence.captureMode)
    }

    func selectZoomPreset(_ preset: CameraZoomPreset) {
        selectedZoomPreset = preset
        persistSelection(preset.rawValue, forKey: SelectionPersistence.zoomPreset)
        cameraSessionController.setZoomPreset(preset)
    }

    func updateSubjectFocusDevicePoint(_ point: CGPoint?) {
        cameraSessionController.setSubjectFocusPoint(point)
    }

    func selectCropPreview(_ cropPreviewID: CropPreviewID) {
        selectedCropPreviewID = cropPreviewID
        persistSelection(cropPreviewID.rawValue, forKey: SelectionPersistence.cropPreviewID)
        promptSelectionState = PromptSelectionState()
        refreshCoaching()
    }

    func selectPersona(_ persona: CoachPersona) {
        selectedPersona = persona
        persistSelection(persona.rawValue, forKey: SelectionPersistence.persona)
        refreshCoaching()
    }

    func presentHistory() {
        isHistoryPresented = true
    }

    func toggleVoiceGuidance() {
        isVoiceGuidanceEnabled.toggle()
        voiceGuidanceController.setEnabled(isVoiceGuidanceEnabled)
        print("[VoiceGuidance] enabled = \(isVoiceGuidanceEnabled)")
    }

    func dismissHistory() {
        isHistoryPresented = false
    }

    func openHistorySession(_ session: CaptureSessionRecord) {
        activeReviewSession = session
        isHistoryPresented = false
    }

    func dismissReview() {
        activeReviewSession = nil
        exportStatusMessage = nil
    }

    func selectReviewFrame(_ frameID: UUID) {
        guard var session = activeReviewSession else {
            return
        }

        session.selectFrame(id: frameID)
        activeReviewSession = session

        Task {
            try? await sessionStore.saveSession(session)
            await loadHistory()
        }
    }

    func selectReviewCropPreview(_ cropPreviewID: CropPreviewID) {
        selectedCropPreviewID = cropPreviewID

        guard var session = activeReviewSession else {
            return
        }

        session.updateCropPreview(cropPreviewID)
        activeReviewSession = session

        Task {
            try? await sessionStore.saveSession(session)
            await loadHistory()
        }
    }

    func deleteSession(_ sessionID: UUID) {
        Task {
            do {
                try await sessionStore.deleteSession(id: sessionID)
                if activeReviewSession?.id == sessionID {
                    activeReviewSession = nil
                }
                await loadHistory()
            } catch {
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    func exportSelectedFrame() {
        guard
            let session = activeReviewSession,
            let selectedFrame = session.selectedFrame
        else {
            return
        }

        isExportingSelection = true
        exportStatusMessage = nil

        Task {
            do {
                try await photoLibraryExporter.exportPhoto(at: selectedFrame.fileURL)
                var updatedSession = session
                updatedSession.markExported(frameID: selectedFrame.id)
                activeReviewSession = updatedSession
                try await sessionStore.saveSession(updatedSession)
                await loadHistory()
                exportStatusMessage = "Saved to Photos"
            } catch {
                exportStatusMessage = error.localizedDescription
            }

            isExportingSelection = false
        }
    }

    func toggleDebugOverlay() {
        isDebugOverlayEnabled.toggle()
    }

    private func loadHistory() async {
        do {
            historySessions = try await sessionStore.loadSessions()
            print("[CameraShellViewModel] loaded history count = \(historySessions.count)")
        } catch {
            print("[CameraShellViewModel] loadHistory failed: \(error.localizedDescription)")
        }
    }

    private func captureSelectedMode() async {
        do {
            let captures = try await captureOrchestrator.capture(
                mode: selectedCaptureMode,
                using: cameraSessionController
            )
            let session = CaptureSessionRecord(
                templateID: selectedTemplateID,
                persona: selectedPersona,
                captureMode: selectedCaptureMode,
                cropPreviewID: selectedCropPreviewID,
                frames: captures.map(CapturedFrameRecord.init(photo:)),
                readyScore: coachingSnapshot?.smoothedScore,
                primaryPromptText: coachingSnapshot?.primaryPromptText,
                lighting: latestLightingSummary,
                motion: latestMotionGuidance,
                orientationLabel: orientationLabel
            )

            activeReviewSession = session
            try await sessionStore.saveSession(session)
            await loadHistory()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func refreshCoaching() {
        let signpost = PerformanceSignposts.beginInterval("guidance_update")
        let nextSnapshot: CoachingSnapshot

        switch selectedExperienceMode {
        case .coach:
            let result = AdaptiveCoachEngine.snapshot(
                previousState: adaptiveCoachState,
                poseFrame: latestPoseFrame,
                motion: latestMotionGuidance,
                persona: selectedPersona
            )
            adaptiveCoachState = result.0
            nextSnapshot = result.1
        case .templates:
            let result = CoachingPipeline.snapshot(
                previousState: promptSelectionState,
                template: liveCoachingTemplate,
                poseFrame: latestPoseFrame,
                persona: selectedPersona,
                phoneTiltSignal: latestMotionGuidance?.phoneTiltSignal
            )
            if promptSelectionState != result.0 {
                promptSelectionState = result.0
            }
            nextSnapshot = result.1
        }

        if coachingSnapshot != nextSnapshot {
            coachingSnapshot = nextSnapshot
            voiceGuidanceController.handle(snapshot: nextSnapshot, persona: selectedPersona)
        }
        PerformanceSignposts.endInterval("guidance_update", signpost)
    }

    private func logUpsideDownLayoutIfNeeded() {
        let nextValue = isUpsideDownLayout
        guard nextValue != lastLoggedUpsideDownLayout else {
            return
        }

        lastLoggedUpsideDownLayout = nextValue
        print("[CameraShellViewModel] upsideDownLayout = \(nextValue)")
    }

    private func restorePersistedSelections() {
        let defaults = UserDefaults.standard

        if
            let rawTemplateID = defaults.string(forKey: SelectionPersistence.templateID),
            let templateID = ShotTemplateID(rawValue: rawTemplateID)
        {
            selectedTemplateID = templateID
        }

        if
            let rawCaptureMode = defaults.string(forKey: SelectionPersistence.captureMode),
            let captureMode = CaptureMode(rawValue: rawCaptureMode)
        {
            selectedCaptureMode = captureMode
        }

        if
            let rawCropPreviewID = defaults.string(forKey: SelectionPersistence.cropPreviewID),
            let cropPreviewID = CropPreviewID(rawValue: rawCropPreviewID)
        {
            selectedCropPreviewID = cropPreviewID
        }

        if
            let rawZoomPreset = defaults.string(forKey: SelectionPersistence.zoomPreset),
            let zoomPreset = CameraZoomPreset(rawValue: rawZoomPreset)
        {
            selectedZoomPreset = zoomPreset
        }

        selectedPersona = .nice
    }

    private func persistSelection(_ rawValue: String, forKey key: String) {
        UserDefaults.standard.set(rawValue, forKey: key)
    }
}

@MainActor
private final class VoiceGuidanceController {
    private let synthesizer = AVSpeechSynthesizer()
    private let preferredVoice = VoiceGuidanceController.selectPreferredCoachVoice()
    private var isEnabled = true
    private var lastSpokenText: String?
    private var lastSpokenAt: Date = .distantPast

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    func handle(snapshot: CoachingSnapshot, persona: CoachPersona) {
        guard isEnabled else { return }
        guard shouldSpeak(snapshot: snapshot) else { return }

        let utterance = AVSpeechUtterance(string: snapshot.primaryPromptText)
        utterance.voice = preferredVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = speechRate(for: persona)
        utterance.pitchMultiplier = speechPitch(for: persona)
        utterance.preUtteranceDelay = speechLeadIn(for: persona)
        utterance.prefersAssistiveTechnologySettings = true
        utterance.postUtteranceDelay = speechTail(for: persona)

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // Keep going; speech can still succeed with the default session.
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        synthesizer.speak(utterance)
        lastSpokenText = snapshot.primaryPromptText
        lastSpokenAt = Date()
        print("[VoiceGuidance] speaking: \(snapshot.primaryPromptText)")
    }

    private func shouldSpeak(snapshot: CoachingSnapshot) -> Bool {
        let now = Date()
        let text = snapshot.primaryPromptText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return false }
        guard !snapshot.isReady else { return false }
        guard now.timeIntervalSince(lastSpokenAt) >= 0.9 else { return false }
        guard text != lastSpokenText || now.timeIntervalSince(lastSpokenAt) >= 2.4 else { return false }
        return true
    }

    private func speechRate(for persona: CoachPersona) -> Float {
        switch persona {
        case .nice:
            return 0.43
        case .sassy:
            return 0.50
        case .mean:
            return 0.47
        }
    }

    private func speechPitch(for persona: CoachPersona) -> Float {
        switch persona {
        case .nice:
            return 1.08
        case .sassy:
            return 1.10
        case .mean:
            return 0.93
        }
    }

    private func speechLeadIn(for persona: CoachPersona) -> TimeInterval {
        switch persona {
        case .nice:
            return 0.03
        case .sassy, .mean:
            return 0
        }
    }

    private func speechTail(for persona: CoachPersona) -> TimeInterval {
        switch persona {
        case .nice:
            return 0.08
        case .sassy:
            return 0.04
        case .mean:
            return 0.03
        }
    }

    private static func selectPreferredCoachVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        guard !voices.isEmpty else {
            return nil
        }

        let preferredNames = [
            "Samantha",
            "Ava",
            "Allison",
            "Susan",
            "Karen",
            "Moira",
            "Tessa",
            "Shelley",
            "Sandy",
            "Flo",
            "Kathy",
        ]

        func score(for voice: AVSpeechSynthesisVoice) -> Int {
            var result = 0

            if voice.language == "en-US" {
                result += 1_000
            } else if voice.language.hasPrefix("en") {
                result += 500
            }

            if let preferredIndex = preferredNames.firstIndex(of: voice.name) {
                result += 400 - (preferredIndex * 20)
            }

            if voice.identifier.localizedCaseInsensitiveContains("premium") {
                result += 50
            } else if voice.identifier.localizedCaseInsensitiveContains("enhanced") {
                result += 30
            }

            if voice.identifier.localizedCaseInsensitiveContains("super-compact") {
                result -= 5
            }

            result += Int(voice.quality.rawValue) * 10
            return result
        }

        return voices.max { score(for: $0) < score(for: $1) }
    }
}
