import AVFoundation
import Combine
import Foundation
import OSLog
import UIKit

final class CameraSessionController: NSObject, ObservableObject {
    private static let logger = Logger(
        subsystem: "com.boyfriendcam.native",
        category: "CameraSession"
    )

    @Published private(set) var isCapturingPhoto = false
    @Published private(set) var isSessionRunning = false
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var latestCapture: CapturedPhoto?
    @Published private(set) var latestPoseFrame: PoseFrame?
    @Published private(set) var latestLightingSummary: LightingAnalysisSummary?
    @Published private(set) var orientationLabel = "Portrait"
    @Published private(set) var previewOrientation: AVCaptureVideoOrientation = .portrait
    @Published private(set) var selectedZoomPreset: CameraZoomPreset = .zoom1

    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let poseDetectionService: PoseDetectionService
    private let lightingAnalysisService: LightingAnalysisService
    private let sessionQueue = DispatchQueue(
        label: "com.boyfriendcam.native.camera.session",
        qos: .userInitiated
    )
    private let videoOutputQueue = DispatchQueue(
        label: "com.boyfriendcam.native.camera.video-output",
        qos: .userInitiated
    )
    private let liveAnalysisEnabled = true
    private let stateLock = NSLock()

    private var hasConfiguredSession = false
    private var isAnalysisActive = false
    private var isPhotoCaptureInFlight = false
    private var photoCaptureSignpostState: OSSignpostIntervalState?
    private var currentVideoOrientation: AVCaptureVideoOrientation = .portrait
    private var pendingPhotoContinuation: CheckedContinuation<CapturedPhoto, Error>?
    private var currentVideoInput: AVCaptureDeviceInput?
    private var requestedZoomPreset: CameraZoomPreset = .zoom1
    private var requestedSubjectFocusPoint: CGPoint?
    private var lastAppliedSubjectFocusPoint: CGPoint?
    private var lastAppliedSubjectFocusAt: Date = .distantPast

    init(
        poseDetectionService: PoseDetectionService,
        lightingAnalysisService: LightingAnalysisService
    ) {
        self.poseDetectionService = poseDetectionService
        self.lightingAnalysisService = lightingAnalysisService
        super.init()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )

        apply(deviceOrientation: UIDevice.current.orientation)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.session.isRunning else { return }
            print("[CameraSession] startSession requested")

            let startupSignpost = PerformanceSignposts.beginInterval("camera_startup")

            do {
                try self.configureSessionIfNeeded()
            } catch {
                print("[CameraSession] configureSessionIfNeeded failed: \(error.localizedDescription)")
                self.publish(errorMessage: error.localizedDescription)
                PerformanceSignposts.endInterval("camera_startup", startupSignpost)
                return
            }

            let previewSignpost = PerformanceSignposts.beginInterval("preview_start")
            self.session.startRunning()
            self.isAnalysisActive = false
            print("[CameraSession] session.startRunning returned. isRunning=\(self.session.isRunning)")
            PerformanceSignposts.endInterval("preview_start", previewSignpost)
            PerformanceSignposts.endInterval("camera_startup", startupSignpost)

            DispatchQueue.main.async {
                self.isSessionRunning = true
                self.lastErrorMessage = nil
            }

            self.sessionQueue.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self, self.session.isRunning else { return }
                guard self.liveAnalysisEnabled else { return }
                self.isAnalysisActive = true
                print("[CameraSession] live analysis activated")
                Self.logger.notice("Live analysis activated")
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            print("[CameraSession] stopSession requested")

            self.session.stopRunning()
            self.isAnalysisActive = false

            DispatchQueue.main.async {
                self.isSessionRunning = false
                self.latestPoseFrame = nil
                self.latestLightingSummary = nil
            }
        }
    }

    func takePhoto() {
        Task {
            _ = try? await capturePhotoAsync()
        }
    }

    func setZoomPreset(_ preset: CameraZoomPreset) {
        requestedZoomPreset = preset

        DispatchQueue.main.async {
            self.selectedZoomPreset = preset
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            do {
                try self.applyZoomPreset(preset)
                DispatchQueue.main.async {
                    self.lastErrorMessage = nil
                }
            } catch {
                self.publish(errorMessage: error.localizedDescription)
            }
        }
    }

    func capturePhotoAsync() async throws -> CapturedPhoto {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraSessionError.sessionDeallocated)
                    return
                }

                self.capturePhoto(continuation: continuation)
            }
        }
    }

    func setSubjectFocusPoint(_ point: CGPoint?) {
        let clampedPoint = point.map { point in
            CGPoint(
                x: min(max(point.x, 0), 1),
                y: min(max(point.y, 0), 1)
            )
        }

        requestedSubjectFocusPoint = clampedPoint

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.applySubjectFocusIfNeeded(point: clampedPoint, force: false)
        }
    }

    private func capturePhoto(
        continuation: CheckedContinuation<CapturedPhoto, Error>
    ) {
        stateLock.lock()
        let canCapture = !isPhotoCaptureInFlight
        if canCapture {
            isPhotoCaptureInFlight = true
            photoCaptureSignpostState = PerformanceSignposts.beginInterval("photo_capture")
            pendingPhotoContinuation = continuation
        }
        let currentOrientation = currentVideoOrientation
        stateLock.unlock()

        guard canCapture else {
            continuation.resume(throwing: CameraSessionError.captureInProgress)
            return
        }

        DispatchQueue.main.async {
            self.isCapturingPhoto = true
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else {
                self.completeCapture(result: .failure(CameraSessionError.previewNotRunning))
                return
            }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off

            if self.photoOutput.isHighResolutionCaptureEnabled,
               self.photoOutput.availablePhotoCodecTypes.contains(.jpeg)
            {
                settings.isHighResolutionPhotoEnabled = true
            }

            if
                let connection = self.photoOutput.connection(with: .video),
                connection.isVideoOrientationSupported
            {
                connection.videoOrientation = currentOrientation
            }

            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    @objc
    private func handleDeviceOrientationDidChange() {
        apply(deviceOrientation: UIDevice.current.orientation)
    }

    private func apply(deviceOrientation: UIDeviceOrientation) {
        orientationLabel = CameraOrientationMapper.label(for: deviceOrientation)

        guard let nextOrientation = CameraOrientationMapper.videoOrientation(for: deviceOrientation) else {
            return
        }

        stateLock.lock()
        currentVideoOrientation = nextOrientation
        stateLock.unlock()

        previewOrientation = nextOrientation

        sessionQueue.async { [weak self] in
            guard let self else { return }
            if
                let photoConnection = self.photoOutput.connection(with: .video),
                photoConnection.isVideoOrientationSupported
            {
                photoConnection.videoOrientation = nextOrientation
            }

            if
                let videoConnection = self.videoDataOutput.connection(with: .video),
                videoConnection.isVideoOrientationSupported
            {
                videoConnection.videoOrientation = nextOrientation
            }
        }
    }

    private func configureSessionIfNeeded() throws {
        if hasConfiguredSession {
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high
        defer { session.commitConfiguration() }

        guard session.canAddOutput(photoOutput) else {
            throw CameraSessionError.cannotAddPhotoOutput
        }

        try configurePrimaryInput(for: requestedZoomPreset)
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .balanced
        photoOutput.isHighResolutionCaptureEnabled = true

        if liveAnalysisEnabled {
            guard session.canAddOutput(videoDataOutput) else {
                throw CameraSessionError.cannotAddVideoDataOutput
            }

            session.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            ]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

            if
                let connection = videoDataOutput.connection(with: .video),
                connection.isVideoOrientationSupported
            {
                connection.videoOrientation = previewOrientation
            }
        }

        hasConfiguredSession = true
        print("[CameraSession] configuration completed")
        Self.logger.notice("Camera session configured")
    }

    private func configurePrimaryInput(for preset: CameraZoomPreset) throws {
        let camera = try resolvedCamera(for: preset)
        let input = try AVCaptureDeviceInput(device: camera)

        guard session.canAddInput(input) else {
            throw CameraSessionError.cannotAddInput
        }

        session.addInput(input)
        currentVideoInput = input
        try applyZoomFactor(for: preset, using: camera)
        applySubjectFocusIfNeeded(point: requestedSubjectFocusPoint, force: true)

        let cameraLabel = preset == .zoom05 && camera.deviceType == .builtInUltraWideCamera
            ? "back ultra-wide camera"
            : "back wide camera"
        print("[CameraSession] configuring session with \(cameraLabel)")
    }

    private func applyZoomPreset(_ preset: CameraZoomPreset) throws {
        if !hasConfiguredSession {
            return
        }

        let desiredCamera = try resolvedCamera(for: preset)
        let currentDevice = currentVideoInput?.device

        if currentDevice?.uniqueID != desiredCamera.uniqueID {
            session.beginConfiguration()

            if let currentVideoInput {
                session.removeInput(currentVideoInput)
            }

            do {
                try configurePrimaryInput(for: preset)
            } catch {
                if let previousDevice = currentDevice {
                    let previousInput = try AVCaptureDeviceInput(device: previousDevice)
                    if session.canAddInput(previousInput) {
                        session.addInput(previousInput)
                        currentVideoInput = previousInput
                    }
                }
                session.commitConfiguration()
                throw error
            }

            if
                let photoConnection = photoOutput.connection(with: .video),
                photoConnection.isVideoOrientationSupported
            {
                photoConnection.videoOrientation = previewOrientation
            }

            if
                let videoConnection = videoDataOutput.connection(with: .video),
                videoConnection.isVideoOrientationSupported
            {
                videoConnection.videoOrientation = previewOrientation
            }

            session.commitConfiguration()
            return
        }

        try applyZoomFactor(for: preset, using: desiredCamera)
        applySubjectFocusIfNeeded(point: requestedSubjectFocusPoint, force: true)
    }

    private func resolvedCamera(for preset: CameraZoomPreset) throws -> AVCaptureDevice {
        if preset == .zoom05,
           let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return ultraWideCamera
        }

        if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return wideCamera
        }

        throw CameraSessionError.noCameraDevice
    }

    private func applyZoomFactor(
        for preset: CameraZoomPreset,
        using device: AVCaptureDevice
    ) throws {
        let resolvedZoomFactor: CGFloat

        if preset == .zoom05 && device.deviceType == .builtInUltraWideCamera {
            resolvedZoomFactor = max(device.minAvailableVideoZoomFactor, 1)
        } else {
            resolvedZoomFactor = min(
                max(preset.requestedFactor, device.minAvailableVideoZoomFactor),
                device.maxAvailableVideoZoomFactor
            )
        }

        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.videoZoomFactor = resolvedZoomFactor
        } catch {
            throw CameraSessionError.zoomConfigurationFailed
        }
    }

    private func savePhotoData(_ photoData: Data) throws -> URL {
        let captureDirectory = SessionStore.capturesDirectoryURL()

        try FileManager.default.createDirectory(
            at: captureDirectory,
            withIntermediateDirectories: true
        )

        let filename = "capture-\(UUID().uuidString).jpg"
        let fileURL = captureDirectory.appendingPathComponent(filename)
        try photoData.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func applySubjectFocusIfNeeded(point: CGPoint?, force: Bool) {
        guard let point, let device = currentVideoInput?.device else {
            return
        }

        let resolvedPoint = CGPoint(
            x: min(max(point.x, 0.08), 0.92),
            y: min(max(point.y, 0.08), 0.92)
        )
        let now = Date()
        let hasMovedEnough = lastAppliedSubjectFocusPoint.map { lastPoint in
            hypot(resolvedPoint.x - lastPoint.x, resolvedPoint.y - lastPoint.y) >= 0.075
        } ?? true
        let hasWaitedLongEnough = now.timeIntervalSince(lastAppliedSubjectFocusAt) >= 1.15

        guard force || hasMovedEnough || hasWaitedLongEnough else {
            return
        }

        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            device.isSubjectAreaChangeMonitoringEnabled = true

            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = resolvedPoint
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                } else if device.isFocusModeSupported(.autoFocus) {
                    device.focusMode = .autoFocus
                }
            }

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = resolvedPoint
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                } else if device.isExposureModeSupported(.autoExpose) {
                    device.exposureMode = .autoExpose
                }
            }
        } catch {
            Self.logger.error("Subject focus update failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        lastAppliedSubjectFocusPoint = resolvedPoint
        lastAppliedSubjectFocusAt = now
    }

    private func publish(errorMessage: String) {
        DispatchQueue.main.async {
            self.lastErrorMessage = errorMessage
            self.isSessionRunning = false
            self.latestPoseFrame = nil
            self.latestLightingSummary = nil
        }
    }

    private func completeCapture(result: Result<CapturedPhoto, Error>) {
        stateLock.lock()
        let continuation = pendingPhotoContinuation
        pendingPhotoContinuation = nil
        if let signpostState = photoCaptureSignpostState {
            PerformanceSignposts.endInterval("photo_capture", signpostState)
        }
        photoCaptureSignpostState = nil
        isPhotoCaptureInFlight = false
        stateLock.unlock()

        DispatchQueue.main.async {
            self.isCapturingPhoto = false
            switch result {
            case let .success(capture):
                self.lastErrorMessage = nil
                self.latestCapture = capture
            case let .failure(error):
                self.lastErrorMessage = error.localizedDescription
            }
        }

        if let continuation {
            continuation.resume(with: result)
        }
    }
}

extension CameraSessionController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil else {
            completeCapture(result: .failure(error ?? CameraSessionError.photoProcessingFailed))
            return
        }

        guard let photoData = photo.fileDataRepresentation() else {
            completeCapture(result: .failure(CameraSessionError.photoDataUnavailable))
            return
        }

        do {
            let fileURL = try savePhotoData(photoData)
            completeCapture(result: .success(CapturedPhoto(fileURL: fileURL)))
            PerformanceSignposts.emitEvent("photo_capture_saved")
        } catch {
            completeCapture(result: .failure(error))
        }
    }
}

extension CameraSessionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard output === videoDataOutput else {
            return
        }

        guard isAnalysisActive else {
            return
        }

        stateLock.lock()
        let orientation = currentVideoOrientation
        stateLock.unlock()

        let frameAnalysisSignpost = PerformanceSignposts.beginInterval("frame_analysis")
        let poseFrame = poseDetectionService.process(
            sampleBuffer: sampleBuffer,
            orientation: orientation
        )
        let lightingSummary = lightingAnalysisService.process(sampleBuffer: sampleBuffer)
        PerformanceSignposts.endInterval("frame_analysis", frameAnalysisSignpost)

        guard poseFrame != nil || lightingSummary != nil else {
            return
        }

        DispatchQueue.main.async {
            if let poseFrame {
                self.latestPoseFrame = poseFrame
            }

            if let lightingSummary {
                if self.latestLightingSummary != lightingSummary {
                    self.latestLightingSummary = lightingSummary
                }
            }
        }
    }
}

private enum CameraSessionError: LocalizedError {
    case cannotAddInput
    case cannotAddPhotoOutput
    case cannotAddVideoDataOutput
    case captureInProgress
    case noCameraDevice
    case photoDataUnavailable
    case photoProcessingFailed
    case previewNotRunning
    case sessionDeallocated
    case zoomConfigurationFailed

    var errorDescription: String? {
        switch self {
        case .cannotAddInput:
            return "The camera input could not be attached."
        case .cannotAddPhotoOutput:
            return "The photo output could not be attached."
        case .cannotAddVideoDataOutput:
            return "The live analysis output could not be attached."
        case .captureInProgress:
            return "A capture is already in progress."
        case .noCameraDevice:
            return "No back camera is available on this device."
        case .photoDataUnavailable:
            return "Photo data could not be created."
        case .photoProcessingFailed:
            return "Photo capture failed."
        case .previewNotRunning:
            return "Camera preview is not running."
        case .sessionDeallocated:
            return "Camera session was released before capture completed."
        case .zoomConfigurationFailed:
            return "The camera zoom could not be updated."
        }
    }
}
