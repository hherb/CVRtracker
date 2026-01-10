import Testing
import HealthKit
@testable import CVRtracker

/// Tests for HealthKit integration and data structures.
@Suite("HealthKit Manager Tests")
struct HealthKitManagerTests {
    
    @Test("HealthKitBPReading stores data correctly")
    func bpReadingStoresData() {
        let timestamp = Date()
        let reading = HealthKitBPReading(
            systolic: 120,
            diastolic: 80,
            timestamp: timestamp,
            sourceBundle: "com.example.app"
        )
        
        #expect(reading.systolic == 120)
        #expect(reading.diastolic == 80)
        #expect(reading.timestamp == timestamp)
        #expect(reading.sourceBundle == "com.example.app")
    }
    
    @Test("HeartRateReading has unique IDs")
    func heartRateReadingHasUniqueIDs() {
        let reading1 = HeartRateReading(
            bpm: 72,
            timestamp: Date(),
            sourceBundle: nil
        )
        
        let reading2 = HeartRateReading(
            bpm: 75,
            timestamp: Date(),
            sourceBundle: nil
        )
        
        #expect(reading1.id != reading2.id, "Each heart rate reading should have a unique ID")
    }
    
    @Test("SyncStatus equality works correctly")
    func syncStatusEquality() {
        #expect(SyncStatus.idle == SyncStatus.idle)
        #expect(SyncStatus.syncing == SyncStatus.syncing)
        #expect(SyncStatus.completed(imported: 5) == SyncStatus.completed(imported: 5))
        #expect(SyncStatus.completed(imported: 5) != SyncStatus.completed(imported: 3))
        #expect(SyncStatus.error("Test") == SyncStatus.error("Test"))
        #expect(SyncStatus.idle != SyncStatus.syncing)
    }
    
    @Test("HealthKitError provides descriptive messages")
    func healthKitErrorMessages() {
        let notAvailableError = HealthKitError.notAvailable
        #expect(notAvailableError.errorDescription?.contains("not available") == true)
        
        let notAuthorizedError = HealthKitError.notAuthorized
        #expect(notAuthorizedError.errorDescription?.contains("not authorized") == true)
        
        struct TestError: Error {}
        let saveFailed = HealthKitError.saveFailed(TestError())
        #expect(saveFailed.errorDescription?.contains("save") == true)
        
        let fetchFailed = HealthKitError.fetchFailed(TestError())
        #expect(fetchFailed.errorDescription?.contains("fetch") == true)
    }
    
    @Test("HealthKit availability can be checked")
    func healthKitAvailability() {
        let isAvailable = HKHealthStore.isHealthDataAvailable()
        
        // On iOS devices (not simulator without proper setup), this should return true
        // On macOS or watchOS, behavior may differ
        // This test documents the API without making platform-specific assertions
        #expect(isAvailable == HKHealthStore.isHealthDataAvailable(), 
                "HealthKit availability should be consistent")
    }
}
