import Foundation
import SwiftData

enum Sex: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

enum CholesterolUnit: String, Codable, CaseIterable {
    case mgdL = "mg/dL"
    case mmolL = "mmol/L"

    var conversionFactor: Double {
        switch self {
        case .mgdL: return 1.0
        case .mmolL: return 38.67 // 1 mmol/L = 38.67 mg/dL for cholesterol
        }
    }

    func toMgdL(_ value: Double) -> Double {
        return value * conversionFactor
    }

    func fromMgdL(_ value: Double) -> Double {
        return value / conversionFactor
    }
}

enum TriglycerideUnit: String, Codable, CaseIterable {
    case mgdL = "mg/dL"
    case mmolL = "mmol/L"

    var conversionFactor: Double {
        switch self {
        case .mgdL: return 1.0
        case .mmolL: return 88.57 // 1 mmol/L = 88.57 mg/dL for triglycerides
        }
    }

    func toMgdL(_ value: Double) -> Double {
        return value * conversionFactor
    }

    func fromMgdL(_ value: Double) -> Double {
        return value / conversionFactor
    }
}

@Model
final class UserProfile {
    var id: UUID
    var age: Int
    var sex: Sex
    var totalCholesterol: Double  // Always stored in mg/dL
    var hdlCholesterol: Double    // Always stored in mg/dL
    var onHypertensionTreatment: Bool
    var isSmoker: Bool
    var hasDiabetes: Bool

    // Unit preferences - optional with defaults for migration compatibility
    var cholesterolUnitRaw: String?
    var triglycerideUnitRaw: String?

    var cholesterolUnit: CholesterolUnit {
        get { CholesterolUnit(rawValue: cholesterolUnitRaw ?? "mg/dL") ?? .mgdL }
        set { cholesterolUnitRaw = newValue.rawValue }
    }

    var triglycerideUnit: TriglycerideUnit {
        get { TriglycerideUnit(rawValue: triglycerideUnitRaw ?? "mg/dL") ?? .mgdL }
        set { triglycerideUnitRaw = newValue.rawValue }
    }

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

    var isComplete: Bool {
        age >= 30 && age <= 79 &&
        totalCholesterol > 0 &&
        hdlCholesterol > 0
    }

    // Get cholesterol values in user's preferred unit
    func displayTotalCholesterol() -> Double {
        cholesterolUnit.fromMgdL(totalCholesterol)
    }

    func displayHDLCholesterol() -> Double {
        cholesterolUnit.fromMgdL(hdlCholesterol)
    }

    // Set cholesterol values from user's preferred unit
    func setTotalCholesterol(displayValue: Double) {
        totalCholesterol = cholesterolUnit.toMgdL(displayValue)
    }

    func setHDLCholesterol(displayValue: Double) {
        hdlCholesterol = cholesterolUnit.toMgdL(displayValue)
    }
}
