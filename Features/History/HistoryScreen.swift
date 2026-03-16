import SwiftUI
import UIKit

struct HistoryScreen: View {
    let sessions: [CaptureSessionRecord]
    let onDismiss: () -> Void
    let onSelectSession: (CaptureSessionRecord) -> Void
    let onDeleteSession: (UUID) -> Void

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

                if sessions.isEmpty {
                    VStack(spacing: 10) {
                        Text("No sessions yet")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("Captured sessions will stay here for simple local review.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.68))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                } else {
                    List {
                        ForEach(sessions) { session in
                            Button {
                                onSelectSession(session)
                            } label: {
                                HStack(spacing: 12) {
                                    HistoryThumbnail(session: session)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ShotTemplateRegistry.template(for: session.templateID).label)
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.white)

                                        Text(session.frameCountSummary)
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.68))

                                        if let lighting = session.lighting, lighting.state != .balanced {
                                            Text(lighting.state.label)
                                                .font(.caption)
                                                .foregroundStyle(.yellow)
                                        }
                                    }

                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button(role: .destructive) {
                                    onDeleteSession(session.id)
                                } label: {
                                    Text("Delete")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    .background(Color.clear)
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
}

private struct HistoryThumbnail: View {
    let session: CaptureSessionRecord

    var body: some View {
        Group {
            if let fileURL = session.selectedFrame?.fileURL,
               let image = UIImage(contentsOfFile: fileURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            }
        }
        .frame(width: 62, height: 86)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
    }
}
