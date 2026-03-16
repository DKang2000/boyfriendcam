import SwiftUI

struct PoseDebugOverlayView: View {
    let poseFrame: PoseFrame

    var body: some View {
        Canvas { context, size in
            let strokeColor = Color(red: 0.33, green: 0.96, blue: 0.82)
            let pointColor = Color(red: 0.96, green: 1.0, blue: 0.38)

            for (start, end) in PoseLandmarkName.debugConnections {
                guard
                    let startPoint = poseFrame.landmarks[start],
                    let endPoint = poseFrame.landmarks[end]
                else {
                    continue
                }

                var path = Path()
                path.move(to: CGPoint(x: startPoint.x * size.width, y: startPoint.y * size.height))
                path.addLine(to: CGPoint(x: endPoint.x * size.width, y: endPoint.y * size.height))
                context.stroke(
                    path,
                    with: .color(strokeColor.opacity(0.88)),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
            }

            for landmark in poseFrame.landmarks.values {
                let rect = CGRect(
                    x: landmark.x * size.width - 4,
                    y: landmark.y * size.height - 4,
                    width: 8,
                    height: 8
                )
                context.fill(Path(ellipseIn: rect), with: .color(pointColor.opacity(max(landmark.confidence, 0.55))))
            }
        }
        .allowsHitTesting(false)
    }
}
