import Foundation

actor CaptureOrchestrator {
    func capture(
        mode: CaptureMode,
        using cameraSessionController: CameraSessionController
    ) async throws -> [CapturedPhoto] {
        if mode == .single {
            return [try await cameraSessionController.capturePhotoAsync()]
        }

        let signpost = PerformanceSignposts.beginInterval("burst_capture")
        defer {
            PerformanceSignposts.endInterval("burst_capture", signpost)
            PerformanceSignposts.emitEvent("burst_completion")
        }

        var photos: [CapturedPhoto] = []
        photos.reserveCapacity(mode.frameCount)

        for index in 0..<mode.frameCount {
            photos.append(try await cameraSessionController.capturePhotoAsync())

            if index < mode.frameCount - 1 {
                try await Task.sleep(nanoseconds: 120_000_000)
            }
        }

        return photos
    }
}
