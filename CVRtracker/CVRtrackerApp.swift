import SwiftUI
import SwiftData

@main
struct CVRtrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try CVRtrackerSchema.createContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var healthKitManager = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
