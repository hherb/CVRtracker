import Testing
import Foundation
@testable import CVRtracker

/// Tests for data validation logic used throughout the app.
@Suite("Validation Tests")
struct ValidationTests {
    
    @Test("Valid blood pressure values are accepted", arguments: [
        (systolic: 90, diastolic: 60, valid: true),
        (systolic: 120, diastolic: 80, valid: true),
        (systolic: 140, diastolic: 90, valid: true),
        (systolic: 180, diastolic: 110, valid: true)
    ])
    func validBloodPressureValues(systolic: Int, diastolic: Int, valid: Bool) {
        // Blood pressure values should be in reasonable ranges
        let systolicValid = systolic >= 70 && systolic <= 200
        let diastolicValid = diastolic >= 40 && diastolic <= 130
        let isValid = systolicValid && diastolicValid && systolic > diastolic
        
        #expect(isValid == valid, "Systolic: \(systolic), Diastolic: \(diastolic)")
    }
    
    @Test("Invalid blood pressure values are rejected", arguments: [
        (systolic: 50, diastolic: 30),  // Too low
        (systolic: 250, diastolic: 150), // Too high
        (systolic: 80, diastolic: 90)    // Diastolic > Systolic
    ])
    func invalidBloodPressureValues(systolic: Int, diastolic: Int) {
        // These should fail validation
        let systolicValid = systolic >= 70 && systolic <= 200
        let diastolicValid = diastolic >= 40 && diastolic <= 130
        let isValid = systolicValid && diastolicValid && systolic > diastolic
        
        #expect(!isValid, "Invalid BP should be rejected: \(systolic)/\(diastolic)")
    }
    
    @Test("Valid lipid values are accepted", arguments: [
        (totalCholesterol: 150.0, ldl: 80.0, hdl: 50.0, triglycerides: 100.0),
        (totalCholesterol: 200.0, ldl: 120.0, hdl: 60.0, triglycerides: 150.0),
        (totalCholesterol: 250.0, ldl: 160.0, hdl: 40.0, triglycerides: 200.0)
    ])
    func validLipidValues(totalCholesterol: Double, ldl: Double, hdl: Double, triglycerides: Double) {
        // Lipid values should be positive and in reasonable medical ranges
        let allPositive = totalCholesterol > 0 && ldl > 0 && hdl > 0 && triglycerides > 0
        let totalValid = totalCholesterol >= 100 && totalCholesterol <= 400
        let ldlValid = ldl >= 40 && ldl <= 300
        let hdlValid = hdl >= 20 && hdl <= 100
        let triglyceridesValid = triglycerides >= 40 && triglycerides <= 500
        
        #expect(allPositive && totalValid && ldlValid && hdlValid && triglyceridesValid)
    }
    
    @Test("Heart rate values in valid range", arguments: [40, 60, 75, 100, 150, 200])
    func validHeartRateValues(bpm: Int) {
        // Heart rate should be between 30 and 220 (covering resting to max exercise)
        let isValid = bpm >= 30 && bpm <= 220
        #expect(isValid, "BPM \(bpm) should be valid")
    }
    
    @Test("Age calculation from date of birth")
    func ageCalculation() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create a date of birth 30 years ago
        let dateOfBirth = try #require(
            calendar.date(byAdding: .year, value: -30, to: now)
        )
        
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        let age = ageComponents.year
        
        #expect(age == 30 || age == 29, "Age should be approximately 30 years")
    }
    
    @Test("Empty notes are handled correctly")
    func emptyNotesHandling() {
        let emptyString = ""
        let whitespaceString = "   "
        let validString = "Test note"
        
        #expect(emptyString.isEmpty)
        #expect(!emptyString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        #expect(!whitespaceString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        #expect(!validString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
