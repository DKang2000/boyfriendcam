import SwiftUI

struct ShotTemplateOverlayView: View {
    let template: ShotTemplate
    let poseFrame: PoseFrame?
    let isUpsideDown: Bool
    @State private var displayedRenderDescriptor: PoseRenderDescriptor?

    var body: some View {
        Canvas { context, size in
            let box = resolvedTargetBox(in: size)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let adaptiveSilhouette = displayedRenderDescriptor.map {
                LivePoseOverlayRenderer.resolvedSilhouette(
                    for: $0,
                    in: size,
                    isUpsideDown: isUpsideDown
                )
            }

            drawCrosshair(context: &context, size: size, center: center)

            if template.guideMode == .ruleOfThirds {
                drawThirds(context: &context, size: size)
            }

            drawSilhouette(
                context: &context,
                box: box,
                silhouette: adaptiveSilhouette
            )
        }
        .opacity(0.72)
        .allowsHitTesting(false)
        .onAppear(perform: syncDisplayedBodyDescriptor)
        .onChange(of: poseFrame) { _, _ in
            syncDisplayedBodyDescriptor()
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.90), value: isUpsideDown)
        .animation(.easeOut(duration: 0.14), value: displayedRenderDescriptor)
    }

    private func resolvedTargetBox(in size: CGSize) -> CGRect {
        let baseBox = template.overlay.targetBox.rect(in: size)

        guard isUpsideDown else {
            return baseBox
        }

        let mirroredBox = CGRect(
            x: baseBox.minX,
            y: size.height - baseBox.maxY,
            width: baseBox.width,
            height: baseBox.height
        )
        let upwardNudge = min(size.height * 0.02, mirroredBox.minY)
        return mirroredBox.offsetBy(dx: 0, dy: -upwardNudge)
    }

    private func drawCrosshair(
        context: inout GraphicsContext,
        size: CGSize,
        center: CGPoint
    ) {
        let crosshairColor = Color.white.opacity(0.44)
        let edgeColor = Color.white.opacity(0.16)

        var verticalPath = Path()
        verticalPath.move(to: CGPoint(x: center.x, y: size.height * 0.08))
        verticalPath.addLine(to: CGPoint(x: center.x, y: size.height * 0.92))
        context.stroke(
            verticalPath,
            with: .color(edgeColor),
            style: StrokeStyle(lineWidth: 0.9, lineCap: .round)
        )

        var horizontalPath = Path()
        horizontalPath.move(to: CGPoint(x: size.width * 0.12, y: center.y))
        horizontalPath.addLine(to: CGPoint(x: size.width * 0.88, y: center.y))
        context.stroke(
            horizontalPath,
            with: .color(edgeColor),
            style: StrokeStyle(lineWidth: 0.9, lineCap: .round)
        )

        context.fill(
            Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)),
            with: .color(Color(red: 0.16, green: 0.82, blue: 0.48))
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)),
            with: .color(crosshairColor),
            style: StrokeStyle(lineWidth: 1)
        )
    }

    private func drawThirds(
        context: inout GraphicsContext,
        size: CGSize
    ) {
        let lineColor = Color.white.opacity(0.08)

        for fraction in [CGFloat(1.0 / 3.0), CGFloat(2.0 / 3.0)] {
            var verticalPath = Path()
            verticalPath.move(to: CGPoint(x: size.width * fraction, y: 0))
            verticalPath.addLine(to: CGPoint(x: size.width * fraction, y: size.height))
            context.stroke(
                verticalPath,
                with: .color(lineColor),
                style: StrokeStyle(lineWidth: 0.9, lineCap: .round)
            )

            var horizontalPath = Path()
            horizontalPath.move(to: CGPoint(x: 0, y: size.height * fraction))
            horizontalPath.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
            context.stroke(
                horizontalPath,
                with: .color(lineColor),
                style: StrokeStyle(lineWidth: 0.9, lineCap: .round)
            )
        }
    }

    private func drawSilhouette(
        context: inout GraphicsContext,
        box: CGRect,
        silhouette: PoseAdaptiveSilhouette?
    ) {
        if let silhouette {
            drawAdaptiveSilhouette(
                context: &context,
                silhouette: silhouette
            )
            return
        }

        drawFallbackSilhouette(context: &context, box: box, isUpsideDown: isUpsideDown)
    }

    private func drawFallbackSilhouette(
        context: inout GraphicsContext,
        box: CGRect,
        isUpsideDown: Bool
    ) {
        let silhouetteFill = Color.white.opacity(0.68)
        let silhouetteGlow = Color.white.opacity(0.05)
        let metrics = fallbackSilhouetteMetrics(for: template)
        let silhouetteBox = CGRect(
            x: box.minX + box.width * 0.25,
            y: box.minY + box.height * metrics.topInset,
            width: box.width * 0.50,
            height: box.height * metrics.heightFactor
        )
        let centerX = silhouetteBox.midX
        let width = silhouetteBox.width
        let height = silhouetteBox.height

        let headWidth = width * 0.26
        let headHeight = headWidth * 1.24
        let headRect = CGRect(
            x: centerX - headWidth / 2,
            y: silhouetteBox.minY + height * 0.07,
            width: headWidth,
            height: headHeight
        )

        let neckY = headRect.maxY - height * 0.008
        let shoulderY = silhouetteBox.minY + height * 0.24
        let waistY = silhouetteBox.minY + height * 0.42
        let hipY = silhouetteBox.minY + height * 0.57
        let handY = silhouetteBox.minY + height * metrics.handHeight
        let footY = silhouetteBox.minY + height * metrics.footHeight
        let shoulderHalf = width * 0.18
        let waistHalf = width * 0.10
        let hipHalf = width * 0.14
        let handHalf = width * 0.17
        let ankleHalf = width * 0.055
        let innerAnkleHalf = width * 0.016
        let neckHalf = headWidth * 0.13

        var silhouette = Path()
        silhouette.move(to: CGPoint(x: centerX - neckHalf, y: neckY))
        silhouette.addQuadCurve(
            to: CGPoint(x: centerX - shoulderHalf, y: shoulderY),
            control: CGPoint(x: centerX - width * 0.11, y: headRect.maxY + height * 0.015)
        )
        silhouette.addCurve(
            to: CGPoint(x: centerX - handHalf, y: handY),
            control1: CGPoint(x: centerX - width * 0.21, y: silhouetteBox.minY + height * 0.36),
            control2: CGPoint(x: centerX - width * 0.23, y: silhouetteBox.minY + height * 0.57)
        )
        silhouette.addQuadCurve(
            to: CGPoint(x: centerX - waistHalf, y: waistY),
            control: CGPoint(x: centerX - width * 0.13, y: silhouetteBox.minY + height * 0.65)
        )
        silhouette.addCurve(
            to: CGPoint(x: centerX - hipHalf, y: hipY),
            control1: CGPoint(x: centerX - width * 0.11, y: silhouetteBox.minY + height * 0.49),
            control2: CGPoint(x: centerX - width * 0.17, y: silhouetteBox.minY + height * 0.55)
        )
        silhouette.addCurve(
            to: CGPoint(x: centerX - ankleHalf, y: footY),
            control1: CGPoint(x: centerX - width * 0.16, y: silhouetteBox.minY + height * 0.71),
            control2: CGPoint(x: centerX - width * 0.09, y: silhouetteBox.minY + height * 0.91)
        )
        silhouette.addQuadCurve(
            to: CGPoint(x: centerX - innerAnkleHalf, y: footY),
            control: CGPoint(x: centerX - width * 0.038, y: silhouetteBox.minY + height * 1.005)
        )
        silhouette.addQuadCurve(
            to: CGPoint(x: centerX + innerAnkleHalf, y: footY),
            control: CGPoint(x: centerX, y: silhouetteBox.minY + height * 0.955)
        )
        silhouette.addQuadCurve(
            to: CGPoint(x: centerX + ankleHalf, y: footY),
            control: CGPoint(x: centerX + width * 0.038, y: silhouetteBox.minY + height * 1.005)
        )
        silhouette.addCurve(
            to: CGPoint(x: centerX + hipHalf, y: hipY),
            control1: CGPoint(x: centerX + width * 0.09, y: silhouetteBox.minY + height * 0.91),
            control2: CGPoint(x: centerX + width * 0.16, y: silhouetteBox.minY + height * 0.71)
        )
        silhouette.addCurve(
            to: CGPoint(x: centerX + waistHalf, y: waistY),
            control1: CGPoint(x: centerX + width * 0.17, y: silhouetteBox.minY + height * 0.55),
            control2: CGPoint(x: centerX + width * 0.11, y: silhouetteBox.minY + height * 0.49)
        )
        silhouette.addQuadCurve(
            to: CGPoint(x: centerX + handHalf, y: handY),
            control: CGPoint(x: centerX + width * 0.13, y: silhouetteBox.minY + height * 0.65)
        )
        silhouette.addCurve(
            to: CGPoint(x: centerX + shoulderHalf, y: shoulderY),
            control1: CGPoint(x: centerX + width * 0.23, y: silhouetteBox.minY + height * 0.57),
            control2: CGPoint(x: centerX + width * 0.21, y: silhouetteBox.minY + height * 0.36)
        )
        silhouette.addQuadCurve(
            to: CGPoint(x: centerX + neckHalf, y: neckY),
            control: CGPoint(x: centerX + width * 0.11, y: headRect.maxY + height * 0.015)
        )
        silhouette.closeSubpath()

        var legGap = Path()
        legGap.move(to: CGPoint(x: centerX - width * 0.018, y: hipY + height * 0.03))
        legGap.addQuadCurve(
            to: CGPoint(x: centerX, y: footY - height * 0.12),
            control: CGPoint(x: centerX - width * 0.012, y: silhouetteBox.minY + height * 0.80)
        )
        legGap.addQuadCurve(
            to: CGPoint(x: centerX + width * 0.018, y: hipY + height * 0.03),
            control: CGPoint(x: centerX + width * 0.012, y: silhouetteBox.minY + height * 0.80)
        )
        legGap.closeSubpath()
        silhouette.addPath(legGap)

        let silhouetteTransform = LivePoseOverlayRenderer.silhouetteTransform(
            for: CGRect(
                x: centerX - shoulderHalf,
                y: headRect.minY,
                width: shoulderHalf * 2,
                height: footY - headRect.minY
            ),
            isUpsideDown: isUpsideDown
        )

        let resolvedHead = Path(ellipseIn: headRect).applying(silhouetteTransform)
        let resolvedBody = silhouette.applying(silhouetteTransform)
        context.addFilter(.shadow(color: silhouetteGlow, radius: 10, x: 0, y: 0))
        context.fill(resolvedHead, with: .color(silhouetteFill))
        context.fill(
            resolvedBody,
            with: .color(silhouetteFill),
            style: FillStyle(eoFill: true, antialiased: true)
        )
    }

    private func drawAdaptiveSilhouette(
        context: inout GraphicsContext,
        silhouette: PoseAdaptiveSilhouette
    ) {
        LivePoseOverlayRenderer.drawHighlight(
            context: &context,
            silhouette: silhouette,
            fillColor: Color.white.opacity(0.70),
            glowColor: Color.white.opacity(0.06)
        )
    }

    private func fallbackSilhouetteMetrics(for template: ShotTemplate) -> (
        topInset: CGFloat,
        heightFactor: CGFloat,
        handHeight: CGFloat,
        footHeight: CGFloat
    ) {
        switch template.id {
        case .portrait:
            return (topInset: 0.08, heightFactor: 0.56, handHeight: 0.76, footHeight: 0.92)
        case .halfBody:
            return (topInset: 0.07, heightFactor: 0.72, handHeight: 0.74, footHeight: 0.95)
        case .ruleOfThirds:
            return (topInset: 0.07, heightFactor: 0.78, handHeight: 0.75, footHeight: 0.97)
        case .fullBody, .outfit, .instagramStory:
            return (topInset: 0.05, heightFactor: 0.90, handHeight: 0.73, footHeight: 0.98)
        }
    }

    private func syncDisplayedBodyDescriptor() {
        guard let nextDescriptor = poseFrame?.renderDescriptor(for: template) else {
            displayedRenderDescriptor = nil
            return
        }

        if let currentDescriptor = displayedRenderDescriptor {
            displayedRenderDescriptor = currentDescriptor.blended(toward: nextDescriptor, factor: 0.30)
        } else {
            displayedRenderDescriptor = nextDescriptor
        }
    }
}

struct PoseAdaptiveSilhouette {
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

    func applying(_ transform: CGAffineTransform) -> PoseAdaptiveSilhouette {
        PoseAdaptiveSilhouette(
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

enum LivePoseOverlayRenderer {
    static func resolvedSilhouette(
        for descriptor: PoseRenderDescriptor,
        in size: CGSize,
        isUpsideDown: Bool
    ) -> PoseAdaptiveSilhouette {
        let silhouette = makeAdaptiveSilhouette(in: size, bodyDescriptor: descriptor)

        guard isUpsideDown else {
            return silhouette
        }

        let bounds = silhouette.compositePath.boundingRect
        let transform = silhouetteTransform(for: bounds, isUpsideDown: true)
        return silhouette.applying(transform)
    }

    static func drawHighlight(
        context: inout GraphicsContext,
        silhouette: PoseAdaptiveSilhouette,
        fillColor: Color,
        glowColor: Color,
        edgeColor: Color? = nil
    ) {
        context.addFilter(.shadow(color: glowColor, radius: 10, x: 0, y: 0))
        context.fill(Path(ellipseIn: silhouette.headRect), with: .color(fillColor))
        context.fill(silhouette.torso, with: .color(fillColor))
        context.stroke(
            silhouette.leftArm,
            with: .color(fillColor),
            style: StrokeStyle(lineWidth: silhouette.armWidth, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            silhouette.rightArm,
            with: .color(fillColor),
            style: StrokeStyle(lineWidth: silhouette.armWidth, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            silhouette.leftLeg,
            with: .color(fillColor),
            style: StrokeStyle(lineWidth: silhouette.legWidth, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            silhouette.rightLeg,
            with: .color(fillColor),
            style: StrokeStyle(lineWidth: silhouette.legWidth, lineCap: .round, lineJoin: .round)
        )

        if let edgeColor {
            context.stroke(
                silhouette.compositePath,
                with: .color(edgeColor),
                style: StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private static func makeAdaptiveSilhouette(
        in size: CGSize,
        bodyDescriptor: PoseRenderDescriptor
    ) -> PoseAdaptiveSilhouette {
        let headCenter = point(from: bodyDescriptor.headCenter.point, in: size)
        let shoulderCenter = point(from: bodyDescriptor.shoulderCenter, in: size)
        let hipCenter = point(from: bodyDescriptor.hipCenter, in: size)
        let leftShoulder = point(from: bodyDescriptor.leftShoulder.point, in: size)
        let rightShoulder = point(from: bodyDescriptor.rightShoulder.point, in: size)
        let leftHip = point(from: bodyDescriptor.leftHip.point, in: size)
        let rightHip = point(from: bodyDescriptor.rightHip.point, in: size)
        let shoulderSpan = max(distance(leftShoulder, rightShoulder), size.width * 0.10)
        let hipSpan = max(distance(leftHip, rightHip), shoulderSpan * 0.60)
        let bodyHeight = max(bodyDescriptor.subjectBounds.height * size.height, size.height * 0.20)
        let headWidth = max(bodyDescriptor.headSize.width * size.width, shoulderSpan * 0.28, hipSpan * 0.34)
        let headHeight = max(bodyDescriptor.headSize.height * size.height, headWidth * 1.10)
        let headRect = CGRect(
            x: headCenter.x - headWidth / 2,
            y: headCenter.y - headHeight * 0.44,
            width: headWidth,
            height: headHeight
        )

        let shoulderAxis = normalizedAxis(from: leftShoulder, to: rightShoulder)
        let hipAxis = normalizedAxis(from: leftHip, to: rightHip)
        let shoulderOffset = shoulderAxis.scaled(by: shoulderSpan * 0.12)
        let hipOffset = hipAxis.scaled(by: hipSpan * 0.10)
        let leftShoulderOuter = leftShoulder.subtracting(shoulderOffset)
        let rightShoulderOuter = rightShoulder.adding(shoulderOffset)
        let leftHipOuter = leftHip.subtracting(hipOffset)
        let rightHipOuter = rightHip.adding(hipOffset)
        let leftWaist = interpolate(
            from: leftShoulderOuter,
            to: leftHipOuter,
            t: 0.58
        )
        let rightWaist = interpolate(
            from: rightShoulderOuter,
            to: rightHipOuter,
            t: 0.58
        )

        var torso = Path()
        torso.move(to: leftShoulderOuter)
        torso.addQuadCurve(
            to: rightShoulderOuter,
            control: CGPoint(
                x: shoulderCenter.x,
                y: min(leftShoulderOuter.y, rightShoulderOuter.y) - bodyHeight * 0.10
            )
        )
        torso.addCurve(
            to: rightWaist,
            control1: CGPoint(
                x: rightShoulderOuter.x + shoulderSpan * 0.06,
                y: rightShoulderOuter.y + bodyHeight * 0.12
            ),
            control2: CGPoint(
                x: rightWaist.x + shoulderSpan * 0.05,
                y: rightWaist.y - bodyHeight * 0.10
            )
        )
        torso.addCurve(
            to: rightHipOuter,
            control1: CGPoint(
                x: rightWaist.x + shoulderSpan * 0.02,
                y: rightWaist.y + bodyHeight * 0.05
            ),
            control2: CGPoint(
                x: rightHipOuter.x + hipSpan * 0.03,
                y: rightHipOuter.y - bodyHeight * 0.05
            )
        )
        torso.addQuadCurve(
            to: leftHipOuter,
            control: CGPoint(
                x: hipCenter.x,
                y: max(leftHipOuter.y, rightHipOuter.y) + bodyHeight * 0.04
            )
        )
        torso.addCurve(
            to: leftWaist,
            control1: CGPoint(
                x: leftHipOuter.x - hipSpan * 0.03,
                y: leftHipOuter.y - bodyHeight * 0.05
            ),
            control2: CGPoint(
                x: leftWaist.x - shoulderSpan * 0.05,
                y: leftWaist.y + bodyHeight * 0.05
            )
        )
        torso.addCurve(
            to: leftShoulderOuter,
            control1: CGPoint(
                x: leftWaist.x - shoulderSpan * 0.05,
                y: leftWaist.y - bodyHeight * 0.10
            ),
            control2: CGPoint(
                x: leftShoulderOuter.x - shoulderSpan * 0.06,
                y: leftShoulderOuter.y + bodyHeight * 0.12
            )
        )
        torso.closeSubpath()

        let leftArm = limbPath(points: [
            leftShoulder,
            optionalPoint(from: bodyDescriptor.leftElbow?.point, in: size),
            optionalPoint(from: bodyDescriptor.leftWrist?.point, in: size),
        ].compactMap { $0 })
        let rightArm = limbPath(points: [
            rightShoulder,
            optionalPoint(from: bodyDescriptor.rightElbow?.point, in: size),
            optionalPoint(from: bodyDescriptor.rightWrist?.point, in: size),
        ].compactMap { $0 })
        let leftLeg = limbPath(points: [
            leftHip,
            optionalPoint(from: bodyDescriptor.leftKnee?.point, in: size),
            optionalPoint(from: bodyDescriptor.leftAnkle?.point, in: size),
        ].compactMap { $0 })
        let rightLeg = limbPath(points: [
            rightHip,
            optionalPoint(from: bodyDescriptor.rightKnee?.point, in: size),
            optionalPoint(from: bodyDescriptor.rightAnkle?.point, in: size),
        ].compactMap { $0 })

        return PoseAdaptiveSilhouette(
            headRect: headRect,
            torso: torso,
            leftArm: leftArm,
            rightArm: rightArm,
            leftLeg: leftLeg,
            rightLeg: rightLeg,
            armWidth: max(shoulderSpan * 0.17, size.width * 0.022),
            legWidth: max(hipSpan * 0.22, size.width * 0.024)
        )
    }

    private static func point(from normalizedPoint: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: normalizedPoint.x * size.width, y: normalizedPoint.y * size.height)
    }

    private static func optionalPoint(from normalizedPoint: CGPoint?, in size: CGSize) -> CGPoint? {
        guard let normalizedPoint else {
            return nil
        }

        return point(from: normalizedPoint, in: size)
    }

    private static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    private static func interpolate(from start: CGPoint, to end: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(
            x: start.x + (end.x - start.x) * t,
            y: start.y + (end.y - start.y) * t
        )
    }

    private static func normalizedAxis(from start: CGPoint, to end: CGPoint) -> CGPoint {
        let deltaX = end.x - start.x
        let deltaY = end.y - start.y
        let length = max(hypot(deltaX, deltaY), 0.001)
        return CGPoint(x: deltaX / length, y: deltaY / length)
    }

    private static func limbPath(points: [CGPoint]) -> Path {
        guard points.count > 1 else {
            return Path()
        }

        var path = Path()
        path.move(to: points[0])

        if points.count == 3 {
            path.addQuadCurve(to: points[2], control: points[1])
            return path
        }

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        return path
    }

    static func silhouetteTransform(
        for bounds: CGRect,
        isUpsideDown: Bool
    ) -> CGAffineTransform {
        guard isUpsideDown else {
            return .identity
        }

        return CGAffineTransform(translationX: bounds.midX, y: bounds.midY)
            .rotated(by: .pi)
            .translatedBy(x: -bounds.midX, y: -bounds.midY)
    }
}

private extension CGPoint {
    func adding(_ other: CGPoint) -> CGPoint {
        CGPoint(x: x + other.x, y: y + other.y)
    }

    func subtracting(_ other: CGPoint) -> CGPoint {
        CGPoint(x: x - other.x, y: y - other.y)
    }

    func scaled(by scalar: CGFloat) -> CGPoint {
        CGPoint(x: x * scalar, y: y * scalar)
    }
}
