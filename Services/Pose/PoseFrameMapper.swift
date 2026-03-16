import CoreGraphics

struct PoseLandmarkCandidate: Equatable {
    let x: CGFloat
    let y: CGFloat
    let confidence: CGFloat
}

enum PoseFrameMapper {
    static let confidenceThreshold: CGFloat = 0.2

    static func map(
        candidates: [PoseLandmarkName: PoseLandmarkCandidate],
        timestampSeconds: Double,
        confidenceThreshold: CGFloat = PoseFrameMapper.confidenceThreshold
    ) -> PoseFrame {
        let landmarks = candidates.reduce(into: PoseLandmarks()) { partialResult, entry in
            let (name, candidate) = entry

            guard candidate.confidence >= confidenceThreshold else {
                return
            }

            partialResult[name] = PoseLandmark(
                x: min(max(candidate.x, 0), 1),
                y: min(max(1 - candidate.y, 0), 1),
                confidence: candidate.confidence
            )
        }

        return PoseFrame(landmarks: landmarks, timestampSeconds: timestampSeconds)
    }
}
