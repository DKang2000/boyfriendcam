import SwiftUI

struct CaptureModePicker: View {
    let selectedMode: CaptureMode
    let onSelect: (CaptureMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Burst")

            HStack(spacing: 8) {
                ForEach(CaptureMode.allCases) { mode in
                    BurstModeChip(
                        label: mode.label,
                        isSelected: mode == selectedMode
                    ) {
                        onSelect(mode)
                    }
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

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.52))
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

private struct BurstModeChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black : .white.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? Color(red: 0.93, green: 0.81, blue: 0.18)
                                : Color.white.opacity(0.08)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
