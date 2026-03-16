import AVFoundation
import UIKit

final class CameraPreviewView: UIView {
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private var normalizedSubjectFocusPoint: CGPoint?
    private var onResolvedSubjectFocusPoint: ((CGPoint?) -> Void)?
    private var lastReportedSubjectFocusPoint: CGPoint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        isOpaque = true
        isUserInteractionEnabled = false
        clipsToBounds = true

        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(previewLayer)
        print("[CameraPreviewView] init")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        isOpaque = true
        isUserInteractionEnabled = false
        clipsToBounds = true

        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(previewLayer)
        print("[CameraPreviewView] init(coder:)")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.commit()
        print("[CameraPreviewView] layoutSubviews bounds=\(bounds)")
        resolveSubjectFocusPointIfNeeded()
    }

    func setSession(_ session: AVCaptureSession) {
        if previewLayer.session !== session {
            previewLayer.session = session
            print("[CameraPreviewView] session attached")
            resolveSubjectFocusPointIfNeeded()
        }
    }

    func setVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        guard
            let connection = previewLayer.connection,
            connection.isVideoOrientationSupported
        else {
            print("[CameraPreviewView] orientation skipped because preview connection unavailable")
            return
        }

        connection.videoOrientation = orientation
        print("[CameraPreviewView] orientation set to \(orientation.rawValue)")
        resolveSubjectFocusPointIfNeeded()
    }

    func setSubjectFocusPoint(
        _ point: CGPoint?,
        onResolvedDevicePoint: @escaping (CGPoint?) -> Void
    ) {
        normalizedSubjectFocusPoint = point.map { CGPoint(
            x: min(max($0.x, 0), 1),
            y: min(max($0.y, 0), 1)
        ) }
        onResolvedSubjectFocusPoint = onResolvedDevicePoint
        resolveSubjectFocusPointIfNeeded()
    }

    private func resolveSubjectFocusPointIfNeeded() {
        guard let onResolvedSubjectFocusPoint else {
            return
        }

        guard let normalizedSubjectFocusPoint else {
            if lastReportedSubjectFocusPoint != nil {
                lastReportedSubjectFocusPoint = nil
                onResolvedSubjectFocusPoint(nil)
            }
            return
        }

        guard bounds.width > 0, bounds.height > 0 else {
            return
        }

        let layerPoint = CGPoint(
            x: normalizedSubjectFocusPoint.x * bounds.width,
            y: normalizedSubjectFocusPoint.y * bounds.height
        )
        let resolvedPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)

        guard shouldReportSubjectFocusPoint(resolvedPoint) else {
            return
        }

        lastReportedSubjectFocusPoint = resolvedPoint
        onResolvedSubjectFocusPoint(resolvedPoint)
    }

    private func shouldReportSubjectFocusPoint(_ point: CGPoint) -> Bool {
        guard let lastReportedSubjectFocusPoint else {
            return true
        }

        let deltaX = point.x - lastReportedSubjectFocusPoint.x
        let deltaY = point.y - lastReportedSubjectFocusPoint.y
        return sqrt(deltaX * deltaX + deltaY * deltaY) >= 0.015
    }
}
