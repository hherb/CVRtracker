import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \BPReading.timestamp, order: .reverse) private var readings: [BPReading]

    @State private var age: Int = 50
    @State private var sex: Sex = .male
    @State private var totalCholesterol: Double = 200
    @State private var hdlCholesterol: Double = 50
    @State private var onHypertensionTreatment: Bool = false
    @State private var isSmoker: Bool = false
    @State private var hasDiabetes: Bool = false

    @State private var showingRiskResult = false

    private var profile: UserProfile? {
        profiles.first
    }

    private var latestReading: BPReading? {
        readings.first
    }

    private var canCalculateRisk: Bool {
        age >= 30 && age <= 79 && totalCholesterol > 0 && hdlCholesterol > 0 && latestReading != nil
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
                    HStack {
                        Text("Total Cholesterol")
                        Spacer()
                        TextField("mg/dL", value: $totalCholesterol, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: totalCholesterol) { saveProfile() }
                        Text("mg/dL")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("HDL Cholesterol")
                        Spacer()
                        TextField("mg/dL", value: $hdlCholesterol, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: hdlCholesterol) { saveProfile() }
                        Text("mg/dL")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Cholesterol")
                } footer: {
                    Text("Enter your most recent lab values. Higher HDL (\"good\" cholesterol) is protective.")
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
                if let reading = latestReading {
                    RiskResultView(
                        profile: createCurrentProfile(),
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
            totalCholesterol = existing.totalCholesterol
            hdlCholesterol = existing.hdlCholesterol
            onHypertensionTreatment = existing.onHypertensionTreatment
            isSmoker = existing.isSmoker
            hasDiabetes = existing.hasDiabetes
        }
    }

    private func saveProfile() {
        if let existing = profile {
            existing.age = age
            existing.sex = sex
            existing.totalCholesterol = totalCholesterol
            existing.hdlCholesterol = hdlCholesterol
            existing.onHypertensionTreatment = onHypertensionTreatment
            existing.isSmoker = isSmoker
            existing.hasDiabetes = hasDiabetes
        } else {
            let newProfile = UserProfile(
                age: age,
                sex: sex,
                totalCholesterol: totalCholesterol,
                hdlCholesterol: hdlCholesterol,
                onHypertensionTreatment: onHypertensionTreatment,
                isSmoker: isSmoker,
                hasDiabetes: hasDiabetes
            )
            modelContext.insert(newProfile)
        }
    }

    private func createCurrentProfile() -> UserProfile {
        UserProfile(
            age: age,
            sex: sex,
            totalCholesterol: totalCholesterol,
            hdlCholesterol: hdlCholesterol,
            onHypertensionTreatment: onHypertensionTreatment,
            isSmoker: isSmoker,
            hasDiabetes: hasDiabetes
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, BPReading.self], inMemory: true)
}
