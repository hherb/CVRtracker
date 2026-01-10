import Foundation
import SwiftData
import SwiftUI

/// A single blood pressure reading with associated cardiovascular metrics.
///
/// Blood pressure readings consist of systolic (peak) and diastolic (resting) pressure values.
/// This model automatically calculates derived metrics including pulse pressure, mean arterial
/// pressure (MAP), and fractional pulse pressure (fPP) - a marker of arterial stiffness.
@Model
final class BPReading {
    /// Unique identifier for the reading
    var id: UUID

    /// Date and time when the reading was taken
    var timestamp: Date

    /// Systolic blood pressure in mmHg (the "top number")
    ///
    /// Represents the peak pressure in arteries when the heart muscle contracts.
    /// Normal: < 120 mmHg, Elevated: 120-129, High: ≥ 130
    var systolic: Int

    /// Diastolic blood pressure in mmHg (the "bottom number")
    ///
    /// Represents the pressure in arteries when the heart rests between beats.
    /// Normal: < 80 mmHg, High: ≥ 80
    var diastolic: Int

    /// Creates a new blood pressure reading.
    /// - Parameters:
    ///   - systolic: Systolic pressure in mmHg
    ///   - diastolic: Diastolic pressure in mmHg
    ///   - timestamp: When the reading was taken (defaults to now)
    init(systolic: Int, diastolic: Int, timestamp: Date = Date()) {
        self.id = UUID()
        self.timestamp = timestamp
        self.systolic = systolic
        self.diastolic = diastolic
    }

    /// Pulse pressure: the difference between systolic and diastolic pressure.
    ///
    /// Normal range is 40-60 mmHg. Wide pulse pressure (> 60) may indicate
    /// arterial stiffness, while narrow pulse pressure (< 25) may suggest
    /// poor cardiac output.
    var pulsePressure: Int {
        systolic - diastolic
    }

    /// Mean Arterial Pressure (MAP): the average pressure during one cardiac cycle.
    ///
    /// Calculated using the formula: MAP = Diastolic + (0.412 × Pulse Pressure)
    /// The 0.412 coefficient accounts for the fact that diastole lasts longer than systole.
    /// Normal MAP is typically 70-100 mmHg.
    var meanArterialPressure: Double {
        Double(diastolic) + (0.412 * Double(pulsePressure))
    }

    /// Fractional Pulse Pressure (fPP): a non-invasive marker of arterial stiffness.
    ///
    /// Calculated as: fPP = Pulse Pressure / Mean Arterial Pressure
    ///
    /// Categories:
    /// - Normal (< 0.40): Good vascular health
    /// - Elevated (0.40-0.50): Moderate arterial stiffness
    /// - High (> 0.50): Significant arterial stiffness
    ///
    /// Higher fPP values indicate stiffer arteries, which is associated with
    /// increased cardiovascular risk and vascular aging.
    var fractionalPulsePressure: Double {
        guard meanArterialPressure > 0 else { return 0 }
        return Double(pulsePressure) / meanArterialPressure
    }

    /// The risk category based on fractional pulse pressure value.
    var fppCategory: FPPCategory {
        if fractionalPulsePressure < 0.4 {
            return .normal
        } else if fractionalPulsePressure < 0.5 {
            return .elevated
        } else {
            return .high
        }
    }
}

/// Risk categories for fractional pulse pressure (fPP).
///
/// fPP is a proxy measure for arterial stiffness. Higher values indicate
/// stiffer arteries, which is associated with vascular aging and increased
/// cardiovascular risk.
enum FPPCategory: String, CaseIterable {
    /// fPP < 0.40 - indicates good vascular health and arterial elasticity
    case normal = "Normal"

    /// fPP 0.40-0.50 - indicates moderate arterial stiffness
    case elevated = "Elevated"

    /// fPP > 0.50 - indicates significant arterial stiffness
    case high = "High"

    /// Human-readable description of the category with value ranges
    var description: String {
        switch self {
        case .normal: return "< 0.40 - Good vascular health"
        case .elevated: return "0.40-0.50 - Moderate arterial stiffness"
        case .high: return "> 0.50 - Increased arterial stiffness"
        }
    }
}

/// Blood pressure category based on AHA/ACC guidelines.
///
/// Classification follows the 2017 ACC/AHA Guideline for High Blood Pressure.
/// The most severe applicable category is used when systolic and diastolic
/// fall into different categories.
enum BPCategory: String, CaseIterable {
    /// Both systolic < 120 AND diastolic < 80 mmHg
    case normal = "Normal"

    /// Systolic 120-129 AND diastolic < 80 mmHg
    case elevated = "Elevated"

    /// Systolic 130-139 OR diastolic 80-89 mmHg
    case hypertensionStage1 = "High (Stage 1)"

    /// Systolic 140-179 OR diastolic 90-119 mmHg
    case hypertensionStage2 = "High (Stage 2)"

    /// Systolic ≥ 180 OR diastolic ≥ 120 mmHg - requires immediate attention
    case hypertensiveCrisis = "Hypertensive Crisis"

    /// Human-readable description with guidance
    var description: String {
        switch self {
        case .normal:
            return "Blood pressure is in the healthy range."
        case .elevated:
            return "Blood pressure is slightly elevated. Lifestyle changes recommended."
        case .hypertensionStage1:
            return "High blood pressure (Stage 1). Consult your healthcare provider."
        case .hypertensionStage2:
            return "High blood pressure (Stage 2). Medical attention recommended."
        case .hypertensiveCrisis:
            return "Blood pressure is critically high. Seek immediate medical attention if you have symptoms."
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .normal: return .green
        case .elevated: return .yellow
        case .hypertensionStage1: return .orange
        case .hypertensionStage2: return .red
        case .hypertensiveCrisis: return Color(red: 0.5, green: 0, blue: 0) // Dark red
        }
    }

    /// Whether this reading requires urgent attention
    var isUrgent: Bool {
        self == .hypertensiveCrisis
    }

    /// Whether this BP category should override fPP interpretation
    /// (BP is the primary concern, fPP is secondary)
    var overridesFPP: Bool {
        self == .hypertensiveCrisis || self == .hypertensionStage2
    }
}

// MARK: - BPReading BP Category Extension

extension BPReading {
    /// Blood pressure category based on AHA/ACC guidelines.
    ///
    /// Uses the higher category when systolic and diastolic fall into different categories.
    var bpCategory: BPCategory {
        if systolic >= 180 || diastolic >= 120 {
            return .hypertensiveCrisis
        } else if systolic >= 140 || diastolic >= 90 {
            return .hypertensionStage2
        } else if systolic >= 130 || diastolic >= 80 {
            return .hypertensionStage1
        } else if systolic >= 120 {
            return .elevated
        } else {
            return .normal
        }
    }

    /// Contextual interpretation of fPP considering BP category.
    ///
    /// When blood pressure is dangerously high, the fPP interpretation is de-emphasized
    /// because immediate BP control is more important than arterial stiffness assessment.
    var fppInterpretation: String {
        switch bpCategory {
        case .hypertensiveCrisis:
            return "Blood pressure is critically elevated. Arterial stiffness assessment is secondary to immediate BP control."
        case .hypertensionStage2:
            return "High blood pressure is your primary cardiovascular concern. Focus on BP management first."
        case .hypertensionStage1:
            return fppCategory.description + " Note: Also address your elevated blood pressure."
        case .elevated:
            return fppCategory.description + " Your blood pressure is slightly elevated."
        case .normal:
            return fppCategory.description
        }
    }
}
