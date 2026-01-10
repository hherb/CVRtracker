import SwiftUI
import SwiftData

struct LipidEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    /// Optional reading to edit; if nil, creates a new reading
    var readingToEdit: LipidReading?

    @State private var totalCholesterolText: String = ""
    @State private var hdlCholesterolText: String = ""
    @State private var ldlCholesterolText: String = ""
    @State private var triglyceridesText: String = ""
    @State private var hasLDL: Bool = false
    @State private var hasTriglycerides: Bool = false
    @State private var timestamp: Date = Date()

    @State private var showingSaveConfirmation = false
    @State private var hasLoadedEditValues = false

    private var isEditMode: Bool { readingToEdit != nil }

    private var totalCholesterol: Double? {
        Double(totalCholesterolText)
    }

    private var hdlCholesterol: Double? {
        Double(hdlCholesterolText)
    }

    private var ldlCholesterol: Double? {
        Double(ldlCholesterolText)
    }

    private var triglycerides: Double? {
        Double(triglyceridesText)
    }

    private var isValidEntry: Bool {
        guard let total = totalCholesterol, let hdl = hdlCholesterol else { return false }
        return total > 0 && hdl > 0
    }

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
                        LabelWithInfo(text: "Total Cholesterol", topic: HelpContent.totalCholesterol)
                        Spacer()
                        TextField("", text: $totalCholesterolText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(cholesterolUnit.rawValue)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        LabelWithInfo(text: "HDL Cholesterol", topic: HelpContent.hdlCholesterol)
                        Spacer()
                        TextField("", text: $hdlCholesterolText)
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
                    HStack {
                        Toggle("LDL measured directly", isOn: $hasLDL)
                        InfoButton(topic: HelpContent.ldlCholesterol)
                    }

                    if hasLDL {
                        HStack {
                            Text("LDL Cholesterol")
                            Spacer()
                            TextField("", text: $ldlCholesterolText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(cholesterolUnit.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Toggle("Triglycerides measured", isOn: $hasTriglycerides)
                        InfoButton(topic: HelpContent.triglycerides)
                    }

                    if hasTriglycerides {
                        HStack {
                            Text("Triglycerides")
                            Spacer()
                            TextField("", text: $triglyceridesText)
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
                            Label(isEditMode ? "Update Reading" : "Save Reading", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(!isValidEntry)

                    if isEditMode {
                        Button(role: .destructive) {
                            deleteReading()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Reading", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Lipids" : "Add Lipids")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isEditMode ? "Updated" : "Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(isEditMode ? "Lipid reading has been updated." : "Lipid reading has been saved.")
            }
            .onChange(of: profiles) { _, _ in
                loadEditValuesIfNeeded()
            }
            .onAppear {
                loadEditValuesIfNeeded()
            }
        }
    }

    private func loadEditValuesIfNeeded() {
        // Only load once, and only when we have a reading to edit and profile is available
        guard !hasLoadedEditValues,
              let reading = readingToEdit,
              profile != nil else { return }

        hasLoadedEditValues = true

        // Convert from stored mg/dL to display units
        totalCholesterolText = String(format: "%.1f", reading.displayTotalCholesterol(unit: cholesterolUnit))
        hdlCholesterolText = String(format: "%.1f", reading.displayHDLCholesterol(unit: cholesterolUnit))

        if let ldl = reading.ldlCholesterol {
            hasLDL = true
            ldlCholesterolText = String(format: "%.1f", cholesterolUnit.fromMgdL(ldl))
        }

        if let trig = reading.triglycerides {
            hasTriglycerides = true
            triglyceridesText = String(format: "%.1f", triglycerideUnit.fromMgdL(trig))
        }

        timestamp = reading.timestamp
    }

    private func saveReading() {
        guard let total = totalCholesterol, let hdl = hdlCholesterol else { return }

        // Convert from display units to mg/dL for storage
        let totalInMgdL = cholesterolUnit.toMgdL(total)
        let hdlInMgdL = cholesterolUnit.toMgdL(hdl)
        let ldlInMgdL: Double? = hasLDL && ldlCholesterol != nil ? cholesterolUnit.toMgdL(ldlCholesterol!) : nil
        let trigInMgdL: Double? = hasTriglycerides && triglycerides != nil ? triglycerideUnit.toMgdL(triglycerides!) : nil

        if let reading = readingToEdit {
            // Update existing reading
            reading.totalCholesterol = totalInMgdL
            reading.hdlCholesterol = hdlInMgdL
            reading.ldlCholesterol = ldlInMgdL
            reading.triglycerides = trigInMgdL
            reading.timestamp = timestamp
        } else {
            // Create new reading
            let reading = LipidReading(
                totalCholesterol: totalInMgdL,
                hdlCholesterol: hdlInMgdL,
                ldlCholesterol: ldlInMgdL,
                triglycerides: trigInMgdL,
                timestamp: timestamp
            )
            modelContext.insert(reading)
        }

        // Explicitly save to persist immediately
        do {
            try modelContext.save()
        } catch {
            print("Failed to save lipid reading: \(error)")
        }

        showingSaveConfirmation = true
    }

    private func deleteReading() {
        if let reading = readingToEdit {
            modelContext.delete(reading)
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete lipid reading: \(error)")
            }
            dismiss()
        }
    }
}

#Preview {
    LipidEntryView()
        .modelContainer(for: [LipidReading.self, UserProfile.self], inMemory: true)
}
