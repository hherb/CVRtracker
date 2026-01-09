import Foundation
import SwiftData

@Model
final class LipidReading {
    var id: UUID
    var timestamp: Date

    // All values stored in mg/dL
    var totalCholesterol: Double
    var hdlCholesterol: Double
    var ldlCholesterol: Double?
    var triglycerides: Double?

    init(
        totalCholesterol: Double,
        hdlCholesterol: Double,
        ldlCholesterol: Double? = nil,
        triglycerides: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.totalCholesterol = totalCholesterol
        self.hdlCholesterol = hdlCholesterol
        self.ldlCholesterol = ldlCholesterol
        self.triglycerides = triglycerides
    }

    // Calculated LDL using Friedewald equation if not directly measured
    // LDL = Total Cholesterol - HDL - (Triglycerides / 5)
    var calculatedLDL: Double? {
        if let ldl = ldlCholesterol {
            return ldl
        }
        guard let trig = triglycerides, trig < 400 else {
            return nil // Friedewald not valid for TG >= 400 mg/dL
        }
        return totalCholesterol - hdlCholesterol - (trig / 5.0)
    }

    // Non-HDL Cholesterol = Total - HDL
    var nonHDLCholesterol: Double {
        totalCholesterol - hdlCholesterol
    }

    // Total/HDL Ratio
    var totalHDLRatio: Double {
        guard hdlCholesterol > 0 else { return 0 }
        return totalCholesterol / hdlCholesterol
    }

    var totalHDLRatioCategory: LipidCategory {
        if totalHDLRatio < 3.5 {
            return .optimal
        } else if totalHDLRatio < 5.0 {
            return .borderline
        } else {
            return .high
        }
    }

    // Display values in specified unit
    func displayTotalCholesterol(unit: CholesterolUnit) -> Double {
        unit.fromMgdL(totalCholesterol)
    }

    func displayHDLCholesterol(unit: CholesterolUnit) -> Double {
        unit.fromMgdL(hdlCholesterol)
    }

    func displayLDLCholesterol(unit: CholesterolUnit) -> Double? {
        guard let ldl = calculatedLDL else { return nil }
        return unit.fromMgdL(ldl)
    }

    func displayTriglycerides(unit: TriglycerideUnit) -> Double? {
        guard let trig = triglycerides else { return nil }
        return unit.fromMgdL(trig)
    }
}

enum LipidCategory: String, CaseIterable {
    case optimal = "Optimal"
    case borderline = "Borderline"
    case high = "High"

    var description: String {
        switch self {
        case .optimal: return "Good cardiovascular health indicator"
        case .borderline: return "Consider lifestyle modifications"
        case .high: return "Consult your healthcare provider"
        }
    }
}
