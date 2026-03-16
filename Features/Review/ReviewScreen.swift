import SwiftUI
import UIKit

struct ReviewScreen: View {
    let session: CaptureSessionRecord
    let exportStatusMessage: String?
    let isExporting: Bool
    let onDismiss: () -> Void
    let onSelectFrame: (UUID) -> Void
    let onSelectCropPreview: (CropPreviewID) -> Void
    let onExport: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.04, blue: 0.06),
                        Color.black,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        previewCard

                        CropPreviewPicker(
                            selectedCropPreviewID: session.cropPreviewID,
                            onSelect: onSelectCropPreview
                        )

                        if session.frames.count > 1 {
                            frameStrip
                        }

                        metadataBlock

                        if let exportStatusMessage {
                            Text(exportStatusMessage)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.white.opacity(0.74))
                        }

                        Button(action: onExport) {
                            HStack {
                                if isExporting {
                                    ProgressView()
                                        .tint(.black)
                                }

                                Text(isExporting ? "Saving..." : "Save to Photos")
                                    .font(.headline.weight(.semibold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Color(red: 0.93, green: 0.81, blue: 0.18),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done", action: onDismiss)
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var previewCard: some View {
        ZStack {
            if let selectedFrame = session.selectedFrame,
               let image = UIImage(contentsOfFile: selectedFrame.fileURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay {
                        Text("Preview unavailable")
                            .foregroundStyle(.white.opacity(0.72))
                    }
            }

            CropPreviewMaskView(cropPreviewID: session.cropPreviewID)
        }
        .aspectRatio(9 / 16, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.32), radius: 20, x: 0, y: 12)
    }

    private var frameStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(session.frames) { frame in
                    Button {
                        onSelectFrame(frame.id)
                    } label: {
                        Group {
                            if let image = UIImage(contentsOfFile: frame.fileURL.path) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            }
                        }
                        .frame(width: 80, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    session.selectedFrameID == frame.id ? Color.yellow : Color.white.opacity(0.10),
                                    lineWidth: session.selectedFrameID == frame.id ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var metadataBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(ShotTemplateRegistry.template(for: session.templateID).label)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Text(session.frameCountSummary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))

            if let lighting = session.lighting {
                metadataPill(text: lighting.state.label)
            }

            if let motion = session.motion, motion.phoneTiltSignal != nil || motion.levelState != .level {
                metadataPill(text: "Phone alignment captured")
            }

            if let primaryPromptText = session.primaryPromptText {
                Text(primaryPromptText)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.64))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func metadataPill(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08), in: Capsule())
    }
}
