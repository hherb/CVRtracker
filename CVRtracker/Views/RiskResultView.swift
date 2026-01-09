import SwiftUI

struct RiskResultView: View {
    @Environment(\.dismiss) private var dismiss

    let profile: UserProfile
    let systolicBP: Int

    private var risk10Year: CVRiskResult {
        Calculations.calculateFramingham10Year(profile: profile, systolicBP: systolicBP)
    }

    private var risk30Year: CVRiskResult {
        Calculations.calculateFramingham30Year(profile: profile, systolicBP: systolicBP)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)

                        Text("Cardiovascular Risk")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Based on Framingham Risk Score")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // 10-Year Risk Card
                    riskCard(
                        title: "10-Year Risk",
                        risk: risk10Year,
                        description: "Probability of cardiovascular event in the next 10 years"
                    )

                    // 30-Year Risk Card
                    riskCard(
                        title: "30-Year Risk",
                        risk: risk30Year,
                        description: "Probability of cardiovascular event in the next 30 years"
                    )

                    // Input Summary
                    inputSummaryCard

                    // Disclaimer
                    disclaimerCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Risk Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func riskCard(title: String, risk: CVRiskResult, description: String) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)

            // Risk Gauge
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)

                Circle()
                    .trim(from: 0, to: min(risk.riskPercent / 100, 1.0))
                    .stroke(
                        colorForRisk(risk.category),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: risk.riskPercent)

                VStack(spacing: 4) {
                    Text(String(format: "%.1f%%", risk.riskPercent))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(colorForRisk(risk.category))

                    Text(risk.category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForRisk(risk.category))
                }
            }
            .frame(width: 160, height: 160)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(risk.category.description)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private var inputSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Risk Factors")
                .font(.headline)

            VStack(spacing: 8) {
                summaryRow(label: "Age", value: "\(profile.age) years")
                summaryRow(label: "Sex", value: profile.sex.rawValue)
                summaryRow(label: "Blood Pressure", value: "\(systolicBP) mmHg (systolic)")
                summaryRow(label: "Total Cholesterol", value: "\(Int(profile.totalCholesterol)) mg/dL")
                summaryRow(label: "HDL Cholesterol", value: "\(Int(profile.hdlCholesterol)) mg/dL")
                summaryRow(label: "BP Medication", value: profile.onHypertensionTreatment ? "Yes" : "No")
                summaryRow(label: "Smoker", value: profile.isSmoker ? "Yes" : "No")
                summaryRow(label: "Diabetes", value: profile.hasDiabetes ? "Yes" : "No")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Important")
                    .font(.headline)
            }

            Text("This calculator provides an estimate based on the Framingham Heart Study. It is not a substitute for professional medical advice. Please consult your healthcare provider for personalized risk assessment and treatment recommendations.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
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
    RiskResultView(
        profile: UserProfile(
            age: 55,
            sex: .male,
            totalCholesterol: 220,
            hdlCholesterol: 45,
            onHypertensionTreatment: true,
            isSmoker: false,
            hasDiabetes: false
        ),
        systolicBP: 140
    )
}
