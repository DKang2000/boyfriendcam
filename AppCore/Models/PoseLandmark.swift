import CoreGraphics

struct PoseLandmark: Equatable {
    let x: CGFloat
    let y: CGFloat
    let confidence: CGFloat
}

typealias PoseLandmarks = [PoseLandmarkName: PoseLandmark]
