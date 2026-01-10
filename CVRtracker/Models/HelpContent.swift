import Foundation

/// Central repository for educational content used in tooltips and the tutorial section.
///
/// This struct contains static `HelpTopic` instances for all cardiovascular health metrics
/// and risk factors tracked by the app. Content is designed to be:
/// - Accurate and clinically relevant
/// - Accessible to non-medical users
/// - Actionable where appropriate
///
/// Topics are organized into categories:
/// - Blood pressure metrics (systolic, diastolic, pulse pressure)
/// - Arterial health indicators (fPP, arterial stiffness, vascular aging)
/// - Lipid panel values (cholesterol types, triglycerides, ratios)
/// - Risk assessment tools (Framingham scores)
/// - Modifiable risk factors (smoking, diabetes, hypertension treatment)
struct HelpContent {

    // MARK: - Blood Pressure

    static let systolicBP = HelpTopic(
        title: "Systolic Blood Pressure",
        shortDescription: "The pressure when your heart beats",
        detailedDescription: """
            Systolic blood pressure is the top number in a blood pressure reading. It measures the pressure in your arteries when your heart muscle contracts and pumps blood.

            Normal: Less than 120 mmHg
            Elevated: 120-129 mmHg
            High (Stage 1): 130-139 mmHg
            High (Stage 2): 140+ mmHg
            """,
        clinicalRelevance: "Higher systolic pressure increases strain on artery walls and is a major risk factor for heart disease and stroke."
    )

    static let diastolicBP = HelpTopic(
        title: "Diastolic Blood Pressure",
        shortDescription: "The pressure between heartbeats",
        detailedDescription: """
            Diastolic blood pressure is the bottom number in a blood pressure reading. It measures the pressure in your arteries when your heart rests between beats.

            Normal: Less than 80 mmHg
            High (Stage 1): 80-89 mmHg
            High (Stage 2): 90+ mmHg
            """,
        clinicalRelevance: "While systolic pressure rises with age, elevated diastolic pressure is particularly concerning in younger adults."
    )

    static let pulsePressure = HelpTopic(
        title: "Pulse Pressure",
        shortDescription: "Difference between systolic and diastolic",
        detailedDescription: """
            Pulse pressure is calculated as:
            Systolic BP − Diastolic BP

            Normal range: 40-60 mmHg

            A pulse pressure greater than 60 mmHg may indicate stiff arteries, while very low pulse pressure (<25 mmHg) may suggest poor heart function.
            """,
        clinicalRelevance: "Wide pulse pressure is associated with arterial stiffness and increased cardiovascular risk, especially in older adults."
    )

    // MARK: - Fractional Pulse Pressure

    static let fractionalPulsePressure = HelpTopic(
        title: "Fractional Pulse Pressure (fPP)",
        shortDescription: "A measure of arterial stiffness",
        detailedDescription: """
            Fractional Pulse Pressure is calculated as:
            fPP = Pulse Pressure ÷ Mean Arterial Pressure

            Categories:
            • < 0.40: Normal - healthy arterial elasticity
            • 0.40-0.50: Elevated - moderate arterial stiffness
            • > 0.50: High - significant arterial stiffness

            Mean Arterial Pressure (MAP) is estimated as:
            MAP = Diastolic + (0.412 × Pulse Pressure)
            """,
        clinicalRelevance: "fPP serves as a non-invasive proxy for arterial stiffness, which is a marker of vascular aging. Stiff arteries require the heart to work harder and increase cardiovascular risk."
    )

    // MARK: - Arterial Stiffness & Vascular Aging

    static let arterialStiffness = HelpTopic(
        title: "Arterial Stiffness",
        shortDescription: "Loss of elasticity in artery walls",
        detailedDescription: """
            Arterial stiffness refers to the reduced ability of arteries to expand and contract with each heartbeat. Healthy arteries are elastic, cushioning the blood flow and reducing stress on the heart.

            Causes of arterial stiffness:
            • Natural aging process
            • High blood pressure
            • Diabetes
            • Smoking
            • High cholesterol
            • Sedentary lifestyle

            Consequences:
            • Increased systolic blood pressure
            • Wider pulse pressure
            • Greater cardiac workload
            • Increased risk of heart disease and stroke
            """,
        clinicalRelevance: "Arterial stiffness is considered a marker of biological vascular age. Your arteries may be 'older' or 'younger' than your chronological age depending on your cardiovascular health."
    )

    static let vascularAging = HelpTopic(
        title: "Vascular Aging",
        shortDescription: "How your blood vessels age over time",
        detailedDescription: """
            Vascular aging is the gradual structural and functional decline of blood vessels over time. While some aging is inevitable, the rate varies significantly between individuals.

            Signs of accelerated vascular aging:
            • Elevated blood pressure
            • Increased arterial stiffness (high fPP)
            • Abnormal lipid levels

            Factors that accelerate vascular aging:
            • Uncontrolled hypertension
            • Diabetes
            • Smoking
            • Obesity
            • Physical inactivity
            • Poor diet

            Factors that slow vascular aging:
            • Regular aerobic exercise
            • Healthy diet (Mediterranean, DASH)
            • Blood pressure control
            • Not smoking
            • Maintaining healthy weight
            """,
        clinicalRelevance: "By tracking your cardiovascular metrics over time, you can monitor your vascular health and potentially slow vascular aging through lifestyle modifications."
    )

    // MARK: - Lipid Panel

    static let totalCholesterol = HelpTopic(
        title: "Total Cholesterol",
        shortDescription: "Combined measure of all cholesterol types",
        detailedDescription: """
            Total cholesterol is the sum of LDL, HDL, and 20% of triglycerides.

            Desirable: Less than 200 mg/dL (5.2 mmol/L)
            Borderline high: 200-239 mg/dL (5.2-6.2 mmol/L)
            High: 240+ mg/dL (6.2+ mmol/L)

            While total cholesterol provides an overview, the ratio of different cholesterol types is more important for risk assessment.
            """,
        clinicalRelevance: "Used in cardiovascular risk calculations, but LDL and HDL levels provide more specific risk information."
    )

    static let hdlCholesterol = HelpTopic(
        title: "HDL Cholesterol",
        shortDescription: "\"Good\" cholesterol - higher is better",
        detailedDescription: """
            HDL (High-Density Lipoprotein) carries cholesterol away from arteries back to the liver for removal.

            Optimal: 60+ mg/dL (1.6+ mmol/L)
            Acceptable: 40-59 mg/dL (1.0-1.5 mmol/L)
            Low (risk factor): Less than 40 mg/dL (1.0 mmol/L)

            Ways to raise HDL:
            • Aerobic exercise
            • Moderate alcohol (if appropriate)
            • Quit smoking
            • Lose excess weight
            • Eat healthy fats (olive oil, nuts, fish)
            """,
        clinicalRelevance: "High HDL levels are protective against heart disease. Low HDL is an independent risk factor even when LDL is normal."
    )

    static let ldlCholesterol = HelpTopic(
        title: "LDL Cholesterol",
        shortDescription: "\"Bad\" cholesterol - lower is better",
        detailedDescription: """
            LDL (Low-Density Lipoprotein) carries cholesterol to arteries where it can build up in vessel walls.

            Optimal: Less than 100 mg/dL (2.6 mmol/L)
            Near optimal: 100-129 mg/dL (2.6-3.3 mmol/L)
            Borderline high: 130-159 mg/dL (3.4-4.1 mmol/L)
            High: 160-189 mg/dL (4.1-4.9 mmol/L)
            Very high: 190+ mg/dL (4.9+ mmol/L)

            If not directly measured, LDL can be calculated using the Friedewald equation:
            LDL = Total Cholesterol − HDL − (Triglycerides ÷ 5)
            (Valid only when triglycerides < 400 mg/dL)
            """,
        clinicalRelevance: "LDL is the primary target for cholesterol-lowering therapy. Each 1% reduction in LDL reduces cardiovascular risk by approximately 1%."
    )

    static let triglycerides = HelpTopic(
        title: "Triglycerides",
        shortDescription: "Fat in blood from recent food intake",
        detailedDescription: """
            Triglycerides are fats from food that circulate in blood and are stored for energy.

            Normal: Less than 150 mg/dL (1.7 mmol/L)
            Borderline high: 150-199 mg/dL (1.7-2.2 mmol/L)
            High: 200-499 mg/dL (2.3-5.6 mmol/L)
            Very high: 500+ mg/dL (5.7+ mmol/L)

            High triglycerides are often associated with:
            • Obesity
            • Poorly controlled diabetes
            • Excessive alcohol
            • High-carbohydrate diet
            • Some medications
            """,
        clinicalRelevance: "Elevated triglycerides contribute to arterial plaque buildup and are associated with metabolic syndrome and increased cardiovascular risk."
    )

    static let totalHDLRatio = HelpTopic(
        title: "Total/HDL Cholesterol Ratio",
        shortDescription: "Risk indicator comparing total to HDL",
        detailedDescription: """
            The ratio of total cholesterol to HDL cholesterol.

            Optimal: Less than 3.5
            Borderline: 3.5-5.0
            High risk: Greater than 5.0

            This ratio accounts for the protective effect of HDL. Someone with high total cholesterol but very high HDL may have lower risk than someone with lower total cholesterol but low HDL.
            """,
        clinicalRelevance: "Some clinicians prefer this ratio as a quick risk indicator because it captures both the harmful (LDL) and protective (HDL) aspects of cholesterol."
    )

    // MARK: - Framingham Risk Score

    static let framinghamRiskScore = HelpTopic(
        title: "Framingham Risk Score",
        shortDescription: "Predicts 10-year cardiovascular risk",
        detailedDescription: """
            The Framingham Risk Score estimates your probability of having a cardiovascular event (heart attack, stroke) in the next 10 years.

            Based on the landmark Framingham Heart Study, it uses:
            • Age
            • Sex
            • Total cholesterol
            • HDL cholesterol
            • Systolic blood pressure
            • Blood pressure treatment status
            • Smoking status
            • Diabetes status

            Risk Categories (10-year):
            • Low: Less than 10%
            • Intermediate: 10-20%
            • High: Greater than 20%
            """,
        clinicalRelevance: "Developed from decades of data from the Framingham Heart Study (D'Agostino et al., 2008). Used worldwide to guide preventive treatment decisions."
    )

    static let thirtyYearRisk = HelpTopic(
        title: "30-Year Cardiovascular Risk",
        shortDescription: "Long-term risk projection",
        detailedDescription: """
            An extended risk calculation showing your probability of cardiovascular disease over 30 years.

            Based on Pencina et al. (2009), this projection is particularly useful for:
            • Younger adults (30-59 years)
            • People with borderline risk factors
            • Long-term planning and motivation

            Risk Categories (30-year):
            • Low: Less than 12%
            • Intermediate: 12-40%
            • High: Greater than 40%
            """,
        clinicalRelevance: "Younger adults may have low 10-year risk but high 30-year risk. This extended view helps motivate early lifestyle changes."
    )

    // MARK: - Profile Risk Factors

    static let hypertensionTreatment = HelpTopic(
        title: "Blood Pressure Medication",
        shortDescription: "Whether you take BP-lowering drugs",
        detailedDescription: """
            Indicates if you are currently taking medication to lower blood pressure. This includes:
            • ACE inhibitors
            • ARBs
            • Beta-blockers
            • Calcium channel blockers
            • Diuretics
            • Other antihypertensives

            Being on treatment affects risk calculations because:
            1. Your current BP reading may be artificially lower than your natural BP
            2. The need for treatment indicates underlying cardiovascular risk
            """,
        clinicalRelevance: "Even with well-controlled blood pressure on medication, cardiovascular risk remains higher than someone with naturally normal blood pressure."
    )

    static let smokingStatus = HelpTopic(
        title: "Smoking Status",
        shortDescription: "Current tobacco use significantly increases risk",
        detailedDescription: """
            Current smoking dramatically increases cardiovascular risk through multiple mechanisms:
            • Damages blood vessel lining (endothelium)
            • Accelerates arterial stiffening
            • Increases blood clotting tendency
            • Reduces HDL cholesterol
            • Increases inflammation

            Smoking cessation benefits:
            • Risk drops significantly within 1 year
            • After 5-15 years, stroke risk equals non-smoker
            • After 15 years, heart disease risk approaches non-smoker
            """,
        clinicalRelevance: "Smoking is one of the most modifiable risk factors. Quitting at any age significantly reduces cardiovascular risk."
    )

    static let diabetesStatus = HelpTopic(
        title: "Diabetes",
        shortDescription: "Blood sugar condition that increases CV risk",
        detailedDescription: """
            Diabetes (Type 1 or Type 2) significantly increases cardiovascular risk through:
            • Accelerated atherosclerosis
            • Blood vessel damage from high glucose
            • Increased inflammation
            • Abnormal blood clotting
            • Often associated with other risk factors (obesity, high BP, abnormal lipids)

            Cardiovascular disease is the leading cause of death in people with diabetes.
            """,
        clinicalRelevance: "Diabetes is considered a \"coronary heart disease equivalent\" - diabetics without prior heart disease have similar risk to non-diabetics who have had a heart attack."
    )

    // MARK: - Apple Health Integration

    static let appleHealthIntegration = HelpTopic(
        title: "Apple Health Integration",
        shortDescription: "Sync blood pressure with Apple Health",
        detailedDescription: """
            When enabled, CVR Tracker can sync with Apple Health:

            Export: Your blood pressure readings are saved to Apple Health, making them available to other health apps.

            Import: Blood pressure readings from other apps and devices (like smart BP monitors) are imported into CVR Tracker.

            Heart Rate: Your latest heart rate from Apple Watch or other devices is displayed on the dashboard.

            Note: Lipid/cholesterol data is not supported by Apple Health and remains stored only in this app.
            """,
        clinicalRelevance: "Syncing health data between apps and devices provides a more complete picture of your cardiovascular health over time and enables better tracking of trends."
    )

    // MARK: - Understanding Your Results (Patient Education)

    static let understandingPulsePressure = HelpTopic(
        title: "Understanding Your Pulse Pressure",
        shortDescription: "What pulse pressure tells you about heart health",
        detailedDescription: """
            Your Blood Pressure Has Two Numbers for a Reason

            When you check your blood pressure, you get two numbers like "120/80." The top number (systolic) is the pressure when your heart pumps. The bottom number (diastolic) is the pressure when your heart rests between beats.

            The difference between these two numbers is called your pulse pressure. If your blood pressure is 120/80, your pulse pressure is 40 mmHg (120 minus 80).

            What's Normal?

            A healthy pulse pressure is between 40 and 60 mmHg. Research from the Framingham Heart Study found that for every 10 mmHg increase in pulse pressure above normal, your risk of heart problems goes up by about 20%.

            Why Does Pulse Pressure Matter?

            Your arteries are like flexible tubes. When they're healthy, they stretch when blood pumps through them, then spring back. This "cushioning" effect keeps blood flowing smoothly to your organs.

            As we age—or if we have high blood pressure, diabetes, or other conditions—arteries can become stiffer, like old rubber bands that have lost their stretch. When arteries get stiff:

            • The top number (systolic) goes up
            • The bottom number (diastolic) may stay the same or drop
            • The gap between them (pulse pressure) gets wider

            A wide pulse pressure (over 60 mmHg) often signals that your arteries have become stiffer than normal for your age.

            But Here's the Important Part

            While pulse pressure tells us about artery stiffness, your actual blood pressure numbers matter more for immediate health risk.

            Think of it this way: If someone has a blood pressure of 200/140, their pulse pressure of 60 mmHg might look "normal"—but their blood pressure is dangerously high and needs immediate attention. The pulse pressure is less important than the fact that both numbers are in the danger zone.

            Blood Pressure Categories:

            • Normal: Less than 120/80 mmHg
            • Elevated: 120-129 / less than 80 mmHg
            • High (Stage 1): 130-139 / 80-89 mmHg
            • High (Stage 2): 140+ / 90+ mmHg
            • Crisis (seek care): 180+ / 120+ mmHg

            Only when your blood pressure is in a safe range should you focus on what your pulse pressure says about artery health.

            What About Fractional Pulse Pressure (fPP)?

            This app calculates something called "fractional pulse pressure" or fPP. It's a way to measure arterial stiffness that accounts for your overall blood pressure level.

            • fPP below 0.40: Good arterial elasticity
            • fPP 0.40-0.50: Moderate arterial stiffness
            • fPP above 0.50: Significant arterial stiffness

            Remember: fPP only gives meaningful information about your arteries when your blood pressure itself is not dangerously high.

            Age Makes a Difference

            Research shows that pulse pressure affects people differently depending on age:

            • Under 50: Pulse pressure has little impact on heart risk. Focus on overall blood pressure.
            • Over 50: Pulse pressure becomes an increasingly important predictor of heart problems.

            This is because arterial stiffness naturally increases with age, so elevated pulse pressure in older adults is a clearer warning sign.

            What Can You Do?

            The good news is that arterial stiffness can often be slowed or improved:

            • Regular aerobic exercise (walking, swimming, cycling)
            • Eating a heart-healthy diet (less salt, more vegetables)
            • Maintaining a healthy weight
            • Not smoking
            • Managing blood pressure, cholesterol, and blood sugar
            • Omega-3 fatty acids from fish or supplements
            """,
        clinicalRelevance: "Understanding pulse pressure in context helps you focus on what matters most: when blood pressure is high, that's the priority. When blood pressure is normal, pulse pressure helps reveal hidden arterial stiffness that could be addressed through lifestyle changes.",
        references: [
            Reference(
                title: "Framingham Heart Study: Pulse Pressure and CV Risk",
                url: URL(string: "https://www.ahajournals.org/doi/10.1161/hy1001.092966")!
            ),
            Reference(
                title: "NIH StatPearls: Pulse Pressure Physiology",
                url: URL(string: "https://www.ncbi.nlm.nih.gov/books/NBK482408/")!
            ),
            Reference(
                title: "Wide Pulse Pressure: A Clinical Review",
                url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8029839/")!
            ),
            Reference(
                title: "Age-Related Pulse Pressure Risk Assessment",
                url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8457427/")!
            ),
            Reference(
                title: "Arterial Stiffness and Hypertension",
                url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10691097/")!
            )
        ]
    )
}

/// A research reference with a clickable URL.
///
/// Used to provide citations for educational content, allowing users
/// to explore the scientific basis for health information.
struct Reference: Identifiable {
    /// Unique identifier for SwiftUI list operations
    let id = UUID()

    /// Display title for the reference (e.g., "Framingham Heart Study")
    let title: String

    /// URL to the research paper or article
    let url: URL
}

/// A single educational topic with layered information depth.
///
/// Topics provide three levels of information:
/// 1. `shortDescription`: One-line summary for tooltips
/// 2. `detailedDescription`: Full explanation with reference ranges
/// 3. `clinicalRelevance`: Why this matters for cardiovascular health
///
/// This structure supports progressive disclosure - users can see a quick
/// summary or dive deeper into the clinical significance.
struct HelpTopic: Identifiable {
    /// Unique identifier for SwiftUI list operations
    let id = UUID()

    /// Display title for the topic (e.g., "Systolic Blood Pressure")
    let title: String

    /// Brief one-line description suitable for tooltips
    let shortDescription: String

    /// Comprehensive explanation including normal ranges and categories
    let detailedDescription: String

    /// Why this metric matters for cardiovascular health assessment
    let clinicalRelevance: String

    /// Optional research references with clickable links
    let references: [Reference]

    init(title: String, shortDescription: String, detailedDescription: String,
         clinicalRelevance: String, references: [Reference] = []) {
        self.title = title
        self.shortDescription = shortDescription
        self.detailedDescription = detailedDescription
        self.clinicalRelevance = clinicalRelevance
        self.references = references
    }
}

/// A grouped section of related help topics for the tutorial view.
///
/// Sections organize topics into logical categories to help users
/// navigate educational content. Each section has a visual icon
/// and contains multiple related `HelpTopic` items.
struct TutorialSection: Identifiable {
    /// Unique identifier for SwiftUI list operations
    let id = UUID()

    /// Display title for the section (e.g., "Blood Pressure Basics")
    let title: String

    /// SF Symbol name for the section icon
    let icon: String

    /// The help topics contained in this section
    let topics: [HelpTopic]
}

extension HelpContent {
    /// Organized sections for the tutorial view.
    ///
    /// Topics are grouped into six main categories:
    /// 1. Understanding Your Results - interpreting your readings in context
    /// 2. Blood Pressure Basics - fundamental BP concepts
    /// 3. Arterial Stiffness & Vascular Aging - advanced health indicators
    /// 4. Understanding Lipids - cholesterol and triglyceride education
    /// 5. Cardiovascular Risk Assessment - Framingham risk scores
    /// 6. Risk Factors - modifiable lifestyle factors
    static let tutorialSections: [TutorialSection] = [
        TutorialSection(
            title: "Understanding Your Results",
            icon: "lightbulb.fill",
            topics: [understandingPulsePressure]
        ),
        TutorialSection(
            title: "Blood Pressure Basics",
            icon: "heart.fill",
            topics: [systolicBP, diastolicBP, pulsePressure]
        ),
        TutorialSection(
            title: "Arterial Stiffness & Vascular Aging",
            icon: "waveform.path.ecg",
            topics: [fractionalPulsePressure, arterialStiffness, vascularAging]
        ),
        TutorialSection(
            title: "Understanding Lipids",
            icon: "drop.fill",
            topics: [totalCholesterol, hdlCholesterol, ldlCholesterol, triglycerides, totalHDLRatio]
        ),
        TutorialSection(
            title: "Cardiovascular Risk Assessment",
            icon: "chart.bar.fill",
            topics: [framinghamRiskScore, thirtyYearRisk]
        ),
        TutorialSection(
            title: "Risk Factors",
            icon: "exclamationmark.triangle.fill",
            topics: [hypertensionTreatment, smokingStatus, diabetesStatus]
        )
    ]
}
