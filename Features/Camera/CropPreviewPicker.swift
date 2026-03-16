import SwiftUI

struct CropPreviewPicker: View {
    let selectedCropPreviewID: CropPreviewID
    let onSelect: (CropPreviewID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Crop Preview")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CropPreviewID.allCases) { cropPreviewID in
                        let isSelected = cropPreviewID == selectedCropPreviewID

                        Button {
                            onSelect(cropPreviewID)
                        } label: {
                            Text(cropPreviewID.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(isSelected ? Color.black : .white.opacity(0.82))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
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

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.52))
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
