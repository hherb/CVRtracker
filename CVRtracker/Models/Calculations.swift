import Foundation

struct CVRiskResult {
    let riskPercent: Double
    let category: RiskCategory

    enum RiskCategory: String {
        case low = "Low"
        case intermediate = "Intermediate"
        case high = "High"

        var description: String {
            switch self {
            case .low: return "Lower than average risk"
            case .intermediate: return "Moderate risk - lifestyle changes recommended"
            case .high: return "Higher risk - consult your healthcare provider"
            }
        }
    }
}

struct Calculations {

    // MARK: - Fractional Pulse Pressure

    /// Calculate fractional pulse pressure from BP readings
    /// - Parameters:
    ///   - systolic: Systolic blood pressure (mmHg)
    ///   - diastolic: Diastolic blood pressure (mmHg)
    /// - Returns: Fractional pulse pressure value
    static func calculateFPP(systolic: Int, diastolic: Int) -> Double {
        let pulsePressure = Double(systolic - diastolic)
        let map = Double(diastolic) + (0.412 * pulsePressure)
        guard map > 0 else { return 0 }
        return pulsePressure / map
    }

    // MARK: - Framingham 10-Year CVD Risk

    /// Calculate 10-year cardiovascular disease risk using Framingham Risk Score
    /// Based on D'Agostino et al. (2008) General cardiovascular risk profile
    static func calculateFramingham10Year(profile: UserProfile, systolicBP: Int) -> CVRiskResult {
        let age = Double(profile.age)
        let totalChol = profile.totalCholesterol
        let hdl = profile.hdlCholesterol
        let sbp = Double(systolicBP)
        let treated = profile.onHypertensionTreatment
        let smoker = profile.isSmoker
        let diabetic = profile.hasDiabetes

        var score: Double = 0

        if profile.sex == .male {
            // Male coefficients
            let lnAge = log(age)
            let lnTotalChol = log(totalChol)
            let lnHDL = log(hdl)
            let lnSBP = log(sbp)

            score = 3.06117 * lnAge
                  + 1.12370 * lnTotalChol
                  - 0.93263 * lnHDL
                  + (treated ? 1.99881 * lnSBP : 1.93303 * lnSBP)
                  + (smoker ? 0.65451 : 0)
                  + (diabetic ? 0.57367 : 0)

            let meanScore = 23.9802
            let baselineSurvival = 0.88936
            let riskPercent = (1 - pow(baselineSurvival, exp(score - meanScore))) * 100
            return CVRiskResult(riskPercent: max(0, min(100, riskPercent)), category: categorize10Year(riskPercent))

        } else {
            // Female coefficients
            let lnAge = log(age)
            let lnTotalChol = log(totalChol)
            let lnHDL = log(hdl)
            let lnSBP = log(sbp)

            score = 2.32888 * lnAge
                  + 1.20904 * lnTotalChol
                  - 0.70833 * lnHDL
                  + (treated ? 2.82263 * lnSBP : 2.76157 * lnSBP)
                  + (smoker ? 0.52873 : 0)
                  + (diabetic ? 0.69154 : 0)

            let meanScore = 26.1931
            let baselineSurvival = 0.95012
            let riskPercent = (1 - pow(baselineSurvival, exp(score - meanScore))) * 100
            return CVRiskResult(riskPercent: max(0, min(100, riskPercent)), category: categorize10Year(riskPercent))
        }
    }

    private static func categorize10Year(_ risk: Double) -> CVRiskResult.RiskCategory {
        if risk < 10 {
            return .low
        } else if risk < 20 {
            return .intermediate
        } else {
            return .high
        }
    }

    // MARK: - Framingham 30-Year CVD Risk

    /// Calculate 30-year cardiovascular disease risk
    /// Based on Pencina et al. (2009) extended Framingham risk functions
    static func calculateFramingham30Year(profile: UserProfile, systolicBP: Int) -> CVRiskResult {
        let age = Double(profile.age)
        let totalChol = profile.totalCholesterol
        let hdl = profile.hdlCholesterol
        let sbp = Double(systolicBP)
        let treated = profile.onHypertensionTreatment
        let smoker = profile.isSmoker
        let diabetic = profile.hasDiabetes

        var score: Double = 0

        if profile.sex == .male {
            // Male 30-year coefficients (simplified model)
            score = 0.0
            score += (age - 20) * 0.04826
            score += (totalChol > 240 ? 0.27168 : (totalChol > 200 ? 0.13579 : 0))
            score += (hdl < 40 ? 0.41415 : (hdl < 50 ? 0.19212 : 0))
            score += (sbp >= 160 ? 0.47179 : (sbp >= 140 ? 0.34821 : (sbp >= 120 ? 0.17892 : 0)))
            score += (treated ? 0.24903 : 0)
            score += (smoker ? 0.62429 : 0)
            score += (diabetic ? 0.66575 : 0)

            let baseRisk = 15.0 // baseline 30-year risk for average male
            let riskPercent = baseRisk * exp(score - 1.0)
            return CVRiskResult(riskPercent: max(0, min(100, riskPercent)), category: categorize30Year(riskPercent))

        } else {
            // Female 30-year coefficients (simplified model)
            score = 0.0
            score += (age - 20) * 0.04177
            score += (totalChol > 240 ? 0.23186 : (totalChol > 200 ? 0.11593 : 0))
            score += (hdl < 40 ? 0.35782 : (hdl < 50 ? 0.16891 : 0))
            score += (sbp >= 160 ? 0.41563 : (sbp >= 140 ? 0.30692 : (sbp >= 120 ? 0.15782 : 0)))
            score += (treated ? 0.21894 : 0)
            score += (smoker ? 0.55167 : 0)
            score += (diabetic ? 0.58923 : 0)

            let baseRisk = 10.0 // baseline 30-year risk for average female
            let riskPercent = baseRisk * exp(score - 0.8)
            return CVRiskResult(riskPercent: max(0, min(100, riskPercent)), category: categorize30Year(riskPercent))
        }
    }

    private static func categorize30Year(_ risk: Double) -> CVRiskResult.RiskCategory {
        if risk < 12 {
            return .low
        } else if risk < 40 {
            return .intermediate
        } else {
            return .high
        }
    }
}
