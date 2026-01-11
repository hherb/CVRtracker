import Foundation
import SwiftData

/// Schema configuration and model container factory for SwiftData persistence.
///
/// This struct centralizes SwiftData configuration for the app, including:
/// - Defining the list of persistent model types
/// - Creating the ModelContainer with error recovery
/// - Supporting optional iCloud sync via CloudKit
///
/// ## Migration Strategy
///
/// Currently uses a simple schema with automatic lightweight migration.
/// For production apps with existing users, implement proper `VersionedSchema`
/// migration to preserve user data during schema changes.
///
/// ## iCloud Sync
///
/// When iCloud sync is enabled by the user, the container uses CloudKit
/// for automatic synchronization across devices. The sync preference is
/// stored in UserDefaults and read at app launch.
///
/// ## Error Recovery
///
/// If the database cannot be opened (e.g., due to schema incompatibility),
/// the container factory will attempt to delete and recreate the database.
/// This is acceptable during development but should be replaced with proper
/// migration handling before production release.
struct CVRtrackerSchema {
    /// All persistent model types managed by SwiftData.
    ///
    /// Add new @Model classes here when extending the data model.
    static var models: [any PersistentModel.Type] {
        [BPReading.self, UserProfile.self, LipidReading.self]
    }

    /// Creates and configures the ModelContainer for the app.
    ///
    /// Attempts to create a persistent store with the current schema.
    /// If iCloud sync is enabled, configures CloudKit for automatic sync.
    /// If creation fails (e.g., due to schema changes), falls back to
    /// deleting the existing store and creating a fresh database.
    ///
    /// - Parameter useiCloud: Whether to enable iCloud sync via CloudKit.
    ///                        Defaults to the user's saved preference.
    /// - Returns: A configured ModelContainer ready for use
    /// - Throws: If the container cannot be created even after reset
    ///
    /// - Warning: The fallback behavior deletes all existing data.
    ///   Implement proper migration before production release.
    static func createContainer(useiCloud: Bool = iCloudSyncManager.shouldUseiCloud) throws -> ModelContainer {
        let schema = Schema(models)

        let config: ModelConfiguration

        if useiCloud {
            // Enable CloudKit sync with automatic container identifier
            // The container ID is derived from the app's bundle identifier
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        } else {
            // Local-only storage (default for privacy)
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If we can't open the store, it may be corrupted or have incompatible schema
            // In development, we can delete and recreate. In production, implement proper migration.
            print("Failed to create ModelContainer: \(error)")
            print("Attempting to reset database...")

            // Find and delete the default store
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                let shmURL = appSupport.appendingPathComponent("default.store-shm")
                let walURL = appSupport.appendingPathComponent("default.store-wal")

                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: shmURL)
                try? FileManager.default.removeItem(at: walURL)
            }

            // Try again with fresh database
            return try ModelContainer(for: schema, configurations: [config])
        }
    }
}
