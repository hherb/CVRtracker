import Foundation
import SwiftData

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
