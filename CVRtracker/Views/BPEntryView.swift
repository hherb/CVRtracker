import SwiftUI
import SwiftData

struct BPEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var systolic: Int = 120
    @State private var diastolic: Int = 80
    @State private var timestamp: Date = Date()
    @State private var showingSavedAlert = false

    private var calculatedFPP: Double {
        Calculations.calculateFPP(systolic: systolic, diastolic: diastolic)
    }

    private var pulsePressure: Int {
        systolic - diastolic
    }

    private var isValidReading: Bool {
        systolic > diastolic && systolic >= 70 && systolic <= 250 && diastolic >= 40 && diastolic <= 150
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        // Systolic Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Systolic (top number)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Stepper(value: $systolic, in: 70...250, step: 1) {
                                    Text("\(systolic)")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }

                                Text("mmHg")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        // Diastolic Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Diastolic (bottom number)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Stepper(value: $diastolic, in: 40...150, step: 1) {
                                    Text("\(diastolic)")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }

                                Text("mmHg")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Blood Pressure")
                }

                Section {
                    DatePicker("Date & Time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("When")
                }

                Section {
                    HStack {
                        Text("Pulse Pressure")
                        Spacer()
                        Text("\(pulsePressure) mmHg")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Fractional Pulse Pressure")
                        Spacer()
                        Text(String(format: "%.3f", calculatedFPP))
                            .fontWeight(.bold)
                            .foregroundColor(colorForFPP(calculatedFPP))
                    }

                    HStack {
                        Text("Category")
                        Spacer()
                        Text(categoryForFPP(calculatedFPP))
                            .fontWeight(.semibold)
                            .foregroundColor(colorForFPP(calculatedFPP))
                    }
                } header: {
                    Text("Calculated Values")
                } footer: {
                    Text("Lower fPP values indicate better vascular health. Normal is below 0.40.")
                }

                Section {
                    Button(action: saveReading) {
                        HStack {
                            Spacer()
                            Label("Save Reading", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(!isValidReading)
                }
            }
            .navigationTitle("Add BP Reading")
            .alert("Reading Saved", isPresented: $showingSavedAlert) {
                Button("OK", role: .cancel) {
                    resetForm()
                }
            } message: {
                Text("Your blood pressure reading has been saved.")
            }
        }
    }

    private func saveReading() {
        let reading = BPReading(systolic: systolic, diastolic: diastolic, timestamp: timestamp)
        modelContext.insert(reading)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        showingSavedAlert = true
    }

    private func resetForm() {
        systolic = 120
        diastolic = 80
        timestamp = Date()
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

    private func categoryForFPP(_ fpp: Double) -> String {
        if fpp < 0.4 {
            return "Normal"
        } else if fpp < 0.5 {
            return "Elevated"
        } else {
            return "High"
        }
    }
}

#Preview {
    BPEntryView()
        .modelContainer(for: BPReading.self, inMemory: true)
}
