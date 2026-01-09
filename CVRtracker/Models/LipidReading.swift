import Foundation
import SwiftData

/// A lipid panel reading containing cholesterol and triglyceride measurements.
///
/// Stores a complete lipid panel with total cholesterol, HDL, LDL (optional), and
/// triglycerides (optional). All values are stored internally in mg/dL regardless
/// of user display preferences; conversion happens at display time.
///
/// If LDL is not directly measured, it can be calculated using the Friedewald equation
/// when triglycerides are available and below 400 mg/dL.
@Model
final class LipidReading {
    /// Unique identifier for the reading
    var id: UUID

    /// Date and time when the lipid panel was taken
    var timestamp: Date

    /// Total cholesterol in mg/dL (stored value, regardless of display unit)
    ///
    /// Desirable: < 200 mg/dL, Borderline: 200-239 mg/dL, High: ≥ 240 mg/dL
    var totalCholesterol: Double

    /// HDL ("good") cholesterol in mg/dL (stored value, regardless of display unit)
    ///
    /// Higher is better. Optimal: ≥ 60 mg/dL, Low (risk factor): < 40 mg/dL
    var hdlCholesterol: Double

    /// LDL ("bad") cholesterol in mg/dL, if directly measured
    ///
    /// Optional because LDL can be calculated from other values using
    /// the Friedewald equation if triglycerides are available.
    var ldlCholesterol: Double?

    /// Triglycerides in mg/dL
    ///
    /// Optional measurement. Normal: < 150 mg/dL, High: ≥ 200 mg/dL
    /// Required for Friedewald LDL calculation.
    var triglycerides: Double?

    /// Creates a new lipid reading with the specified values.
    /// - Parameters:
    ///   - totalCholesterol: Total cholesterol in mg/dL
    ///   - hdlCholesterol: HDL cholesterol in mg/dL
    ///   - ldlCholesterol: LDL cholesterol in mg/dL (optional, can be calculated)
    ///   - triglycerides: Triglycerides in mg/dL (optional)
    ///   - timestamp: When the reading was taken (defaults to now)
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

    /// LDL cholesterol, either directly measured or calculated using the Friedewald equation.
    ///
    /// If LDL was directly measured, returns that value. Otherwise, calculates LDL using:
    /// `LDL = Total Cholesterol - HDL - (Triglycerides / 5)`
    ///
    /// - Returns: LDL value in mg/dL, or nil if:
    ///   - LDL was not measured AND triglycerides are unavailable
    ///   - Triglycerides ≥ 400 mg/dL (Friedewald equation is inaccurate at high TG levels)
    var calculatedLDL: Double? {
        if let ldl = ldlCholesterol {
            return ldl
        }
        guard let trig = triglycerides, trig < 400 else {
            return nil // Friedewald not valid for TG >= 400 mg/dL
        }
        return totalCholesterol - hdlCholesterol - (trig / 5.0)
    }

    /// Non-HDL cholesterol: all cholesterol except HDL.
    ///
    /// Calculated as: Total Cholesterol - HDL
    ///
    /// Non-HDL includes LDL, VLDL, and other atherogenic particles.
    /// Some guidelines consider this a better predictor of cardiovascular
    /// risk than LDL alone, especially in patients with high triglycerides.
    var nonHDLCholesterol: Double {
        totalCholesterol - hdlCholesterol
    }

    /// Ratio of total cholesterol to HDL cholesterol.
    ///
    /// A commonly used cardiovascular risk indicator that accounts for
    /// both harmful (LDL) and protective (HDL) cholesterol fractions.
    ///
    /// Categories:
    /// - Optimal: < 3.5
    /// - Borderline: 3.5-5.0
    /// - High risk: > 5.0
    var totalHDLRatio: Double {
        guard hdlCholesterol > 0 else { return 0 }
        return totalCholesterol / hdlCholesterol
    }

    /// Risk category based on the total/HDL cholesterol ratio
    var totalHDLRatioCategory: LipidCategory {
        if totalHDLRatio < 3.5 {
            return .optimal
        } else if totalHDLRatio < 5.0 {
            return .borderline
        } else {
            return .high
        }
    }

    /// Returns total cholesterol converted to the specified display unit.
    /// - Parameter unit: The unit to convert to (mg/dL or mmol/L)
    /// - Returns: Total cholesterol in the specified unit
    func displayTotalCholesterol(unit: CholesterolUnit) -> Double {
        unit.fromMgdL(totalCholesterol)
    }

    /// Returns HDL cholesterol converted to the specified display unit.
    /// - Parameter unit: The unit to convert to (mg/dL or mmol/L)
    /// - Returns: HDL cholesterol in the specified unit
    func displayHDLCholesterol(unit: CholesterolUnit) -> Double {
        unit.fromMgdL(hdlCholesterol)
    }

    /// Returns LDL cholesterol converted to the specified display unit.
    /// - Parameter unit: The unit to convert to (mg/dL or mmol/L)
    /// - Returns: LDL cholesterol in the specified unit, or nil if unavailable
    func displayLDLCholesterol(unit: CholesterolUnit) -> Double? {
        guard let ldl = calculatedLDL else { return nil }
        return unit.fromMgdL(ldl)
    }

    /// Returns triglycerides converted to the specified display unit.
    /// - Parameter unit: The unit to convert to (mg/dL or mmol/L)
    /// - Returns: Triglycerides in the specified unit, or nil if not recorded
    func displayTriglycerides(unit: TriglycerideUnit) -> Double? {
        guard let trig = triglycerides else { return nil }
        return unit.fromMgdL(trig)
    }
}

/// Risk categories for lipid panel values.
///
/// Used primarily for the total/HDL ratio but applicable to other
/// lipid measurements as a general risk classification.
enum LipidCategory: String, CaseIterable {
    /// Optimal range - indicates good cardiovascular health
    case optimal = "Optimal"

    /// Borderline range - lifestyle modifications recommended
    case borderline = "Borderline"

    /// High range - medical consultation recommended
    case high = "High"

    /// Human-readable description with actionable guidance
    var description: String {
        switch self {
        case .optimal: return "Good cardiovascular health indicator"
        case .borderline: return "Consider lifestyle modifications"
        case .high: return "Consult your healthcare provider"
        }
    }
}
