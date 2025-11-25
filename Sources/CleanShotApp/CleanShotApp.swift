import SwiftUI

@main
struct CleanShotApp: App {
    @StateObject private var classifier = ScreenshotClassifier()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(classifier)
        }
    }
}
