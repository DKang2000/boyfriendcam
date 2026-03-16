import SwiftUI

struct LevelGuideView: View {
    let offsetRatio: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let centerX = width / 2
            let bubbleX = centerX + (CGFloat(offsetRatio) * (width * 0.38))
            let isLevel = abs(offsetRatio) < 0.05

            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.26))
                    .frame(height: 24)

                Capsule()
                    .fill(Color.white.opacity(0.20))
                    .frame(height: 1.25)
                    .padding(.horizontal, 18)

                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 2.5, height: 11)
                    .position(x: centerX, y: 12)

                Circle()
                    .fill(isLevel ? Color(red: 0.20, green: 0.77, blue: 0.45) : Color(red: 0.94, green: 0.82, blue: 0.18))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
                    .position(x: bubbleX, y: 12)
            }
        }
        .frame(height: 24)
    }
}
