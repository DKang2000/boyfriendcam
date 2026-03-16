import SwiftUI

@main
struct BoyfriendCamNativeApp: App {
    private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    var body: some Scene {
        WindowGroup {
            RootAppView(isRunningTests: isRunningTests)
        }
    }
}

private struct RootAppView: View {
    let isRunningTests: Bool

    var body: some View {
        if isRunningTests {
            Color.clear
        } else {
            CameraRootView()
        }
    }
}

private struct CameraRootView: View {
    @StateObject private var environment = AppEnvironment()

    var body: some View {
        CameraScreen(viewModel: environment.cameraShellViewModel)
    }
}
