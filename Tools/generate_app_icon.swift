import AppKit

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)

let sizes: [(filename: String, pixels: Int)] = [
    ("icon-20@2x.png", 40),
    ("icon-20@3x.png", 60),
    ("icon-29@2x.png", 58),
    ("icon-29@3x.png", 87),
    ("icon-40@2x.png", 80),
    ("icon-40@3x.png", 120),
    ("icon-60@2x.png", 120),
    ("icon-60@3x.png", 180),
    ("icon-1024.png", 1024),
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(
        roundedRect: rect,
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
    )
}

func sparklePath(center: CGPoint, size: CGFloat) -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: center.x, y: center.y + size))
    path.addLine(to: CGPoint(x: center.x + size * 0.26, y: center.y + size * 0.26))
    path.addLine(to: CGPoint(x: center.x + size, y: center.y))
    path.addLine(to: CGPoint(x: center.x + size * 0.26, y: center.y - size * 0.26))
    path.addLine(to: CGPoint(x: center.x, y: center.y - size))
    path.addLine(to: CGPoint(x: center.x - size * 0.26, y: center.y - size * 0.26))
    path.addLine(to: CGPoint(x: center.x - size, y: center.y))
    path.addLine(to: CGPoint(x: center.x - size * 0.26, y: center.y + size * 0.26))
    path.closeSubpath()
    return path
}

func drawBracket(
    in context: CGContext,
    origin: CGPoint,
    horizontal: CGFloat,
    vertical: CGFloat,
    lineWidth: CGFloat,
    mirroredX: Bool,
    mirroredY: Bool
) {
    let xDirection: CGFloat = mirroredX ? -1 : 1
    let yDirection: CGFloat = mirroredY ? -1 : 1
    context.move(to: origin)
    context.addLine(to: CGPoint(x: origin.x + horizontal * xDirection, y: origin.y))
    context.move(to: origin)
    context.addLine(to: CGPoint(x: origin.x, y: origin.y + vertical * yDirection))
    context.setLineWidth(lineWidth)
    context.strokePath()
}

func drawCurvedArrow(
    in context: CGContext,
    center: CGPoint,
    radius: CGFloat,
    startAngle: CGFloat,
    endAngle: CGFloat,
    clockwise: Bool,
    lineWidth: CGFloat
) {
    let path = CGMutablePath()
    path.addArc(
        center: center,
        radius: radius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: clockwise
    )
    context.addPath(path)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.strokePath()

    let tip = CGPoint(
        x: center.x + cos(endAngle) * radius,
        y: center.y + sin(endAngle) * radius
    )
    let tangentAngle = endAngle + (clockwise ? -.pi / 2 : .pi / 2)
    let arrowSize = radius * 0.12
    let left = CGPoint(
        x: tip.x + cos(tangentAngle + .pi * 0.80) * arrowSize,
        y: tip.y + sin(tangentAngle + .pi * 0.80) * arrowSize
    )
    let right = CGPoint(
        x: tip.x + cos(tangentAngle - .pi * 0.80) * arrowSize,
        y: tip.y + sin(tangentAngle - .pi * 0.80) * arrowSize
    )
    context.move(to: tip)
    context.addLine(to: left)
    context.move(to: tip)
    context.addLine(to: right)
    context.setLineWidth(lineWidth)
    context.strokePath()
}

func drawSilhouette(in context: CGContext, rect: CGRect) {
    let path = CGMutablePath()
    let centerX = rect.midX
    let top = rect.maxY
    let bottom = rect.minY
    let width = rect.width
    let height = rect.height

    path.move(to: CGPoint(x: centerX, y: top))
    path.addCurve(
        to: CGPoint(x: centerX - width * 0.23, y: top - height * 0.14),
        control1: CGPoint(x: centerX - width * 0.08, y: top),
        control2: CGPoint(x: centerX - width * 0.22, y: top - height * 0.05)
    )
    path.addCurve(
        to: CGPoint(x: centerX - width * 0.28, y: top - height * 0.34),
        control1: CGPoint(x: centerX - width * 0.29, y: top - height * 0.20),
        control2: CGPoint(x: centerX - width * 0.31, y: top - height * 0.27)
    )
    path.addCurve(
        to: CGPoint(x: centerX - width * 0.18, y: top - height * 0.60),
        control1: CGPoint(x: centerX - width * 0.27, y: top - height * 0.44),
        control2: CGPoint(x: centerX - width * 0.25, y: top - height * 0.53)
    )
    path.addCurve(
        to: CGPoint(x: centerX - width * 0.15, y: bottom + height * 0.08),
        control1: CGPoint(x: centerX - width * 0.11, y: top - height * 0.75),
        control2: CGPoint(x: centerX - width * 0.16, y: bottom + height * 0.24)
    )
    path.addCurve(
        to: CGPoint(x: centerX - width * 0.04, y: bottom),
        control1: CGPoint(x: centerX - width * 0.14, y: bottom + height * 0.03),
        control2: CGPoint(x: centerX - width * 0.09, y: bottom)
    )
    path.addLine(to: CGPoint(x: centerX + width * 0.04, y: bottom))
    path.addCurve(
        to: CGPoint(x: centerX + width * 0.15, y: bottom + height * 0.08),
        control1: CGPoint(x: centerX + width * 0.09, y: bottom),
        control2: CGPoint(x: centerX + width * 0.14, y: bottom + height * 0.03)
    )
    path.addCurve(
        to: CGPoint(x: centerX + width * 0.18, y: top - height * 0.60),
        control1: CGPoint(x: centerX + width * 0.16, y: bottom + height * 0.24),
        control2: CGPoint(x: centerX + width * 0.11, y: top - height * 0.75)
    )
    path.addCurve(
        to: CGPoint(x: centerX + width * 0.28, y: top - height * 0.34),
        control1: CGPoint(x: centerX + width * 0.25, y: top - height * 0.53),
        control2: CGPoint(x: centerX + width * 0.27, y: top - height * 0.44)
    )
    path.addCurve(
        to: CGPoint(x: centerX + width * 0.23, y: top - height * 0.14),
        control1: CGPoint(x: centerX + width * 0.31, y: top - height * 0.27),
        control2: CGPoint(x: centerX + width * 0.29, y: top - height * 0.20)
    )
    path.addCurve(
        to: CGPoint(x: centerX, y: top),
        control1: CGPoint(x: centerX + width * 0.22, y: top - height * 0.05),
        control2: CGPoint(x: centerX + width * 0.08, y: top)
    )
    path.closeSubpath()

    context.saveGState()
    context.addPath(path)
    context.clip()

    let silhouetteGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color(253, 243, 210).cgColor,
            color(248, 190, 126).cgColor,
            color(51, 37, 49, 0.72).cgColor,
        ] as CFArray,
        locations: [0, 0.56, 1]
    )!
    context.drawLinearGradient(
        silhouetteGradient,
        start: CGPoint(x: rect.midX, y: rect.maxY),
        end: CGPoint(x: rect.midX, y: rect.minY),
        options: []
    )

    context.restoreGState()
}

func drawIcon(into context: CGContext, size: CGSize) {
    let scale = size.width / 1024
    let rect = CGRect(origin: .zero, size: size)

    context.saveGState()
    context.addPath(roundedRectPath(rect, radius: 230 * scale))
    context.clip()

    let backgroundGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color(44, 37, 52).cgColor,
            color(24, 21, 33).cgColor,
            color(14, 13, 23).cgColor,
        ] as CFArray,
        locations: [0, 0.56, 1]
    )!
    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: size.width * 0.86, y: size.height),
        end: CGPoint(x: size.width * 0.12, y: 0),
        options: []
    )

    context.setFillColor(color(255, 208, 156, 0.18).cgColor)
    context.fillEllipse(in: CGRect(x: 430 * scale, y: 720 * scale, width: 520 * scale, height: 240 * scale))
    context.setFillColor(color(247, 151, 82, 0.15).cgColor)
    context.fillEllipse(in: CGRect(x: 460 * scale, y: 520 * scale, width: 300 * scale, height: 240 * scale))
    context.setFillColor(color(255, 255, 255, 0.04).cgColor)
    context.fillEllipse(in: CGRect(x: 150 * scale, y: 90 * scale, width: 720 * scale, height: 260 * scale))

    let lensCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.53)
    let outerRadius = 370 * scale

    context.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 35 * scale, color: color(255, 209, 161, 0.18).cgColor)
    context.setFillColor(color(16, 15, 25, 0.84).cgColor)
    context.fillEllipse(in: CGRect(
        x: lensCenter.x - outerRadius,
        y: lensCenter.y - outerRadius,
        width: outerRadius * 2,
        height: outerRadius * 2
    ))
    context.setShadow(offset: .zero, blur: 0, color: nil)

    let ringConfigs: [(radius: CGFloat, width: CGFloat, stroke: NSColor)] = [
        (370, 18, color(242, 223, 205, 0.90)),
        (344, 16, color(123, 138, 170, 0.70)),
        (317, 11, color(23, 20, 33, 0.90)),
        (287, 10, color(120, 99, 93, 0.75)),
        (258, 9, color(241, 221, 197, 0.52)),
    ]

    for ring in ringConfigs {
        context.setStrokeColor(ring.stroke.cgColor)
        context.setLineWidth(ring.width * scale)
        context.strokeEllipse(in: CGRect(
            x: lensCenter.x - ring.radius * scale,
            y: lensCenter.y - ring.radius * scale,
            width: ring.radius * 2 * scale,
            height: ring.radius * 2 * scale
        ))
    }

    let innerRect = CGRect(
        x: lensCenter.x - 250 * scale,
        y: lensCenter.y - 250 * scale,
        width: 500 * scale,
        height: 500 * scale
    )
    context.saveGState()
    context.addEllipse(in: innerRect)
    context.clip()

    let glassGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color(74, 60, 72).cgColor,
            color(43, 30, 42).cgColor,
            color(20, 19, 30).cgColor,
        ] as CFArray,
        locations: [0, 0.52, 1]
    )!
    context.drawRadialGradient(
        glassGradient,
        startCenter: CGPoint(x: lensCenter.x - 32 * scale, y: lensCenter.y + 56 * scale),
        startRadius: 10 * scale,
        endCenter: lensCenter,
        endRadius: 300 * scale,
        options: []
    )

    context.setFillColor(color(255, 181, 112, 0.20).cgColor)
    context.fillEllipse(in: CGRect(x: 370 * scale, y: 510 * scale, width: 310 * scale, height: 240 * scale))
    context.setFillColor(color(255, 255, 255, 0.04).cgColor)
    context.fillEllipse(in: CGRect(x: 335 * scale, y: 610 * scale, width: 220 * scale, height: 120 * scale))
    context.restoreGState()

    let silhouetteRect = CGRect(x: 444 * scale, y: 282 * scale, width: 136 * scale, height: 382 * scale)
    drawSilhouette(in: context, rect: silhouetteRect)

    context.setStrokeColor(color(241, 230, 217, 0.82).cgColor)
    drawBracket(
        in: context,
        origin: CGPoint(x: 414 * scale, y: 590 * scale),
        horizontal: 58 * scale,
        vertical: 58 * scale,
        lineWidth: 6 * scale,
        mirroredX: false,
        mirroredY: false
    )
    drawBracket(
        in: context,
        origin: CGPoint(x: 610 * scale, y: 590 * scale),
        horizontal: 58 * scale,
        vertical: 58 * scale,
        lineWidth: 6 * scale,
        mirroredX: true,
        mirroredY: false
    )
    drawBracket(
        in: context,
        origin: CGPoint(x: 414 * scale, y: 394 * scale),
        horizontal: 58 * scale,
        vertical: 58 * scale,
        lineWidth: 6 * scale,
        mirroredX: false,
        mirroredY: true
    )
    drawBracket(
        in: context,
        origin: CGPoint(x: 610 * scale, y: 394 * scale),
        horizontal: 58 * scale,
        vertical: 58 * scale,
        lineWidth: 6 * scale,
        mirroredX: true,
        mirroredY: true
    )

    context.setStrokeColor(color(210, 176, 132, 0.92).cgColor)
    drawCurvedArrow(
        in: context,
        center: CGPoint(x: 390 * scale, y: 510 * scale),
        radius: 84 * scale,
        startAngle: .pi * 0.18,
        endAngle: .pi * 1.00,
        clockwise: false,
        lineWidth: 6 * scale
    )
    drawCurvedArrow(
        in: context,
        center: CGPoint(x: 634 * scale, y: 510 * scale),
        radius: 84 * scale,
        startAngle: .pi,
        endAngle: .pi * 1.82,
        clockwise: false,
        lineWidth: 6 * scale
    )

    context.setFillColor(color(255, 191, 104, 0.96).cgColor)
    context.addPath(sparklePath(center: CGPoint(x: 332 * scale, y: 820 * scale), size: 18 * scale))
    context.fillPath()
    context.addPath(sparklePath(center: CGPoint(x: 804 * scale, y: 238 * scale), size: 16 * scale))
    context.fillPath()

    context.saveGState()
    context.setBlendMode(.screen)
    let flareGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color(255, 255, 240, 0.98).cgColor,
            color(255, 180, 92, 0.78).cgColor,
            color(255, 180, 92, 0).cgColor,
        ] as CFArray,
        locations: [0, 0.2, 1]
    )!
    context.drawRadialGradient(
        flareGradient,
        startCenter: CGPoint(x: 442 * scale, y: 646 * scale),
        startRadius: 8 * scale,
        endCenter: CGPoint(x: 442 * scale, y: 646 * scale),
        endRadius: 96 * scale,
        options: []
    )
    context.drawRadialGradient(
        flareGradient,
        startCenter: CGPoint(x: 690 * scale, y: 352 * scale),
        startRadius: 8 * scale,
        endCenter: CGPoint(x: 690 * scale, y: 352 * scale),
        endRadius: 90 * scale,
        options: []
    )
    context.restoreGState()

    context.restoreGState()
}

func writeImage(filename: String, pixels: Int) throws {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    bitmap.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current = graphicsContext
    graphicsContext.cgContext.interpolationQuality = .high
    drawIcon(into: graphicsContext.cgContext, size: CGSize(width: pixels, height: pixels))
    graphicsContext.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    let data = bitmap.representation(using: .png, properties: [:])!
    try data.write(to: outputDirectory.appendingPathComponent(filename))
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
for size in sizes {
    try writeImage(filename: size.filename, pixels: size.pixels)
}
