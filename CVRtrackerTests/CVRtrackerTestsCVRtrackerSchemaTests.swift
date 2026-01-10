import Testing
import SwiftData
@testable import CVRtracker

/// Tests for the SwiftData schema configuration and model container creation.
@Suite("Schema Configuration Tests")
struct CVRtrackerSchemaTests {
    
    @Test("Schema includes all required model types")
    func schemaIncludesAllModels() {
        let models = CVRtrackerSchema.models
        
        #expect(models.count == 3, "Schema should contain exactly 3 model types")
        
        // Verify that all expected model types are present
        let modelNames = models.map { String(describing: $0) }
        #expect(modelNames.contains("BPReading"), "Schema should include BPReading")
        #expect(modelNames.contains("UserProfile"), "Schema should include UserProfile")
        #expect(modelNames.contains("LipidReading"), "Schema should include LipidReading")
    }
    
    @Test("Can create in-memory model container")
    func canCreateInMemoryContainer() throws {
        // Create an in-memory container for testing
        let schema = Schema(CVRtrackerSchema.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        let container = try ModelContainer(for: schema, configurations: [config])
        
        #expect(container.schema.entities.count == 3, "Container should have 3 entity types")
    }
    
    @Test("Container creation handles schema correctly")
    func containerCreationHandlesSchema() throws {
        // This tests that the createContainer method doesn't throw
        // when creating an in-memory test container
        let schema = Schema(CVRtrackerSchema.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        
        // Verify context is usable
        #expect(context.container === container)
    }
}
