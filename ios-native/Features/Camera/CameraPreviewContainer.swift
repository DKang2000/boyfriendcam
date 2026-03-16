import AVFoundation
import CoreGraphics
import SwiftUI

struct CameraPreviewContainer: UIViewRepresentable {
    let session: AVCaptureSession
    let orientation: AVCaptureVideoOrientation
    let subjectFocusPreviewPoint: CGPoint?
    let onResolvedSubjectFocusPoint: (CGPoint?) -> Void

    func makeUIView(context: Context) -> CameraPreviewView {
        let previewView = CameraPreviewView()
        previewView.setSession(session)
        previewView.setVideoOrientation(orientation)
        previewView.setSubjectFocusPoint(
            subjectFocusPreviewPoint,
            onResolvedDevicePoint: onResolvedSubjectFocusPoint
        )
        return previewView
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.setSession(session)
        uiView.setVideoOrientation(orientation)
        uiView.setSubjectFocusPoint(
            subjectFocusPreviewPoint,
            onResolvedDevicePoint: onResolvedSubjectFocusPoint
        )
    }
}
