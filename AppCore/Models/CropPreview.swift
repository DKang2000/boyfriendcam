import CoreGraphics

enum CropPreviewID: String, CaseIterable, Identifiable, Codable {
    case none
    case square = "1_1"
    case fourByFive = "4_5"
    case nineBySixteen = "9_16"

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .none:
            return "Full"
        case .square:
            return "1:1"
        case .fourByFive:
            return "4:5"
        case .nineBySixteen:
            return "9:16"
        }
    }
}

struct CropPreviewConfiguration: Equatable {
    let id: CropPreviewID
    let aspectRatio: CGFloat?
    let summary: String

    func maskRect(in size: CGSize) -> CGRect {
        guard let aspectRatio else {
            return CGRect(origin: .zero, size: size)
        }

        guard size.width > 0, size.height > 0 else {
            return .zero
        }

        let containerAspectRatio = size.width / size.height

        if containerAspectRatio > aspectRatio {
            let width = size.height * aspectRatio
            return CGRect(
                x: (size.width - width) / 2,
                y: 0,
                width: width,
                height: size.height
            )
        }

        let height = size.width / aspectRatio
        return CGRect(
            x: 0,
            y: (size.height - height) / 2,
            width: size.width,
            height: height
        )
    }

    func normalizedRect(inContainerAspectRatio containerAspectRatio: CGFloat) -> NormalizedRect {
        guard let aspectRatio else {
            return NormalizedRect(x: 0, y: 0, width: 1, height: 1)
        }

        guard containerAspectRatio > 0 else {
            return NormalizedRect(x: 0, y: 0, width: 1, height: 1)
        }

        if containerAspectRatio > aspectRatio {
            let normalizedWidth = aspectRatio / containerAspectRatio
            return NormalizedRect(
                x: (1 - normalizedWidth) * 0.5,
                y: 0,
                width: normalizedWidth,
                height: 1
            )
        }

        let normalizedHeight = containerAspectRatio / aspectRatio
        return NormalizedRect(
            x: 0,
            y: (1 - normalizedHeight) * 0.5,
            width: 1,
            height: normalizedHeight
        )
    }
}

enum CropPreviewRegistry {
    static let configurations: [CropPreviewConfiguration] = [
        CropPreviewConfiguration(
            id: .none,
            aspectRatio: nil,
            summary: "Show the full frame."
        ),
        CropPreviewConfiguration(
            id: .square,
            aspectRatio: 1,
            summary: "Instagram square crop."
        ),
        CropPreviewConfiguration(
            id: .fourByFive,
            aspectRatio: 4 / 5,
            summary: "Instagram portrait crop."
        ),
        CropPreviewConfiguration(
            id: .nineBySixteen,
            aspectRatio: 9 / 16,
            summary: "Stories and reels crop."
        ),
    ]

    private static let registry: [CropPreviewID: CropPreviewConfiguration] = {
        Dictionary(uniqueKeysWithValues: configurations.map { ($0.id, $0) })
    }()

    static func configuration(for id: CropPreviewID) -> CropPreviewConfiguration {
        registry[id] ?? configurations[0]
    }
}
