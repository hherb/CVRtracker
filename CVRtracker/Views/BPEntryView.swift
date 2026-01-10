import SwiftUI
import SwiftData

struct BPEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Query private var profiles: [UserProfile]

    @State private var systolic: Int = 120
    @State private var diastolic: Int = 80
    @State private var systolicText: String = "120"
    @State private var diastolicText: String = "80"
    @State private var timestamp: Date = Date()
    @State private var showingSavedAlert = false
    @FocusState private var focusedField: Field?

    enum Field {
        case systolic, diastolic
    }

    private var calculatedFPP: Double {
        Calculations.calculateFPP(systolic: systolic, diastolic: diastolic)
    }

    private var pulsePressure: Int {
        systolic - diastolic
    }

    private var isValidReading: Bool {
        systolic > diastolic && systolic >= 70 && systolic <= 250 && diastolic >= 40 && diastolic <= 150
    }

    private var healthKitEnabled: Bool {
        profiles.first?.healthKitEnabled ?? false
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 4) {
                    Spacer()
                    TextField("120", text: $systolicText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .frame(width: 90)
                        .focused($focusedField, equals: .systolic)
                        .onChange(of: systolicText) { _, newValue in
                            if let value = Int(newValue), value >= 0, value <= 999 {
                                systolic = value
                            }
                        }

                    Text("/")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)

                    TextField("80", text: $diastolicText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .frame(width: 90)
                        .focused($focusedField, equals: .diastolic)
                        .onChange(of: diastolicText) { _, newValue in
                            if let value = Int(newValue), value >= 0, value <= 999 {
                                diastolic = value
                            }
                        }

                    Text("mmHg")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            } header: {
                HStack(spacing: 6) {
                    Text("Blood Pressure")
                    InfoButton(topic: HelpContent.systolicBP)
                }
            }

            Section {
                DatePicker("Date & Time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
            }

            Section {
                HStack {
                    LabelWithInfo(text: "Pulse Pressure", topic: HelpContent.pulsePressure)
                    Spacer()
                    Text("\(pulsePressure) mmHg")
                        .foregroundColor(.secondary)
                }
                HStack {
                    LabelWithInfo(text: "fPP", topic: HelpContent.fractionalPulsePressure)
                    Spacer()
                    Text(String(format: "%.3f", calculatedFPP))
                        .fontWeight(.bold)
                        .foregroundColor(colorForFPP(calculatedFPP))
                    Text("(\(categoryForFPP(calculatedFPP)))")
                        .foregroundColor(colorForFPP(calculatedFPP))
                }
            } footer: {
                Text("fPP < 0.40 is normal")
            }

            Section {
                Button(action: saveReading) {
                    HStack {
                        Spacer()
                        Label("Save", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(!isValidReading)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .alert("Reading Saved", isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) {
                resetForm()
            }
        } message: {
            Text("Your blood pressure reading has been saved.")
        }
    }

    private func saveReading() {
        let reading = BPReading(systolic: systolic, diastolic: diastolic, timestamp: timestamp)
        modelContext.insert(reading)

        // Explicitly save to persist immediately
        do {
            try modelContext.save()
        } catch {
            print("Failed to save BP reading: \(error)")
        }

        // Export to HealthKit if enabled
        if healthKitEnabled && healthKitManager.isAvailable {
            Task {
                do {
                    try await healthKitManager.saveBPReading(
                        systolic: systolic,
                        diastolic: diastolic,
                        timestamp: timestamp
                    )
                } catch {
                    print("Failed to save to HealthKit: \(error)")
                }
            }
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        showingSavedAlert = true
    }

    private func resetForm() {
        systolic = 120
        diastolic = 80
        systolicText = "120"
        diastolicText = "80"
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
        .environmentObject(HealthKitManager())
        .modelContainer(for: [BPReading.self, UserProfile.self], inMemory: true)
}
