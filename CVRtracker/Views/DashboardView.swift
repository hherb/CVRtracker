import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
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
            HStack(spacing: 6) {
                Text("Fractional Pulse Pressure")
                    .font(.headline)
                    .foregroundColor(.secondary)
                InfoButton(topic: HelpContent.fractionalPulsePressure)
            }

            if let reading = latestReading {
                Text(String(format: "%.3f", reading.fractionalPulsePressure))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(colorForFPP(reading.fractionalPulsePressure))

                Text(reading.fppCategory.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForFPP(reading.fractionalPulsePressure))

                Text(reading.fppCategory.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("--")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)

                Text("No readings yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
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
        .modelContainer(for: [BPReading.self, UserProfile.self, LipidReading.self], inMemory: true)
}
