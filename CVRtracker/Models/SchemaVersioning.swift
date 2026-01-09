import Foundation
import SwiftData

// Simple schema configuration - all current models
// For production apps with existing users, implement proper VersionedSchema migration

struct CVRtrackerSchema {
    static var models: [any PersistentModel.Type] {
        [BPReading.self, UserProfile.self, LipidReading.self]
    }

    static func createContainer() throws -> ModelContainer {
        let schema = Schema(models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
