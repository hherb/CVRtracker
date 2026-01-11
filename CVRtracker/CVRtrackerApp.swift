import SwiftUI
import SwiftData

@main
struct CVRtrackerApp: App {
    /// The shared model container, configured based on user's iCloud sync preference.
    ///
    /// The container is created once at app launch. If the user changes their
    /// iCloud sync preference in Profile settings, they need to restart the app
    /// for the change to take effect.
    var sharedModelContainer: ModelContainer = {
        do {
            // Container configuration (local vs iCloud) is determined by
            // iCloudSyncManager.shouldUseiCloud which reads from UserDefaults
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
