import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \BPReading.timestamp, order: .reverse) private var readings: [BPReading]
    @Query(sort: \LipidReading.timestamp, order: .reverse) private var lipidReadings: [LipidReading]

    @State private var age: Int = 50
    @State private var sex: Sex = .male
    @State private var onHypertensionTreatment: Bool = false
    @State private var isSmoker: Bool = false
    @State private var hasDiabetes: Bool = false
    @State private var cholesterolUnit: CholesterolUnit = .mgdL
    @State private var triglycerideUnit: TriglycerideUnit = .mgdL

    @State private var showingRiskResult = false

    private var profile: UserProfile? {
        profiles.first
    }

    private var latestReading: BPReading? {
        readings.first
    }

    private var latestLipidReading: LipidReading? {
        lipidReadings.first
    }

    private var canCalculateRisk: Bool {
        age >= 30 && age <= 79 && latestLipidReading != nil && latestReading != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Age: \(age) years", value: $age, in: 30...79)
                        .onChange(of: age) { saveProfile() }

                    Picker("Sex", selection: $sex) {
                        ForEach(Sex.allCases, id: \.self) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }
                    .onChange(of: sex) { saveProfile() }
                } header: {
                    Text("Demographics")
                } footer: {
                    Text("Framingham risk calculations are validated for ages 30-79.")
                }

                Section {
                    Toggle("On blood pressure medication", isOn: $onHypertensionTreatment)
                        .onChange(of: onHypertensionTreatment) { saveProfile() }

                    Toggle("Current smoker", isOn: $isSmoker)
                        .onChange(of: isSmoker) { saveProfile() }

                    Toggle("Diabetes", isOn: $hasDiabetes)
                        .onChange(of: hasDiabetes) { saveProfile() }
                } header: {
                    Text("Risk Factors")
                }

                Section {
                    Picker("Cholesterol Units", selection: $cholesterolUnit) {
                        ForEach(CholesterolUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .onChange(of: cholesterolUnit) { saveProfile() }

                    Picker("Triglyceride Units", selection: $triglycerideUnit) {
                        ForEach(TriglycerideUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .onChange(of: triglycerideUnit) { saveProfile() }
                } header: {
                    Text("Unit Preferences")
                } footer: {
                    Text("Choose your preferred units for lipid values. Values are converted automatically.")
                }

                if let lipid = latestLipidReading {
                    Section {
                        HStack {
                            Text("Total Cholesterol")
                            Spacer()
                            Text(String(format: "%.0f %@",
                                         lipid.displayTotalCholesterol(unit: cholesterolUnit),
                                         cholesterolUnit.rawValue))
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("HDL Cholesterol")
                            Spacer()
                            Text(String(format: "%.0f %@",
                                         lipid.displayHDLCholesterol(unit: cholesterolUnit),
                                         cholesterolUnit.rawValue))
                                .foregroundColor(.secondary)
                        }
                        if let ldl = lipid.displayLDLCholesterol(unit: cholesterolUnit) {
                            HStack {
                                Text("LDL Cholesterol")
                                Spacer()
                                Text(String(format: "%.0f %@", ldl, cholesterolUnit.rawValue))
                                    .foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(lipid.timestamp, style: .date)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Latest Lipid Values")
                    } footer: {
                        Text("Lipid values are tracked in the Lipids tab. The latest reading is used for risk calculations.")
                    }
                }

                Section {
                    Button {
                        showingRiskResult = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Calculate CV Risk", systemImage: "heart.text.square")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(!canCalculateRisk)
                } footer: {
                    if latestReading == nil {
                        Text("Add a blood pressure reading first to calculate your risk.")
                    } else if latestLipidReading == nil {
                        Text("Add a lipid reading first to calculate your risk.")
                    } else if !canCalculateRisk {
                        Text("Please complete all required fields.")
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                loadProfile()
            }
            .sheet(isPresented: $showingRiskResult) {
                if let reading = latestReading, let lipid = latestLipidReading {
                    RiskResultView(
                        profile: createCurrentProfile(lipid: lipid),
                        systolicBP: reading.systolic
                    )
                }
            }
        }
    }

    private func loadProfile() {
        if let existing = profile {
            age = existing.age
            sex = existing.sex
            onHypertensionTreatment = existing.onHypertensionTreatment
            isSmoker = existing.isSmoker
            hasDiabetes = existing.hasDiabetes
            cholesterolUnit = existing.cholesterolUnit
            triglycerideUnit = existing.triglycerideUnit
        }
    }

    private func saveProfile() {
        if let existing = profile {
            existing.age = age
            existing.sex = sex
            existing.onHypertensionTreatment = onHypertensionTreatment
            existing.isSmoker = isSmoker
            existing.hasDiabetes = hasDiabetes
            existing.cholesterolUnit = cholesterolUnit
            existing.triglycerideUnit = triglycerideUnit
        } else {
            let newProfile = UserProfile(
                age: age,
                sex: sex,
                totalCholesterol: 0,
                hdlCholesterol: 0,
                onHypertensionTreatment: onHypertensionTreatment,
                isSmoker: isSmoker,
                hasDiabetes: hasDiabetes,
                cholesterolUnit: cholesterolUnit,
                triglycerideUnit: triglycerideUnit
            )
            modelContext.insert(newProfile)
        }
    }

    private func createCurrentProfile(lipid: LipidReading) -> UserProfile {
        UserProfile(
            age: age,
            sex: sex,
            totalCholesterol: lipid.totalCholesterol,
            hdlCholesterol: lipid.hdlCholesterol,
            onHypertensionTreatment: onHypertensionTreatment,
            isSmoker: isSmoker,
            hasDiabetes: hasDiabetes,
            cholesterolUnit: cholesterolUnit,
            triglycerideUnit: triglycerideUnit
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, BPReading.self, LipidReading.self], inMemory: true)
}
