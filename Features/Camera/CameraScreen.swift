import SwiftUI
import UIKit

struct CameraScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: CameraShellViewModel
    @State private var isControlsPresented = false

    var body: some View {
        Group {
            switch viewModel.authorizationState {
            case .checking:
                ProgressView("Checking camera access...")
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            case .needsPermission:
                permissionGate(
                    title: "Camera access is required",
                    body: "Enable the camera to validate the live preview, guidance, burst flow, and polished native controls."
                ) {
                    Task {
                        await viewModel.requestCameraAccess()
                    }
                }
            case .denied:
                permissionGate(
                    title: "Camera access is denied",
                    body: "Enable camera access in Settings to validate the native preview, guidance, and capture flow."
                ) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            case .restricted:
                permissionGate(
                    title: "Camera access is restricted",
                    body: "This device currently cannot grant camera access."
                ) {}
            case .ready:
                liveCameraScreen
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.prepareIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.handleScenePhase(newPhase)
        }
        .sheet(isPresented: $viewModel.isHistoryPresented) {
            HistoryScreen(
                sessions: viewModel.historySessions,
                onDismiss: viewModel.dismissHistory,
                onSelectSession: viewModel.openHistorySession,
                onDeleteSession: viewModel.deleteSession
            )
        }
        .fullScreenCover(item: $viewModel.activeReviewSession) { session in
            ReviewScreen(
                session: session,
                exportStatusMessage: viewModel.exportStatusMessage,
                isExporting: viewModel.isExportingSelection,
                onDismiss: viewModel.dismissReview,
                onSelectFrame: viewModel.selectReviewFrame,
                onSelectCropPreview: viewModel.selectReviewCropPreview,
                onExport: viewModel.exportSelectedFrame
            )
        }
        .sheet(isPresented: $isControlsPresented) {
            controlsSheet
        }
    }

    private var liveCameraScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                let stageWidth = geometry.size.width
                let preferredStageHeight = stageWidth * (4.0 / 3.0)
                let minimumTopBand = geometry.safeAreaInsets.top + 82
                let minimumBottomBand = geometry.safeAreaInsets.bottom + 146
                let maximumStageHeight = max(
                    geometry.size.height - minimumTopBand - minimumBottomBand,
                    0
                )
                let stageHeight = min(preferredStageHeight, maximumStageHeight)
                let remainingHeight = max(geometry.size.height - stageHeight, 0)
                let topBandHeight = max(minimumTopBand, remainingHeight * 0.39)
                let bottomBandHeight = max(remainingHeight - topBandHeight, 0)

                VStack(spacing: 0) {
                    topLetterboxChrome
                        .frame(height: topBandHeight)

                    previewStage
                        .frame(width: stageWidth, height: stageHeight)

                    bottomLetterboxChrome
                        .frame(height: bottomBandHeight)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
            .ignoresSafeArea()
        }
        .background(Color.black.ignoresSafeArea())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var previewStage: some View {
        ZStack {
            CameraPreviewContainer(
                session: viewModel.previewSession,
                orientation: viewModel.previewOrientation,
                subjectFocusPreviewPoint: viewModel.subjectFocusPreviewPoint,
                onResolvedSubjectFocusPoint: viewModel.updateSubjectFocusDevicePoint
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if viewModel.isTemplateMode {
                    CropPreviewMaskView(cropPreviewID: viewModel.selectedCropPreviewID)
                }
            }
            .overlay {
                if viewModel.selectedExperienceMode == .coach {
                    CoachGuidanceOverlayView(
                        poseFrame: viewModel.latestPoseFrame,
                        isGuidanceActive: viewModel.coachingSnapshot?.isGuidanceActive ?? false,
                        isUpsideDown: viewModel.isUpsideDownLayout
                    )
                } else {
                    ShotTemplateOverlayView(
                        template: viewModel.liveCoachingTemplate,
                        poseFrame: viewModel.latestPoseFrame,
                        isUpsideDown: viewModel.isUpsideDownLayout
                    )
                }
            }
            .overlay {
                if viewModel.isDebugOverlayEnabled, let latestPoseFrame = viewModel.latestPoseFrame {
                    PoseDebugOverlayView(poseFrame: latestPoseFrame)
                }
            }

            if viewModel.isDebugOverlayEnabled {
                debugCluster
            }
        }
        .background(Color.black)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: viewModel.primaryPromptText)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: viewModel.secondaryPromptText)
        .animation(.spring(response: 0.30, dampingFraction: 0.90), value: viewModel.isUpsideDownLayout)
    }

    private var topLetterboxChrome: some View {
        VStack(spacing: 8) {
            primaryPromptPill
                .frame(maxWidth: 292)

            if let secondaryPromptText = viewModel.secondaryPromptText {
                secondaryPromptPill(text: secondaryPromptText)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var bottomLetterboxChrome: some View {
        VStack(spacing: 14) {
            if let message = viewModel.lastErrorMessage {
                liveErrorPill(message: message)
            }

            if abs(viewModel.levelGuideOffsetRatio) >= 0.08 {
                LevelGuideView(offsetRatio: viewModel.levelGuideOffsetRatio)
                    .frame(width: 112)
                    .offset(y: -16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            HStack(alignment: .center, spacing: 14) {
                if viewModel.isUpsideDownLayout {
                    controlsButton
                    Spacer(minLength: 0)
                    captureButton
                    Spacer(minLength: 0)
                    thumbnailButton
                } else {
                    thumbnailButton
                    Spacer(minLength: 0)
                    captureButton
                    Spacer(minLength: 0)
                    controlsButton
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 52)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var debugCluster: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusBadge(text: "Mode: \(viewModel.selectedExperienceMode.label)")
            statusBadge(text: "Orientation: \(viewModel.orientationLabel)")

            if let scoreText = viewModel.smoothedScoreText {
                statusBadge(text: scoreText)
            }

            if let latestLightingSummary = viewModel.latestLightingSummary {
                statusBadge(text: "Light: \(latestLightingSummary.state.rawValue)")
            }

            let count = viewModel.latestPoseFrame?.visibleLandmarkCount ?? 0
            statusBadge(text: "Landmarks: \(count)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(18)
    }

    private var primaryPromptPill: some View {
        Text(viewModel.primaryPromptText)
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .foregroundStyle(primaryPromptForegroundColor)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
        .background(primaryPromptBackgroundColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(primaryPromptBorderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
    }

    private var experienceModePicker: some View {
        HStack(spacing: 8) {
            ForEach(CameraExperienceMode.allCases) { mode in
                let isSelected = viewModel.selectedExperienceMode == mode

                Button {
                    viewModel.selectExperienceMode(mode)
                } label: {
                    Text(mode.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.black : .white.opacity(0.84))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    isSelected
                                        ? Color(red: 0.94, green: 0.82, blue: 0.18)
                                        : Color.white.opacity(0.08)
                                )
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Color.black.opacity(0.34), in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func secondaryPromptPill(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.94))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.20), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
    }

    private var captureButton: some View {
        Button(action: viewModel.capture) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.96), lineWidth: 5)
                    .frame(width: 84, height: 84)

                Circle()
                    .fill(viewModel.isCapturingPhoto ? Color(red: 0.94, green: 0.82, blue: 0.18) : Color.white)
                    .frame(width: 68, height: 68)

                if viewModel.isCapturingPhoto {
                    ProgressView()
                        .tint(.black)
                }
            }
            .shadow(color: Color.black.opacity(0.24), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isCapturingPhoto || !viewModel.isSessionRunning)
        .opacity(viewModel.isSessionRunning ? 1 : 0.56)
        .accessibilityLabel("Take photo")
    }

    private var thumbnailButton: some View {
        Button {
            if let session = viewModel.historySessions.first {
                viewModel.openHistorySession(session)
            }
        } label: {
            Group {
                if let thumbnailURL = viewModel.latestSessionThumbnailURL,
                   let image = UIImage(contentsOfFile: thumbnailURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                }
            }
            .frame(width: 46, height: 46)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.26))
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.historySessions.isEmpty && viewModel.latestSessionThumbnailURL == nil)
        .opacity((viewModel.historySessions.isEmpty && viewModel.latestSessionThumbnailURL == nil) ? 0.58 : 1)
        .accessibilityLabel("Open latest review")
    }

    private var controlsButton: some View {
        Button {
            isControlsPresented = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.black.opacity(0.24), in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open controls")
    }

    private var primaryPromptBackgroundColor: Color {
        viewModel.isReadyForCapture
            ? Color(red: 0.87, green: 0.95, blue: 0.88)
            : Color(red: 0.94, green: 0.88, blue: 0.16)
    }

    private var primaryPromptForegroundColor: Color {
        Color.black.opacity(viewModel.isReadyForCapture ? 0.78 : 0.84)
    }

    private var primaryPromptBorderColor: Color {
        Color.white.opacity(viewModel.isReadyForCapture ? 0.22 : 0.12)
    }

    private func liveErrorPill(message: String) -> some View {
        Text(message)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.orange.opacity(0.26), in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.orange.opacity(0.60), lineWidth: 1)
            )
    }

    private func permissionGate(
        title: String,
        body: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("BoyfriendCam Native")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.94, green: 0.82, blue: 0.18))
                .textCase(.uppercase)
                .tracking(1.1)

            Text(title)
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            Text(body)
                .font(.body)
                .foregroundStyle(.white.opacity(0.74))

            Button(action: action) {
                Text("Continue")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Color(red: 0.94, green: 0.82, blue: 0.18),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color.black.ignoresSafeArea())
    }

    private func statusBadge(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.44), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private var controlsSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Camera Setup")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Keep the preview clean. Tune mode, zoom, burst, and template framing here.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.72))

                    experienceModeSection

                    if viewModel.isTemplateMode {
                        ShotTemplatePicker(
                            selectedTemplateID: viewModel.selectedTemplateID,
                            onSelect: viewModel.selectTemplate
                        )
                    } else {
                        coachModeSummaryCard
                    }

                    HStack(alignment: .top, spacing: 10) {
                        zoomPresetPicker(
                            selectedPreset: viewModel.selectedZoomPreset,
                            onSelect: viewModel.selectZoomPreset
                        )

                        CaptureModePicker(
                            selectedMode: viewModel.selectedCaptureMode,
                            onSelect: viewModel.selectCaptureMode
                        )
                    }

                    if viewModel.isTemplateMode {
                        CropPreviewPicker(
                            selectedCropPreviewID: viewModel.selectedCropPreviewID,
                            onSelect: viewModel.selectCropPreview
                        )
                    }

                    Toggle(
                        isOn: Binding(
                            get: { viewModel.isVoiceGuidanceEnabled },
                            set: { isEnabled in
                                guard isEnabled != viewModel.isVoiceGuidanceEnabled else {
                                    return
                                }
                                viewModel.toggleVoiceGuidance()
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Voice Guidance")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            Text("Read framing prompts out loud while keeping the live camera clean.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.64))
                        }
                    }
                    .tint(Color(red: 0.93, green: 0.81, blue: 0.18))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )

                    Button {
                        viewModel.toggleDebugOverlay()
                    } label: {
                        HStack {
                            Image(systemName: viewModel.isDebugOverlayEnabled ? "ladybug.fill" : "ladybug")
                            Text(viewModel.isDebugOverlayEnabled ? "Hide Debug Overlay" : "Show Debug Overlay")
                            Spacer()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.07, blue: 0.10),
                        Color.black,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isControlsPresented = false
                    }
                    .font(.headline.weight(.semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var experienceModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Mode")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.52))
                .textCase(.uppercase)
                .tracking(0.8)

            experienceModePicker
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private var coachModeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coach mode adapts to the scene in front of you.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text("It recommends the strongest next adjustment for the shot while keeping the tone calm and supportive by default.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.70))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private func zoomPresetPicker(
        selectedPreset: CameraZoomPreset,
        onSelect: @escaping (CameraZoomPreset) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zoom")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.52))
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(spacing: 8) {
                ForEach(CameraZoomPreset.allCases) { preset in
                    let isSelected = preset == selectedPreset

                    Button {
                        onSelect(preset)
                    } label: {
                        Text(preset.displayLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSelected ? Color.black : .white.opacity(0.82))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color(red: 0.93, green: 0.81, blue: 0.18) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

private struct CoachGuidanceOverlayView: View {
    let poseFrame: PoseFrame?
    let isGuidanceActive: Bool
    let isUpsideDown: Bool
    @State private var displayedBodyDescriptor: PoseBodyDescriptor?

    var body: some View {
        Canvas { context, size in
            let overlayOpacity = isGuidanceActive ? 0.68 : 0.0
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.52)
            let subjectSilhouette = displayedBodyDescriptor.flatMap {
                resolvedSilhouette(for: $0, in: size)
            }

            if overlayOpacity > 0.001 {
                drawScrim(
                    context: &context,
                    size: size,
                    overlayOpacity: overlayOpacity,
                    silhouette: subjectSilhouette
                )
                drawGuides(context: &context, size: size, center: center, overlayOpacity: overlayOpacity)
                drawHighlight(
                    context: &context,
                    overlayOpacity: overlayOpacity,
                    silhouette: subjectSilhouette
                )
            }
        }
        .allowsHitTesting(false)
        .onAppear(perform: syncDisplayedBodyDescriptor)
        .onChange(of: poseFrame) { _, _ in
            syncDisplayedBodyDescriptor()
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.90), value: displayedBodyDescriptor)
        .animation(.easeInOut(duration: 0.28), value: isGuidanceActive)
        .animation(.spring(response: 0.28, dampingFraction: 0.90), value: isUpsideDown)
    }

    private func drawScrim(
        context: inout GraphicsContext,
        size: CGSize,
        overlayOpacity: Double,
        silhouette: CoachAdaptiveSilhouette?
    ) {
        guard let silhouette else {
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color.black.opacity(0.12 * overlayOpacity))
            )
            return
        }

        var scrimPath = Path(CGRect(origin: .zero, size: size))
        scrimPath.addPath(silhouette.compositePath)
        context.fill(
            scrimPath,
            with: .color(Color.black.opacity(0.24 * overlayOpacity)),
            style: FillStyle(eoFill: true)
        )
    }

    private func drawGuides(
        context: inout GraphicsContext,
        size: CGSize,
        center: CGPoint,
        overlayOpacity: Double
    ) {
        let edgeColor = Color.white.opacity(0.18 * overlayOpacity)

        var verticalPath = Path()
        verticalPath.move(to: CGPoint(x: center.x, y: size.height * 0.10))
        verticalPath.addLine(to: CGPoint(x: center.x, y: size.height * 0.92))
        context.stroke(
            verticalPath,
            with: .color(edgeColor),
            style: StrokeStyle(lineWidth: 1.05, lineCap: .round)
        )

        var horizontalPath = Path()
        horizontalPath.move(to: CGPoint(x: size.width * 0.12, y: center.y))
        horizontalPath.addLine(to: CGPoint(x: size.width * 0.88, y: center.y))
        context.stroke(
            horizontalPath,
            with: .color(edgeColor),
            style: StrokeStyle(lineWidth: 1.05, lineCap: .round)
        )
    }

    private func drawHighlight(
        context: inout GraphicsContext,
        overlayOpacity: Double,
        silhouette: CoachAdaptiveSilhouette?
    ) {
        guard let silhouette else {
            return
        }

        let silhouetteFill = Color.white.opacity(0.72 * overlayOpacity)
        let silhouetteGlow = Color.white.opacity(0.06 * overlayOpacity)
        let edgeColor = Color.white.opacity(0.34 * overlayOpacity)

        context.addFilter(.shadow(color: silhouetteGlow, radius: 12, x: 0, y: 0))
        context.fill(Path(ellipseIn: silhouette.headRect), with: .color(silhouetteFill))
        context.fill(silhouette.torso, with: .color(silhouetteFill))
        context.stroke(
            silhouette.leftArm,
            with: .color(silhouetteFill),
            style: StrokeStyle(lineWidth: silhouette.armWidth, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            silhouette.rightArm,
            with: .color(silhouetteFill),
            style: StrokeStyle(lineWidth: silhouette.armWidth, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            silhouette.leftLeg,
            with: .color(silhouetteFill),
            style: StrokeStyle(lineWidth: silhouette.legWidth, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            silhouette.rightLeg,
            with: .color(silhouetteFill),
            style: StrokeStyle(lineWidth: silhouette.legWidth, lineCap: .round, lineJoin: .round)
        )

        context.stroke(
            silhouette.compositePath,
            with: .color(edgeColor),
            style: StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round)
        )
    }

    private func syncDisplayedBodyDescriptor() {
        guard let nextDescriptor = poseFrame?.coachBodyDescriptor() else {
            displayedBodyDescriptor = nil
            return
        }

        if let currentDescriptor = displayedBodyDescriptor {
            displayedBodyDescriptor = currentDescriptor.blended(toward: nextDescriptor, factor: 0.24)
        } else {
            displayedBodyDescriptor = nextDescriptor
        }
    }

    private func resolvedSilhouette(
        for descriptor: PoseBodyDescriptor,
        in size: CGSize
    ) -> CoachAdaptiveSilhouette? {
        guard let silhouette = makeAdaptiveSilhouette(in: size, bodyDescriptor: descriptor) else {
            return nil
        }

        guard isUpsideDown else {
            return silhouette
        }

        let bounds = silhouette.compositePath.boundingRect
        let transform = CGAffineTransform(translationX: bounds.midX, y: bounds.midY)
            .rotated(by: .pi)
            .translatedBy(x: -bounds.midX, y: -bounds.midY)
        return silhouette.applying(transform)
    }

    private func makeAdaptiveSilhouette(
        in size: CGSize,
        bodyDescriptor: PoseBodyDescriptor
    ) -> CoachAdaptiveSilhouette? {
        let headCenter = point(from: bodyDescriptor.headCenter, in: size)
        let shoulderCenter = point(from: bodyDescriptor.shoulderCenter, in: size)
        let hipCenter = point(from: bodyDescriptor.hipCenter, in: size)
        let shoulderSpan = max(bodyDescriptor.shoulderWidth * size.width, size.width * 0.10)
        let hipSpan = max(bodyDescriptor.hipWidth * size.width, shoulderSpan * 0.72)
        let bodyHeight = max((bodyDescriptor.footY - bodyDescriptor.headCenter.y) * size.height, size.height * 0.22)
        let headWidth = max(bodyDescriptor.headWidth * size.width, shoulderSpan * 0.34, hipSpan * 0.42)
        let headHeight = headWidth * 1.24
        let headRect = CGRect(
            x: headCenter.x - headWidth / 2,
            y: headCenter.y - headHeight * 0.44,
            width: headWidth,
            height: headHeight
        )

        let leftShoulder = CGPoint(x: shoulderCenter.x - shoulderSpan * 0.50, y: shoulderCenter.y + bodyHeight * 0.01)
        let rightShoulder = CGPoint(x: shoulderCenter.x + shoulderSpan * 0.50, y: shoulderCenter.y + bodyHeight * 0.01)
        let leftHip = CGPoint(x: hipCenter.x - hipSpan * 0.44, y: hipCenter.y)
        let rightHip = CGPoint(x: hipCenter.x + hipSpan * 0.44, y: hipCenter.y)
        let armDrop = bodyHeight * 0.36
        let handDrop = bodyHeight * 0.62
        let leftElbow = CGPoint(x: leftShoulder.x - shoulderSpan * 0.26, y: shoulderCenter.y + armDrop)
        let rightElbow = CGPoint(x: rightShoulder.x + shoulderSpan * 0.26, y: shoulderCenter.y + armDrop)
        let leftWrist = CGPoint(x: leftShoulder.x - shoulderSpan * 0.30, y: shoulderCenter.y + handDrop)
        let rightWrist = CGPoint(x: rightShoulder.x + shoulderSpan * 0.30, y: shoulderCenter.y + handDrop)
        let footY = bodyDescriptor.footY * size.height
        let kneeY = hipCenter.y + (footY - hipCenter.y) * 0.48
        let leftKnee = CGPoint(x: leftHip.x - hipSpan * 0.08, y: kneeY)
        let rightKnee = CGPoint(x: rightHip.x + hipSpan * 0.08, y: kneeY)
        let leftAnkle = CGPoint(x: shoulderCenter.x - hipSpan * 0.18, y: footY)
        let rightAnkle = CGPoint(x: shoulderCenter.x + hipSpan * 0.18, y: footY)

        let waistLeft = CGPoint(
            x: lerp(leftShoulder.x, leftHip.x, t: 0.66) + shoulderSpan * 0.02,
            y: lerp(leftShoulder.y, leftHip.y, t: 0.62)
        )
        let waistRight = CGPoint(
            x: lerp(rightShoulder.x, rightHip.x, t: 0.66) - shoulderSpan * 0.02,
            y: lerp(rightShoulder.y, rightHip.y, t: 0.62)
        )
        let leftShoulderOuter = CGPoint(x: leftShoulder.x - shoulderSpan * 0.12, y: leftShoulder.y + bodyHeight * 0.02)
        let rightShoulderOuter = CGPoint(x: rightShoulder.x + shoulderSpan * 0.12, y: rightShoulder.y + bodyHeight * 0.02)
        let leftHipOuter = CGPoint(x: leftHip.x - hipSpan * 0.08, y: leftHip.y)
        let rightHipOuter = CGPoint(x: rightHip.x + hipSpan * 0.08, y: rightHip.y)

        var torso = Path()
        torso.move(to: leftShoulderOuter)
        torso.addQuadCurve(
            to: rightShoulderOuter,
            control: CGPoint(x: shoulderCenter.x, y: min(leftShoulderOuter.y, rightShoulderOuter.y) - bodyHeight * 0.10)
        )
        torso.addCurve(
            to: waistRight,
            control1: CGPoint(x: rightShoulderOuter.x + shoulderSpan * 0.06, y: rightShoulderOuter.y + bodyHeight * 0.12),
            control2: CGPoint(x: waistRight.x + shoulderSpan * 0.05, y: waistRight.y - bodyHeight * 0.10)
        )
        torso.addCurve(
            to: rightHipOuter,
            control1: CGPoint(x: waistRight.x + shoulderSpan * 0.02, y: waistRight.y + bodyHeight * 0.05),
            control2: CGPoint(x: rightHipOuter.x + hipSpan * 0.03, y: rightHipOuter.y - bodyHeight * 0.05)
        )
        torso.addQuadCurve(
            to: leftHipOuter,
            control: CGPoint(x: hipCenter.x, y: max(leftHipOuter.y, rightHipOuter.y) + bodyHeight * 0.04)
        )
        torso.addCurve(
            to: waistLeft,
            control1: CGPoint(x: leftHipOuter.x - hipSpan * 0.03, y: leftHipOuter.y - bodyHeight * 0.05),
            control2: CGPoint(x: waistLeft.x - shoulderSpan * 0.05, y: waistLeft.y + bodyHeight * 0.05)
        )
        torso.addCurve(
            to: leftShoulderOuter,
            control1: CGPoint(x: waistLeft.x - shoulderSpan * 0.05, y: waistLeft.y - bodyHeight * 0.10),
            control2: CGPoint(x: leftShoulderOuter.x - shoulderSpan * 0.06, y: leftShoulderOuter.y + bodyHeight * 0.12)
        )
        torso.closeSubpath()

        var leftArm = Path()
        leftArm.move(to: leftShoulder)
        leftArm.addQuadCurve(to: leftWrist, control: leftElbow)

        var rightArm = Path()
        rightArm.move(to: rightShoulder)
        rightArm.addQuadCurve(to: rightWrist, control: rightElbow)

        var leftLeg = Path()
        leftLeg.move(to: leftHip)
        leftLeg.addQuadCurve(to: leftAnkle, control: leftKnee)

        var rightLeg = Path()
        rightLeg.move(to: rightHip)
        rightLeg.addQuadCurve(to: rightAnkle, control: rightKnee)

        let armWidth = max(shoulderSpan * 0.17, size.width * 0.022)
        let legWidth = max(hipSpan * 0.22, size.width * 0.024)

        return CoachAdaptiveSilhouette(
            headRect: headRect,
            torso: torso,
            leftArm: leftArm,
            rightArm: rightArm,
            leftLeg: leftLeg,
            rightLeg: rightLeg,
            armWidth: armWidth,
            legWidth: legWidth
        )
    }

    private func point(from normalizedPoint: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: normalizedPoint.x * size.width, y: normalizedPoint.y * size.height)
    }

    private func lerp(_ start: CGFloat, _ end: CGFloat, t: CGFloat) -> CGFloat {
        start + (end - start) * t
    }
}

private struct CoachAdaptiveSilhouette {
    let headRect: CGRect
    let torso: Path
    let leftArm: Path
    let rightArm: Path
    let leftLeg: Path
    let rightLeg: Path
    let armWidth: CGFloat
    let legWidth: CGFloat

    var compositePath: Path {
        var path = Path()
        path.addEllipse(in: headRect)
        path.addPath(torso)
        path.addPath(leftArm.strokedPath(.init(lineWidth: armWidth, lineCap: .round, lineJoin: .round)))
        path.addPath(rightArm.strokedPath(.init(lineWidth: armWidth, lineCap: .round, lineJoin: .round)))
        path.addPath(leftLeg.strokedPath(.init(lineWidth: legWidth, lineCap: .round, lineJoin: .round)))
        path.addPath(rightLeg.strokedPath(.init(lineWidth: legWidth, lineCap: .round, lineJoin: .round)))
        return path
    }

    func applying(_ transform: CGAffineTransform) -> CoachAdaptiveSilhouette {
        CoachAdaptiveSilhouette(
            headRect: headRect.applying(transform),
            torso: torso.applying(transform),
            leftArm: leftArm.applying(transform),
            rightArm: rightArm.applying(transform),
            leftLeg: leftLeg.applying(transform),
            rightLeg: rightLeg.applying(transform),
            armWidth: armWidth,
            legWidth: legWidth
        )
    }
}
