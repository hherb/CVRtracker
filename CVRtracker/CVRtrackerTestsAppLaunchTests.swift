import Testing
import SwiftUI
@testable import CVRtracker

/// Tests for app initialization and configuration.
@Suite("App Launch Tests")
struct AppLaunchTests {
    
    @Test("App creates shared model container")
    func appCreatesSharedModelContainer() throws {
        // Create an instance of the app struct
        let app = CVRtrackerApp()
        
        // Verify the container exists and is properly configured
        let container = app.sharedModelContainer
        #expect(container.schema.entities.count > 0, "Container should have entities")
    }
    
    @Test("HealthKitManager can be initialized")
    func healthKitManagerInitialization() {
        let manager = HealthKitManager()
        
        // Verify the manager exists
        #expect(manager != nil, "HealthKitManager should initialize successfully")
    }
    
    @Test("Schema container creation does not throw")
    func schemaContainerCreationDoesNotThrow() throws {
        // This should not throw when creating an in-memory container
        let schema = Schema(CVRtrackerSchema.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        let container = try ModelContainer(for: schema, configurations: [config])
        
        #expect(container != nil)
    }
}
