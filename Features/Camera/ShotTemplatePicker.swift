import SwiftUI

struct ShotTemplatePicker: View {
    let selectedTemplateID: ShotTemplateID
    let onSelect: (ShotTemplateID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Shot Type")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ShotTemplateRegistry.templates) { template in
                        let selected = template.id == selectedTemplateID

                        Button {
                            onSelect(template.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(selected ? Color.black : .white)

                                Text(template.summary)
                                    .font(.caption)
                                    .foregroundStyle(selected ? Color.black.opacity(0.62) : .white.opacity(0.50))
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(width: 156, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(selected ? Color(red: 0.93, green: 0.81, blue: 0.18) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(selected ? 0 : 0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 12)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
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
