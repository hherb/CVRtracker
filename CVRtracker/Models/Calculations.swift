import Foundation

/// Result of a cardiovascular risk calculation.
///
/// Contains both the raw risk percentage and a categorical interpretation
/// to help users understand their risk level.
struct CVRiskResult {
    /// The calculated risk as a percentage (0-100)
    let riskPercent: Double

    /// The categorical interpretation of the risk percentage
    let category: RiskCategory

    /// Risk categories for cardiovascular disease.
    ///
    /// Categories are based on standard clinical thresholds used
    /// in cardiovascular risk assessment guidelines.
    enum RiskCategory: String {
        /// Low risk: < 10% (10-year) or < 12% (30-year)
        case low = "Low"

        /// Intermediate risk: 10-20% (10-year) or 12-40% (30-year)
        case intermediate = "Intermediate"

        /// High risk: > 20% (10-year) or > 40% (30-year)
        case high = "High"

        /// Human-readable description with actionable guidance
        var description: String {
            switch self {
            case .low: return "Lower than average risk"
            case .intermediate: return "Moderate risk - lifestyle changes recommended"
            case .high: return "Higher risk - consult your healthcare provider"
            }
        }
    }
}

/// Cardiovascular risk calculation utilities.
///
/// Provides static methods for calculating:
/// - Fractional Pulse Pressure (fPP) as a marker of arterial stiffness
/// - 10-year cardiovascular risk using the Framingham Risk Score
/// - 30-year cardiovascular risk using extended Framingham functions
///
/// All calculations are based on peer-reviewed research and validated
/// risk prediction models from the Framingham Heart Study.
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

    /// Calculates 10-year cardiovascular disease risk using the Framingham Risk Score.
    ///
    /// Based on the General Cardiovascular Risk Profile from D'Agostino et al. (2008),
    /// published in Circulation. Uses log-transformed risk factors with sex-specific
    /// coefficients derived from the Framingham Heart Study cohort.
    ///
    /// The calculation uses Cox proportional hazards regression with the following variables:
    /// - Age (log-transformed)
    /// - Total cholesterol (log-transformed)
    /// - HDL cholesterol (log-transformed, protective)
    /// - Systolic blood pressure (log-transformed, with treatment modifier)
    /// - Current smoking status (binary)
    /// - Diabetes status (binary)
    ///
    /// - Parameters:
    ///   - profile: User profile containing demographic and health information
    ///   - systolicBP: Current systolic blood pressure in mmHg
    /// - Returns: CVRiskResult containing risk percentage and category
    /// - Note: Valid for ages 30-79. Results outside this range should be interpreted with caution.
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

    /// Categorizes 10-year risk percentage into clinical risk categories.
    ///
    /// Thresholds based on ATP III guidelines:
    /// - Low: < 10%
    /// - Intermediate: 10-20%
    /// - High: ≥ 20%
    ///
    /// - Parameter risk: The calculated 10-year risk percentage
    /// - Returns: The appropriate risk category
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

    /// Calculates 30-year cardiovascular disease risk using extended Framingham functions.
    ///
    /// Based on Pencina et al. (2009) "Predicting the 30-Year Risk of Cardiovascular Disease",
    /// published in Circulation. This extended model is particularly useful for younger adults
    /// (30-59 years) who may have low short-term but significant long-term risk.
    ///
    /// Uses a simplified point-based scoring system with categorical risk factor levels:
    /// - Age: Linear increase from age 20
    /// - Total cholesterol: Categories at 200 and 240 mg/dL
    /// - HDL cholesterol: Categories at 40 and 50 mg/dL
    /// - Systolic BP: Categories at 120, 140, and 160 mmHg
    /// - Treatment status, smoking, and diabetes as binary factors
    ///
    /// - Parameters:
    ///   - profile: User profile containing demographic and health information
    ///   - systolicBP: Current systolic blood pressure in mmHg
    /// - Returns: CVRiskResult containing risk percentage and category
    /// - Note: Best suited for adults aged 20-59. Older adults should primarily use 10-year risk.
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

    /// Categorizes 30-year risk percentage into clinical risk categories.
    ///
    /// Uses different thresholds than 10-year risk due to longer time horizon:
    /// - Low: < 12%
    /// - Intermediate: 12-40%
    /// - High: ≥ 40%
    ///
    /// - Parameter risk: The calculated 30-year risk percentage
    /// - Returns: The appropriate risk category
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
