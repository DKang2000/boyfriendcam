enum PoseLandmarkName: String, CaseIterable, Hashable {
    case nose
    case leftEyeInner
    case leftEye
    case leftEyeOuter
    case rightEyeInner
    case rightEye
    case rightEyeOuter
    case leftEar
    case rightEar
    case leftMouth
    case rightMouth
    case leftShoulder
    case rightShoulder
    case leftElbow
    case rightElbow
    case leftWrist
    case rightWrist
    case leftPinky
    case rightPinky
    case leftIndex
    case rightIndex
    case leftThumb
    case rightThumb
    case leftHip
    case rightHip
    case leftKnee
    case rightKnee
    case leftAnkle
    case rightAnkle
    case leftHeel
    case rightHeel
    case leftFootIndex
    case rightFootIndex
}

extension PoseLandmarkName {
    static let debugConnections: [(PoseLandmarkName, PoseLandmarkName)] = [
        (.leftEyeInner, .leftEye),
        (.leftEye, .leftEyeOuter),
        (.leftEyeOuter, .leftEar),
        (.rightEyeInner, .rightEye),
        (.rightEye, .rightEyeOuter),
        (.rightEyeOuter, .rightEar),
        (.nose, .leftEyeInner),
        (.nose, .rightEyeInner),
        (.leftMouth, .rightMouth),
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.leftWrist, .leftThumb),
        (.leftWrist, .leftPinky),
        (.leftWrist, .leftIndex),
        (.leftPinky, .leftIndex),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.rightWrist, .rightThumb),
        (.rightWrist, .rightPinky),
        (.rightWrist, .rightIndex),
        (.rightPinky, .rightIndex),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.leftAnkle, .leftHeel),
        (.leftHeel, .leftFootIndex),
        (.leftAnkle, .leftFootIndex),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
        (.rightAnkle, .rightHeel),
        (.rightHeel, .rightFootIndex),
        (.rightAnkle, .rightFootIndex),
    ]
}
