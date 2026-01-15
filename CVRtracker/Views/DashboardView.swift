import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Binding var selectedTab: AppTab
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Query(sort: \BPReading.timestamp, order: .reverse) private var readings: [BPReading]
    @Query(sort: \LipidReading.timestamp, order: .reverse) private var lipidReadings: [LipidReading]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? {
        profiles.first
    }

    private var latestReading: BPReading? {
        readings.first
    }

    private var latestLipidReading: LipidReading? {
        lipidReadings.first
    }

    /// Readings for the mini trend chart.
    /// Ensures at least 3 readings are shown (if available), regardless of time span.
    /// For charts to be meaningful, we prioritize having enough data points over recency.
    private var recentReadings: [BPReading] {
        // Always include at least 3 readings if available, up to 10 max
        let minReadings = 3
        let maxReadings = 10

        // If we have fewer than minReadings, just return what we have
        guard readings.count >= minReadings else {
            return readings.reversed()
        }

        // Return between minReadings and maxReadings, preferring more recent data
        let count = min(max(readings.count, minReadings), maxReadings)
        return Array(readings.prefix(count)).reversed()
    }

    // MARK: - Trend Analysis for Dashboard

    /// Readings for trend analysis (last 14 readings)
    private var trendReadings: [BPReading] {
        Array(readings.prefix(14))
    }

    /// Can we show trend interpretation?
    private var canShowTrendInterpretation: Bool {
        trendReadings.count >= 4
    }

    /// Pulse pressure trend direction
    private var dashboardPPTrend: TrendDirection {
        guard trendReadings.count >= 4 else { return .insufficient }
        let firstHalf = Array(trendReadings.suffix(trendReadings.count / 2))
        let secondHalf = Array(trendReadings.prefix(trendReadings.count / 2))

        let firstAvg = firstHalf.reduce(0) { $0 + Double($1.pulsePressure) } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0) { $0 + Double($1.pulsePressure) } / Double(secondHalf.count)

        let change = secondAvg - firstAvg
        if change < -2 { return .decreasing }
        else if change > 2 { return .increasing }
        else { return .stable }
    }

    /// Mean arterial pressure trend direction
    private var dashboardMAPTrend: TrendDirection {
        guard trendReadings.count >= 4 else { return .insufficient }
        let firstHalf = Array(trendReadings.suffix(trendReadings.count / 2))
        let secondHalf = Array(trendReadings.prefix(trendReadings.count / 2))

        let firstAvg = firstHalf.reduce(0) { $0 + $1.meanArterialPressure } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0) { $0 + $1.meanArterialPressure } / Double(secondHalf.count)

        let change = secondAvg - firstAvg
        if change < -3 { return .decreasing }
        else if change > 3 { return .increasing }
        else { return .stable }
    }

    /// Combined trend interpretation
    private var dashboardTrendInterpretation: TrendInterpretation {
        TrendInterpretation.interpret(ppTrend: dashboardPPTrend, mapTrend: dashboardMAPTrend)
    }

    private var canShowRisk: Bool {
        guard let profile = profile else { return false }
        return profile.age >= 30 && profile.age <= 79 &&
               latestLipidReading != nil &&
               latestReading != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current fPP Card
                    currentFPPCard

                    // Mini Trend Chart (requires at least 3 readings for meaningful trend)
                    if recentReadings.count >= 3 {
                        miniTrendChart
                    }

                    // Trend Interpretation
                    if canShowTrendInterpretation {
                        trendInterpretationCard
                    }

                    // Risk Scores
                    if canShowRisk, let profile = profile, let reading = latestReading, let lipid = latestLipidReading {
                        riskScoresCard(profile: profile, lipid: lipid, systolic: reading.systolic)
                    } else {
                        setupPromptCard
                    }

                    // Heart Rate from HealthKit
                    if let heartRate = healthKitManager.latestHeartRate {
                        heartRateCard(heartRate: heartRate)
                    }

                    // Latest Reading
                    if let reading = latestReading {
                        latestReadingCard(reading: reading)
                    }

                    // Medical Disclaimer with link to sources
                    CompactMedicalDisclaimer()
                }
                .padding()
            }
            .navigationTitle("CVR Tracker")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var currentFPPCard: some View {
        VStack(spacing: 8) {
            if let reading = latestReading {
                // Show BP category warning for critical readings
                if reading.bpCategory.isUrgent {
                    urgentBPWarning(reading: reading)
                } else if reading.bpCategory.overridesFPP {
                    highBPWithFPP(reading: reading)
                } else {
                    normalFPPDisplay(reading: reading)
                }
            } else {
                noReadingsDisplay
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    /// Display for hypertensive crisis - emphasize BP, minimize fPP
    private func urgentBPWarning(reading: BPReading) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text(reading.bpCategory.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(reading.bpCategory.color)
            .cornerRadius(8)

            Text("\(reading.systolic)/\(reading.diastolic)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(reading.bpCategory.color)

            Text("mmHg")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(reading.bpCategory.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()
                .padding(.vertical, 4)

            // Show fPP but de-emphasized
            HStack(spacing: 6) {
                Text("fPP:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.3f", reading.fractionalPulsePressure))
                    .font(.caption)
                    .foregroundColor(.secondary)
                InfoButton(topic: HelpContent.fractionalPulsePressure)
            }

            Text("Arterial stiffness assessment is secondary to BP control")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
    }

    /// Display for Stage 2 hypertension - show both BP and fPP with context
    private func highBPWithFPP(reading: BPReading) -> some View {
        VStack(spacing: 12) {
            // BP Category badge
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(reading.bpCategory.color)
                Text(reading.bpCategory.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(reading.bpCategory.color)
            }

            HStack(spacing: 6) {
                Text("Fractional Pulse Pressure")
                    .font(.headline)
                    .foregroundColor(.secondary)
                InfoButton(topic: HelpContent.fractionalPulsePressure)
            }

            Text(String(format: "%.3f", reading.fractionalPulsePressure))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(colorForFPP(reading.fractionalPulsePressure))

            Text(reading.fppCategory.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(colorForFPP(reading.fractionalPulsePressure))

            Text(reading.fppInterpretation)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    /// Normal fPP display when BP is not critical
    private func normalFPPDisplay(reading: BPReading) -> some View {
        VStack(spacing: 8) {
            // Show BP category if elevated (but not critical)
            if reading.bpCategory != .normal {
                HStack(spacing: 6) {
                    Circle()
                        .fill(reading.bpCategory.color)
                        .frame(width: 8, height: 8)
                    Text(reading.bpCategory.rawValue)
                        .font(.caption)
                        .foregroundColor(reading.bpCategory.color)
                }
            }

            HStack(spacing: 6) {
                Text("Fractional Pulse Pressure")
                    .font(.headline)
                    .foregroundColor(.secondary)
                InfoButton(topic: HelpContent.fractionalPulsePressure)
            }

            Text(String(format: "%.3f", reading.fractionalPulsePressure))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(colorForFPP(reading.fractionalPulsePressure))

            Text(reading.fppCategory.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(colorForFPP(reading.fractionalPulsePressure))

            Text(reading.fppInterpretation)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    /// Display when no readings exist
    private var noReadingsDisplay: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("Fractional Pulse Pressure")
                    .font(.headline)
                    .foregroundColor(.secondary)
                InfoButton(topic: HelpContent.fractionalPulsePressure)
            }

            Text("--")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)

            Text("No readings yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var miniTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Trend")
                    .font(.headline)
                Spacer()
                InfoButton(topic: HelpContent.interpretingTrends)
            }

            Chart {
                ForEach(recentReadings, id: \.id) { reading in
                    LineMark(
                        x: .value("Date", reading.timestamp),
                        y: .value("fPP", reading.fractionalPulsePressure)
                    )
                    .foregroundStyle(.red)
                    .symbol(Circle())
                }

                // Reference line at 0.4
                RuleMark(y: .value("Normal", 0.4))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .chartYScale(domain: 0.3...0.6)
            .frame(height: 150)

            // Brief clinical relevance explanation
            Text("Fractional Pulse Pressure (fPP) reflects arterial stiffness. Values below 0.40 indicate healthy, elastic arteries. Rising trends may suggest progressive vascular stiffening.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private var trendInterpretationCard: some View {
        let interp = dashboardTrendInterpretation

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: trendIcon(for: interp.category))
                    .foregroundColor(interp.color)
                    .font(.title3)

                Text(interp.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(interp.color)

                Spacer()

                InfoButton(topic: HelpContent.interpretingTrends)
            }

            Text(interp.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Compact trend indicators
            HStack(spacing: 16) {
                dashboardTrendIndicator(label: "PP", trend: dashboardPPTrend)
                dashboardTrendIndicator(label: "MAP", trend: dashboardMAPTrend)
                Spacer()
                Text("\(trendReadings.count) readings")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private func dashboardTrendIndicator(label: String, trend: TrendDirection) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(trend.symbol)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(dashboardColorForTrend(trend))
        }
    }

    private func dashboardColorForTrend(_ trend: TrendDirection) -> Color {
        switch trend {
        case .increasing: return .red
        case .stable: return .blue
        case .decreasing: return .green
        case .insufficient: return .secondary
        }
    }

    private func trendIcon(for category: TrendInterpretation.Category) -> String {
        switch category {
        case .bestScenario: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .neutral: return "equal.circle.fill"
        case .needsAttention: return "exclamationmark.circle.fill"
        case .concerning: return "exclamationmark.triangle.fill"
        case .mostConcerning: return "exclamationmark.octagon.fill"
        case .insufficient: return "questionmark.circle"
        }
    }

    private func riskScoresCard(profile: UserProfile, lipid: LipidReading, systolic: Int) -> some View {
        // Create a profile with lipid values for calculation
        let calculationProfile = UserProfile(
            age: profile.age,
            sex: profile.sex,
            totalCholesterol: lipid.totalCholesterol,
            hdlCholesterol: lipid.hdlCholesterol,
            onHypertensionTreatment: profile.onHypertensionTreatment,
            isSmoker: profile.isSmoker,
            hasDiabetes: profile.hasDiabetes
        )
        let risk10 = Calculations.calculateFramingham10Year(profile: calculationProfile, systolicBP: systolic)
        let risk30 = Calculations.calculateFramingham30Year(profile: calculationProfile, systolicBP: systolic)

        return VStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("Cardiovascular Risk")
                    .font(.headline)
                InfoButton(topic: HelpContent.framinghamRiskScore)
            }

            HStack(spacing: 20) {
                riskScoreItem(title: "10-Year", risk: risk10, topic: HelpContent.framinghamRiskScore)
                Divider()
                riskScoreItem(title: "30-Year", risk: risk30, topic: HelpContent.thirtyYearRisk)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private func riskScoreItem(title: String, risk: CVRiskResult, topic: HelpTopic) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                InfoButton(topic: topic)
            }

            Text(String(format: "%.1f%%", risk.riskPercent))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorForRisk(risk.category))

            Text(risk.category.rawValue)
                .font(.caption2)
                .foregroundColor(colorForRisk(risk.category))
        }
        .frame(maxWidth: .infinity)
    }

    private var setupPromptCard: some View {
        Button {
            selectedTab = .profile
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                Text("Complete Your Profile")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Add your health information in the Profile tab and lipid readings to see your cardiovascular risk scores.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10)
        }
        .buttonStyle(.plain)
    }

    private func latestReadingCard(reading: BPReading) -> some View {
        VStack(spacing: 8) {
            Text("Latest Reading")
                .font(.headline)

            HStack(spacing: 24) {
                VStack {
                    Text("\(reading.systolic)/\(reading.diastolic)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("mmHg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack {
                    Text("\(reading.pulsePressure)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Pulse Pressure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack {
                    Text(String(format: "%.1f", reading.meanArterialPressure))
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("MAP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(reading.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private func heartRateCard(heartRate: HeartRateReading) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Heart Rate")
                    .font(.headline)
            }

            Text("\(heartRate.bpm)")
                .font(.system(size: 40, weight: .bold, design: .rounded))

            Text("BPM")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(heartRate.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private func colorForFPP(_ fpp: Double) -> Color {
        if fpp < 0.4 {
            return .green
        } else if fpp < 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    private func colorForRisk(_ category: CVRiskResult.RiskCategory) -> Color {
        switch category {
        case .low: return .green
        case .intermediate: return .orange
        case .high: return .red
        }
    }
}

#Preview {
    DashboardView(selectedTab: .constant(.dashboard))
        .environmentObject(HealthKitManager())
        .modelContainer(for: [BPReading.self, UserProfile.self, LipidReading.self], inMemory: true)
}
