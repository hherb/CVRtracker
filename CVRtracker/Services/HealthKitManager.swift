import Foundation
import HealthKit
import SwiftData
import SwiftUI

/// Status of HealthKit sync operations
enum SyncStatus: Equatable {
    case idle
    case syncing
    case completed(imported: Int)
    case error(String)
}

/// A blood pressure reading from HealthKit
struct HealthKitBPReading {
    let systolic: Int
    let diastolic: Int
    let timestamp: Date
    let sourceBundle: String?
}

/// A heart rate reading from HealthKit
struct HeartRateReading: Identifiable {
    let id = UUID()
    let bpm: Int
    let timestamp: Date
    let sourceBundle: String?
}

/// Errors that can occur during HealthKit operations
enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case saveFailed(Error)
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .saveFailed(let error):
            return "Failed to save to HealthKit: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch from HealthKit: \(error.localizedDescription)"
        }
    }
}

/// Manages all HealthKit operations for bidirectional blood pressure sync and heart rate import.
@MainActor
final class HealthKitManager: ObservableObject {

    // MARK: - Published State

    /// Whether HealthKit is available on this device
    @Published private(set) var isAvailable: Bool = false

    /// Whether the user has authorized HealthKit write access
    @Published private(set) var isAuthorized: Bool = false

    /// Current sync status for UI feedback
    @Published private(set) var syncStatus: SyncStatus = .idle

    /// Latest heart rate from HealthKit
    @Published private(set) var latestHeartRate: HeartRateReading?

    // MARK: - Private Properties

    private let healthStore: HKHealthStore?

    // HealthKit types - lazy to avoid initialization on simulator where BP types crash
    private lazy var bloodPressureSystolicType = HKQuantityType(.bloodPressureSystolic)
    private lazy var bloodPressureDiastolicType = HKQuantityType(.bloodPressureDiastolic)
    private lazy var bloodPressureCorrelationType = HKCorrelationType(.bloodPressure)
    private lazy var heartRateType = HKQuantityType(.heartRate)

    /// Types we want to read from HealthKit
    /// Note: We request the individual quantity types, not the correlation type,
    /// as requesting HKCorrelationType for BP can cause authorization issues
    private var readTypes: Set<HKObjectType> {
        [bloodPressureSystolicType, bloodPressureDiastolicType, heartRateType]
    }

    /// Types we want to write to HealthKit
    private var writeTypes: Set<HKSampleType> {
        [bloodPressureSystolicType, bloodPressureDiastolicType]
    }

    // MARK: - Initialization

    init() {
        // On simulator, HealthKit reports as available but blood pressure types
        // throw NSInvalidArgumentException when accessed. Disable entirely on simulator.
        #if targetEnvironment(simulator)
        self.healthStore = nil
        self.isAvailable = false
        #else
        // Check basic availability on real devices
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            self.isAvailable = true
        } else {
            self.healthStore = nil
            self.isAvailable = false
        }
        #endif
    }

    // MARK: - Authorization

    /// Requests HealthKit authorization.
    /// - Returns: true if the authorization request was presented successfully
    func requestAuthorization() async -> Bool {
        guard let healthStore = healthStore, isAvailable else {
            return false
        }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await checkAuthorizationStatus()
            return true
        } catch {
            print("HealthKit authorization error: \(error)")
            // If authorization fails (e.g., on simulator for restricted types),
            // mark as unavailable to hide UI
            isAvailable = false
            return false
        }
    }

    /// Checks current authorization status for write types
    func checkAuthorizationStatus() async {
        guard let healthStore = healthStore else {
            isAuthorized = false
            return
        }

        let systolicStatus = healthStore.authorizationStatus(for: bloodPressureSystolicType)
        let diastolicStatus = healthStore.authorizationStatus(for: bloodPressureDiastolicType)
        isAuthorized = (systolicStatus == .sharingAuthorized && diastolicStatus == .sharingAuthorized)
    }

    // MARK: - Blood Pressure Export

    /// Saves a blood pressure reading to HealthKit
    func saveBPReading(systolic: Int, diastolic: Int, timestamp: Date) async throws {
        guard let healthStore = healthStore, isAvailable else {
            throw HealthKitError.notAvailable
        }

        let systolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(systolic))
        let diastolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(diastolic))

        let systolicSample = HKQuantitySample(
            type: bloodPressureSystolicType,
            quantity: systolicQuantity,
            start: timestamp,
            end: timestamp
        )

        let diastolicSample = HKQuantitySample(
            type: bloodPressureDiastolicType,
            quantity: diastolicQuantity,
            start: timestamp,
            end: timestamp
        )

        let bloodPressure = HKCorrelation(
            type: bloodPressureCorrelationType,
            start: timestamp,
            end: timestamp,
            objects: [systolicSample, diastolicSample]
        )

        do {
            try await healthStore.save(bloodPressure)
        } catch {
            throw HealthKitError.saveFailed(error)
        }
    }

    // MARK: - Blood Pressure Import

    /// Fetches BP readings from HealthKit since the given date
    func fetchBPReadings(since startDate: Date) async throws -> [HealthKitBPReading] {
        guard let healthStore = healthStore, isAvailable else {
            throw HealthKitError.notAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bloodPressureCorrelationType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }

                if let error = error {
                    continuation.resume(throwing: HealthKitError.fetchFailed(error))
                    return
                }

                let readings = (samples as? [HKCorrelation])?.compactMap { correlation -> HealthKitBPReading? in
                    guard let systolicSample = correlation.objects(for: self.bloodPressureSystolicType).first as? HKQuantitySample,
                          let diastolicSample = correlation.objects(for: self.bloodPressureDiastolicType).first as? HKQuantitySample else {
                        return nil
                    }

                    let systolic = Int(systolicSample.quantity.doubleValue(for: .millimeterOfMercury()))
                    let diastolic = Int(diastolicSample.quantity.doubleValue(for: .millimeterOfMercury()))

                    return HealthKitBPReading(
                        systolic: systolic,
                        diastolic: diastolic,
                        timestamp: correlation.startDate,
                        sourceBundle: correlation.sourceRevision.source.bundleIdentifier
                    )
                } ?? []

                continuation.resume(returning: readings)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Heart Rate Import

    /// Fetches the most recent heart rate readings
    func fetchHeartRateReadings(limit: Int = 10) async throws -> [HeartRateReading] {
        guard let healthStore = healthStore, isAvailable else {
            throw HealthKitError.notAvailable
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.fetchFailed(error))
                    return
                }

                let readings = (samples as? [HKQuantitySample])?.map { sample in
                    HeartRateReading(
                        bpm: Int(sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))),
                        timestamp: sample.startDate,
                        sourceBundle: sample.sourceRevision.source.bundleIdentifier
                    )
                } ?? []

                continuation.resume(returning: readings)
            }

            healthStore.execute(query)
        }
    }

    /// Updates the latest heart rate
    func refreshLatestHeartRate() async {
        do {
            let readings = try await fetchHeartRateReadings(limit: 1)
            latestHeartRate = readings.first
        } catch {
            print("Failed to fetch heart rate: \(error)")
        }
    }

    // MARK: - Sync Operations

    /// Performs a full sync: import from HealthKit, avoiding duplicates
    func syncBPReadings(with modelContext: ModelContext) async {
        guard isAvailable else { return }

        syncStatus = .syncing

        do {
            // Fetch existing readings from SwiftData
            let descriptor = FetchDescriptor<BPReading>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let existingReadings = try modelContext.fetch(descriptor)
            let existingTimestamps = Set(existingReadings.map { $0.timestamp.timeIntervalSince1970 })

            // Fetch from HealthKit (last 1 year)
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            let healthKitReadings = try await fetchBPReadings(since: oneYearAgo)

            // Import non-duplicate readings (skip readings from our own app)
            var importedCount = 0
            let ourBundleId = Bundle.main.bundleIdentifier

            for hkReading in healthKitReadings {
                // Skip if from our own app
                if hkReading.sourceBundle == ourBundleId {
                    continue
                }

                // Duplicate detection: check if timestamp exists within 1 minute tolerance
                let timestamp = hkReading.timestamp.timeIntervalSince1970
                let isDuplicate = existingTimestamps.contains { existing in
                    abs(existing - timestamp) < 60
                }

                if !isDuplicate {
                    let newReading = BPReading(
                        systolic: hkReading.systolic,
                        diastolic: hkReading.diastolic,
                        timestamp: hkReading.timestamp
                    )
                    modelContext.insert(newReading)
                    importedCount += 1
                }
            }

            if importedCount > 0 {
                try modelContext.save()
            }

            syncStatus = .completed(imported: importedCount)

            // Refresh heart rate
            await refreshLatestHeartRate()

        } catch {
            print("Sync error: \(error)")
            syncStatus = .error(error.localizedDescription)
        }
    }

    /// Resets sync status to idle
    func resetSyncStatus() {
        syncStatus = .idle
    }
}
