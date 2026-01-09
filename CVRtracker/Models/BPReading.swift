import Foundation
import SwiftData

@Model
final class BPReading {
    var id: UUID
    var timestamp: Date
    var systolic: Int
    var diastolic: Int

    init(systolic: Int, diastolic: Int, timestamp: Date = Date()) {
        self.id = UUID()
        self.timestamp = timestamp
        self.systolic = systolic
        self.diastolic = diastolic
    }

    // Pulse Pressure = Systolic - Diastolic
    var pulsePressure: Int {
        systolic - diastolic
    }

    // Mean Arterial Pressure = Diastolic + (0.412 * Pulse Pressure)
    var meanArterialPressure: Double {
        Double(diastolic) + (0.412 * Double(pulsePressure))
    }

    // Fractional Pulse Pressure = Pulse Pressure / MAP
    var fractionalPulsePressure: Double {
        guard meanArterialPressure > 0 else { return 0 }
        return Double(pulsePressure) / meanArterialPressure
    }

    // fPP risk category
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

enum FPPCategory: String, CaseIterable {
    case normal = "Normal"
    case elevated = "Elevated"
    case high = "High"

    var description: String {
        switch self {
        case .normal: return "< 0.40 - Good vascular health"
        case .elevated: return "0.40-0.50 - Moderate arterial stiffness"
        case .high: return "> 0.50 - Increased arterial stiffness"
        }
    }
}
