import SwiftUI

struct CropPreviewMaskView: View {
    let cropPreviewID: CropPreviewID

    var body: some View {
        GeometryReader { geometry in
            let rect = CropPreviewRegistry.configuration(for: cropPreviewID).maskRect(in: geometry.size)
            let roundedRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y,
                width: max(rect.size.width, 0),
                height: max(rect.size.height, 0)
            )

            Canvas { context, size in
                guard cropPreviewID != .none else {
                    return
                }

                var path = Path(CGRect(origin: .zero, size: size))
                path.addRoundedRect(in: roundedRect, cornerSize: CGSize(width: 18, height: 18))

                context.fill(path, with: .color(Color.black.opacity(0.46)), style: FillStyle(eoFill: true))
                context.stroke(
                    Path(roundedRect: roundedRect, cornerRadius: 18),
                    with: .color(.white.opacity(0.72)),
                    lineWidth: 1
                )
            }
        }
        .allowsHitTesting(false)
    }
}
