import Foundation
import Photos

enum PhotoLibraryExporterError: LocalizedError {
    case authorizationDenied
    case couldNotCreateAsset

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Photo Library access was denied."
        case .couldNotCreateAsset:
            return "The photo could not be exported."
        }
    }
}

final class PhotoLibraryExporter {
    func exportPhoto(at fileURL: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        guard status == .authorized || status == .limited else {
            throw PhotoLibraryExporterError.authorizationDenied
        }

        let signpost = PerformanceSignposts.beginInterval("photo_export")
        defer { PerformanceSignposts.endInterval("photo_export", signpost) }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, fileURL: fileURL, options: nil)
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: PhotoLibraryExporterError.couldNotCreateAsset)
                }
            })
        }
    }
}
