import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
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

    private var recentReadings: [BPReading] {
        Array(readings.prefix(7)).reversed()
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

                    // Mini Trend Chart
                    if recentReadings.count >= 2 {
                        miniTrendChart
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
            Text("Recent Trend")
                .font(.headline)

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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
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
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text("Complete Your Profile")
                .font(.headline)

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
    DashboardView()
        .environmentObject(HealthKitManager())
        .modelContainer(for: [BPReading.self, UserProfile.self, LipidReading.self], inMemory: true)
}
