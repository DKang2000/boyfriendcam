import SwiftUI

struct CoachPersonaPicker: View {
    let selectedPersona: CoachPersona
    let onSelect: (CoachPersona) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Tone")

            HStack(spacing: 8) {
                ForEach(CoachPersona.allCases) { persona in
                    let selected = persona == selectedPersona

                    Button {
                        onSelect(persona)
                    } label: {
                        Text(persona.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selected ? Color.black : .white.opacity(0.82))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(selected ? Color.white.opacity(0.94) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(selected ? 0 : 0.08), lineWidth: 1)
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

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.52))
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
