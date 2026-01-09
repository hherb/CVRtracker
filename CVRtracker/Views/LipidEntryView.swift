import SwiftUI
import SwiftData

struct LipidEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var totalCholesterol: Double = 200
    @State private var hdlCholesterol: Double = 50
    @State private var ldlCholesterol: Double = 100
    @State private var triglycerides: Double = 150
    @State private var hasLDL: Bool = false
    @State private var hasTriglycerides: Bool = false
    @State private var timestamp: Date = Date()

    @State private var showingSaveConfirmation = false

    private var profile: UserProfile? {
        profiles.first
    }

    private var cholesterolUnit: CholesterolUnit {
        profile?.cholesterolUnit ?? .mgdL
    }

    private var triglycerideUnit: TriglycerideUnit {
        profile?.triglycerideUnit ?? .mgdL
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $timestamp, displayedComponents: [.date])
                } header: {
                    Text("Reading Date")
                }

                Section {
                    HStack {
                        Text("Total Cholesterol")
                        Spacer()
                        TextField("Value", value: $totalCholesterol, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(cholesterolUnit.rawValue)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("HDL Cholesterol")
                        Spacer()
                        TextField("Value", value: $hdlCholesterol, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(cholesterolUnit.rawValue)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Required Values")
                }

                Section {
                    Toggle("LDL measured directly", isOn: $hasLDL)

                    if hasLDL {
                        HStack {
                            Text("LDL Cholesterol")
                            Spacer()
                            TextField("Value", value: $ldlCholesterol, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(cholesterolUnit.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle("Triglycerides measured", isOn: $hasTriglycerides)

                    if hasTriglycerides {
                        HStack {
                            Text("Triglycerides")
                            Spacer()
                            TextField("Value", value: $triglycerides, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(triglycerideUnit.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Optional Values")
                } footer: {
                    Text("LDL can be calculated from other values if triglycerides are provided and < 400 mg/dL.")
                }

                Section {
                    Button {
                        saveReading()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Save Reading", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(totalCholesterol <= 0 || hdlCholesterol <= 0)
                }
            }
            .navigationTitle("Add Lipids")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Lipid reading has been saved.")
            }
        }
    }

    private func saveReading() {
        // Convert from display units to mg/dL for storage
        let totalInMgdL = cholesterolUnit.toMgdL(totalCholesterol)
        let hdlInMgdL = cholesterolUnit.toMgdL(hdlCholesterol)
        let ldlInMgdL: Double? = hasLDL ? cholesterolUnit.toMgdL(ldlCholesterol) : nil
        let trigInMgdL: Double? = hasTriglycerides ? triglycerideUnit.toMgdL(triglycerides) : nil

        let reading = LipidReading(
            totalCholesterol: totalInMgdL,
            hdlCholesterol: hdlInMgdL,
            ldlCholesterol: ldlInMgdL,
            triglycerides: trigInMgdL,
            timestamp: timestamp
        )

        modelContext.insert(reading)
        showingSaveConfirmation = true
    }
}

#Preview {
    LipidEntryView()
        .modelContainer(for: [LipidReading.self, UserProfile.self], inMemory: true)
}
