import Foundation
import SwiftData

/// Biological sex for cardiovascular risk calculations.
///
/// The Framingham Risk Score uses different coefficients for males and females
/// due to inherent differences in cardiovascular risk profiles between sexes.
enum Sex: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

/// Units for cholesterol measurements.
///
/// Cholesterol can be measured in mg/dL (milligrams per deciliter, common in US)
/// or mmol/L (millimoles per liter, common internationally).
/// Internal storage always uses mg/dL; conversion happens at display time.
enum CholesterolUnit: String, Codable, CaseIterable {
    /// Milligrams per deciliter (US standard)
    case mgdL = "mg/dL"

    /// Millimoles per liter (international standard)
    case mmolL = "mmol/L"

    /// Conversion factor from this unit to mg/dL.
    ///
    /// For cholesterol: 1 mmol/L = 38.67 mg/dL
    var conversionFactor: Double {
        switch self {
        case .mgdL: return 1.0
        case .mmolL: return 38.67
        }
    }

    /// Converts a value from this unit to mg/dL for storage.
    /// - Parameter value: The value in the current unit
    /// - Returns: The value converted to mg/dL
    func toMgdL(_ value: Double) -> Double {
        return value * conversionFactor
    }

    /// Converts a value from mg/dL to this unit for display.
    /// - Parameter value: The value in mg/dL
    /// - Returns: The value converted to the current unit
    func fromMgdL(_ value: Double) -> Double {
        return value / conversionFactor
    }
}

/// Units for triglyceride measurements.
///
/// Triglycerides use a different conversion factor than cholesterol
/// due to their different molecular weight.
enum TriglycerideUnit: String, Codable, CaseIterable {
    /// Milligrams per deciliter (US standard)
    case mgdL = "mg/dL"

    /// Millimoles per liter (international standard)
    case mmolL = "mmol/L"

    /// Conversion factor from this unit to mg/dL.
    ///
    /// For triglycerides: 1 mmol/L = 88.57 mg/dL
    var conversionFactor: Double {
        switch self {
        case .mgdL: return 1.0
        case .mmolL: return 88.57
        }
    }

    /// Converts a value from this unit to mg/dL for storage.
    /// - Parameter value: The value in the current unit
    /// - Returns: The value converted to mg/dL
    func toMgdL(_ value: Double) -> Double {
        return value * conversionFactor
    }

    /// Converts a value from mg/dL to this unit for display.
    /// - Parameter value: The value in mg/dL
    /// - Returns: The value converted to the current unit
    func fromMgdL(_ value: Double) -> Double {
        return value / conversionFactor
    }
}

/// User health profile containing demographics and risk factors for cardiovascular risk calculation.
///
/// This model stores all the information needed to calculate the Framingham Risk Score,
/// including age, sex, cholesterol levels, and modifiable risk factors like smoking
/// and diabetes status.
///
/// - Note: Cholesterol values are always stored internally in mg/dL regardless of
///   the user's display preference. Conversion happens at display/input time.
@Model
final class UserProfile {
    /// Unique identifier for the profile
    var id: UUID

    /// User's age in years (valid range for Framingham: 30-79)
    var age: Int

    /// Biological sex (affects risk calculation coefficients)
    var sex: Sex

    /// Total cholesterol in mg/dL (stored value, regardless of display unit)
    var totalCholesterol: Double

    /// HDL ("good") cholesterol in mg/dL (stored value, regardless of display unit)
    var hdlCholesterol: Double

    /// Whether the user is currently on blood pressure medication
    ///
    /// This affects risk calculation because treated hypertension indicates
    /// underlying cardiovascular risk even when BP is controlled.
    var onHypertensionTreatment: Bool

    /// Whether the user currently smokes
    ///
    /// Smoking is a major modifiable risk factor for cardiovascular disease.
    var isSmoker: Bool

    /// Whether the user has diabetes
    ///
    /// Diabetes is considered a "coronary heart disease equivalent" and
    /// significantly increases cardiovascular risk.
    var hasDiabetes: Bool

    /// Raw string storage for cholesterol unit preference (for SwiftData compatibility)
    var cholesterolUnitRaw: String?

    /// Raw string storage for triglyceride unit preference (for SwiftData compatibility)
    var triglycerideUnitRaw: String?

    /// Whether HealthKit integration is enabled (optional for migration compatibility)
    var healthKitEnabledRaw: Bool?

    /// User's preferred unit for displaying cholesterol values.
    ///
    /// Stored as optional raw string for migration compatibility.
    /// Defaults to mg/dL if not set.
    var cholesterolUnit: CholesterolUnit {
        get { CholesterolUnit(rawValue: cholesterolUnitRaw ?? "mg/dL") ?? .mgdL }
        set { cholesterolUnitRaw = newValue.rawValue }
    }

    /// User's preferred unit for displaying triglyceride values.
    ///
    /// Stored as optional raw string for migration compatibility.
    /// Defaults to mg/dL if not set.
    var triglycerideUnit: TriglycerideUnit {
        get { TriglycerideUnit(rawValue: triglycerideUnitRaw ?? "mg/dL") ?? .mgdL }
        set { triglycerideUnitRaw = newValue.rawValue }
    }

    /// Whether to sync with Apple Health. Defaults to false.
    var healthKitEnabled: Bool {
        get { healthKitEnabledRaw ?? false }
        set { healthKitEnabledRaw = newValue }
    }

    /// Creates a new user profile with the specified health information.
    /// - Parameters:
    ///   - age: Age in years (30-79 for valid Framingham calculation)
    ///   - sex: Biological sex
    ///   - totalCholesterol: Total cholesterol in mg/dL
    ///   - hdlCholesterol: HDL cholesterol in mg/dL
    ///   - onHypertensionTreatment: Whether taking BP medication
    ///   - isSmoker: Current smoking status
    ///   - hasDiabetes: Diabetes status
    ///   - cholesterolUnit: Preferred display unit for cholesterol
    ///   - triglycerideUnit: Preferred display unit for triglycerides
    init(
        age: Int = 50,
        sex: Sex = .male,
        totalCholesterol: Double = 200,
        hdlCholesterol: Double = 50,
        onHypertensionTreatment: Bool = false,
        isSmoker: Bool = false,
        hasDiabetes: Bool = false,
        cholesterolUnit: CholesterolUnit = .mgdL,
        triglycerideUnit: TriglycerideUnit = .mgdL
    ) {
        self.id = UUID()
        self.age = age
        self.sex = sex
        self.totalCholesterol = totalCholesterol
        self.hdlCholesterol = hdlCholesterol
        self.onHypertensionTreatment = onHypertensionTreatment
        self.isSmoker = isSmoker
        self.hasDiabetes = hasDiabetes
        self.cholesterolUnitRaw = cholesterolUnit.rawValue
        self.triglycerideUnitRaw = triglycerideUnit.rawValue
    }

    /// Whether the profile has all required data for risk calculation.
    ///
    /// Requires age within Framingham valid range (30-79) and positive cholesterol values.
    var isComplete: Bool {
        age >= 30 && age <= 79 &&
        totalCholesterol > 0 &&
        hdlCholesterol > 0
    }

    /// Returns total cholesterol converted to the user's preferred display unit.
    /// - Returns: Total cholesterol in the user's preferred unit
    func displayTotalCholesterol() -> Double {
        cholesterolUnit.fromMgdL(totalCholesterol)
    }

    /// Returns HDL cholesterol converted to the user's preferred display unit.
    /// - Returns: HDL cholesterol in the user's preferred unit
    func displayHDLCholesterol() -> Double {
        cholesterolUnit.fromMgdL(hdlCholesterol)
    }

    /// Sets total cholesterol from a value in the user's preferred display unit.
    /// - Parameter displayValue: The value in the user's preferred unit
    func setTotalCholesterol(displayValue: Double) {
        totalCholesterol = cholesterolUnit.toMgdL(displayValue)
    }

    /// Sets HDL cholesterol from a value in the user's preferred display unit.
    /// - Parameter displayValue: The value in the user's preferred unit
    func setHDLCholesterol(displayValue: Double) {
        hdlCholesterol = cholesterolUnit.toMgdL(displayValue)
    }
}
