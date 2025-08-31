import SwiftUI
import SwiftData

@main
struct FocusTimeNowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ActivityEvent.self, Project.self])
    }
}