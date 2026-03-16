import AVFoundation
import CoreVideo

final class LightingAnalysisService {
    private let minimumAnalysisInterval: Double
    private var lastAnalysisTimestamp = CMTime.invalid

    init(framesPerSecond: Double = 3) {
        minimumAnalysisInterval = 1 / max(framesPerSecond, 1)
    }

    func process(sampleBuffer: CMSampleBuffer) -> LightingAnalysisSummary? {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        guard shouldAnalyzeFrame(at: timestamp) else {
            return nil
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let planeIndex = 0
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex)

        guard
            width > 0,
            height > 0,
            let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex)
        else {
            return nil
        }

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let sampleColumns = 6
        let sampleRows = 8

        var totalLuma = 0.0
        var totalCount = 0.0
        var centerLuma = 0.0
        var centerCount = 0.0
        var edgeLuma = 0.0
        var edgeCount = 0.0
        var topLuma = 0.0
        var topCount = 0.0

        for row in 0..<sampleRows {
            let y = min((row * height) / sampleRows + height / (sampleRows * 2), height - 1)

            for column in 0..<sampleColumns {
                let x = min((column * width) / sampleColumns + width / (sampleColumns * 2), width - 1)
                let luma = Double(buffer[(y * bytesPerRow) + x]) / 255.0

                totalLuma += luma
                totalCount += 1

                let normalizedX = Double(x) / Double(width)
                let normalizedY = Double(y) / Double(height)

                if normalizedX >= 0.25, normalizedX <= 0.75, normalizedY >= 0.25, normalizedY <= 0.75 {
                    centerLuma += luma
                    centerCount += 1
                }

                if normalizedX <= 0.15 || normalizedX >= 0.85 {
                    edgeLuma += luma
                    edgeCount += 1
                }

                if normalizedY <= 0.25 {
                    topLuma += luma
                    topCount += 1
                }
            }
        }

        let average = totalLuma / max(totalCount, 1)
        let center = centerLuma / max(centerCount, 1)
        let edge = edgeLuma / max(edgeCount, 1)
        let top = topLuma / max(topCount, 1)

        return LightingAnalysisSummary(
            state: classify(averageLuma: average, centerLuma: center, edgeLuma: edge, topLuma: top),
            averageLuma: average,
            centerLuma: center,
            edgeLuma: edge,
            topLuma: top
        )
    }

    private func shouldAnalyzeFrame(at timestamp: CMTime) -> Bool {
        if !lastAnalysisTimestamp.isValid {
            lastAnalysisTimestamp = timestamp
            return true
        }

        let elapsed = timestamp.seconds - lastAnalysisTimestamp.seconds
        guard elapsed >= minimumAnalysisInterval else {
            return false
        }

        lastAnalysisTimestamp = timestamp
        return true
    }

    private func classify(
        averageLuma: Double,
        centerLuma: Double,
        edgeLuma: Double,
        topLuma: Double
    ) -> LightingState {
        if averageLuma < 0.26 {
            return .lowLight
        }

        if edgeLuma > centerLuma + 0.18 {
            return .backlit
        }

        if topLuma > averageLuma + 0.16, centerLuma < averageLuma - 0.05 {
            return .harshOverhead
        }

        return .balanced
    }
}
