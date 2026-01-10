import Testing
import SwiftData
import Foundation
@testable import CVRtracker

/// Tests for SwiftData model objects.
@Suite("Model Tests", .serialized)
struct ModelTests {
    
    // Helper to create a test model container
    func createTestContainer() throws -> ModelContainer {
        let schema = Schema(CVRtrackerSchema.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
    
    @Test("Can create and persist BPReading")
    func createAndPersistBPReading() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let reading = BPReading(
            systolic: 120,
            diastolic: 80,
            timestamp: Date(),
            notes: "Test reading"
        )
        
        context.insert(reading)
        try context.save()
        
        // Fetch the reading back
        let descriptor = FetchDescriptor<BPReading>()
        let readings = try context.fetch(descriptor)
        
        #expect(readings.count == 1)
        #expect(readings.first?.systolic == 120)
        #expect(readings.first?.diastolic == 80)
        #expect(readings.first?.notes == "Test reading")
    }
    
    @Test("Can create and persist UserProfile")
    func createAndPersistUserProfile() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let profile = UserProfile(
            dateOfBirth: Date(),
            biologicalSex: .male
        )
        
        context.insert(profile)
        try context.save()
        
        // Fetch the profile back
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(descriptor)
        
        #expect(profiles.count == 1)
        #expect(profiles.first != nil)
    }
    
    @Test("Can create and persist LipidReading")
    func createAndPersistLipidReading() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let reading = LipidReading(
            totalCholesterol: 200.0,
            ldl: 100.0,
            hdl: 60.0,
            triglycerides: 150.0,
            timestamp: Date()
        )
        
        context.insert(reading)
        try context.save()
        
        // Fetch the reading back
        let descriptor = FetchDescriptor<LipidReading>()
        let readings = try context.fetch(descriptor)
        
        #expect(readings.count == 1)
        #expect(readings.first?.totalCholesterol == 200.0)
        #expect(readings.first?.ldl == 100.0)
        #expect(readings.first?.hdl == 60.0)
        #expect(readings.first?.triglycerides == 150.0)
    }
    
    @Test("Can query BPReadings by date range")
    func queryBPReadingsByDateRange() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        // Create readings at different times
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        context.insert(BPReading(systolic: 120, diastolic: 80, timestamp: now))
        context.insert(BPReading(systolic: 125, diastolic: 82, timestamp: yesterday))
        context.insert(BPReading(systolic: 118, diastolic: 78, timestamp: lastWeek))
        
        try context.save()
        
        // Query for readings from the last 2 days
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let predicate = #Predicate<BPReading> { reading in
            reading.timestamp >= twoDaysAgo
        }
        
        var descriptor = FetchDescriptor<BPReading>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        
        let recentReadings = try context.fetch(descriptor)
        
        #expect(recentReadings.count == 2, "Should find 2 readings from the last 2 days")
    }
    
    @Test("Can delete model objects")
    func deleteModelObjects() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let reading = BPReading(systolic: 120, diastolic: 80, timestamp: Date())
        context.insert(reading)
        try context.save()
        
        // Verify it exists
        var descriptor = FetchDescriptor<BPReading>()
        var readings = try context.fetch(descriptor)
        #expect(readings.count == 1)
        
        // Delete it
        context.delete(reading)
        try context.save()
        
        // Verify it's gone
        readings = try context.fetch(descriptor)
        #expect(readings.isEmpty, "Reading should be deleted")
    }
}
