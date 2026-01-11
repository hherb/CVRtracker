import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @StateObject private var iCloudManager = iCloudSyncManager.shared
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
    @State private var healthKitEnabled: Bool = false
    @State private var iCloudSyncEnabled: Bool = false

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
                    HStack {
                        Toggle("On blood pressure medication", isOn: $onHypertensionTreatment)
                            .onChange(of: onHypertensionTreatment) { saveProfile() }
                        InfoButton(topic: HelpContent.hypertensionTreatment)
                    }

                    HStack {
                        Toggle("Current smoker", isOn: $isSmoker)
                            .onChange(of: isSmoker) { saveProfile() }
                        InfoButton(topic: HelpContent.smokingStatus)
                    }

                    HStack {
                        Toggle("Diabetes", isOn: $hasDiabetes)
                            .onChange(of: hasDiabetes) { saveProfile() }
                        InfoButton(topic: HelpContent.diabetesStatus)
                    }
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

                if healthKitManager.isAvailable {
                    Section {
                        HStack {
                            Toggle("Apple Health Sync", isOn: $healthKitEnabled)
                                .onChange(of: healthKitEnabled) { _, newValue in
                                    Task {
                                        await handleHealthKitToggle(enabled: newValue)
                                    }
                                }
                            InfoButton(topic: HelpContent.appleHealthIntegration)
                        }

                        if healthKitEnabled {
                            HStack {
                                Text("Status")
                                Spacer()
                                syncStatusView
                            }

                            Button("Sync Now") {
                                Task {
                                    await healthKitManager.syncBPReadings(with: modelContext)
                                }
                            }
                            .disabled(healthKitManager.syncStatus == .syncing)

                            if let heartRate = healthKitManager.latestHeartRate {
                                HStack {
                                    Label("Heart Rate", systemImage: "heart.fill")
                                        .foregroundColor(.red)
                                    Spacer()
                                    Text("\(heartRate.bpm) BPM")
                                        .foregroundColor(.secondary)
                                    Text(heartRate.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Apple Health")
                    } footer: {
                        Text("Sync blood pressure readings with Apple Health. Heart rate is read-only from Apple Watch or other devices.")
                    }
                }

                Section {
                    HStack {
                        Toggle("iCloud Sync", isOn: $iCloudSyncEnabled)
                            .onChange(of: iCloudSyncEnabled) { _, newValue in
                                if newValue {
                                    iCloudManager.enableSync()
                                } else {
                                    iCloudManager.disableSync()
                                }
                            }
                        InfoButton(topic: HelpContent.iCloudSync)
                    }

                    if !iCloudManager.isAvailable && iCloudSyncEnabled {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Sign in to iCloud in Settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if iCloudManager.pendingRestart {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(.blue)
                            Text("Restart app to apply changes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if iCloudSyncEnabled && iCloudManager.isAvailable && !iCloudManager.pendingRestart {
                        HStack {
                            Text("Status")
                            Spacer()
                            iCloudSyncStatusView
                        }
                    }
                } header: {
                    Text("iCloud")
                } footer: {
                    if iCloudSyncEnabled {
                        Text("Your data syncs automatically across all devices signed into your iCloud account.")
                    } else {
                        Text("Enable to sync your data between iPhone and iPad. Your data stays private in your iCloud account.")
                    }
                }

                if let lipid = latestLipidReading {
                    Section {
                        HStack {
                            LabelWithInfo(text: "Total Cholesterol", topic: HelpContent.totalCholesterol)
                            Spacer()
                            Text(String(format: "%.0f %@",
                                         lipid.displayTotalCholesterol(unit: cholesterolUnit),
                                         cholesterolUnit.rawValue))
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            LabelWithInfo(text: "HDL Cholesterol", topic: HelpContent.hdlCholesterol)
                            Spacer()
                            Text(String(format: "%.0f %@",
                                         lipid.displayHDLCholesterol(unit: cholesterolUnit),
                                         cholesterolUnit.rawValue))
                                .foregroundColor(.secondary)
                        }
                        if let ldl = lipid.displayLDLCholesterol(unit: cholesterolUnit) {
                            HStack {
                                LabelWithInfo(text: "LDL Cholesterol", topic: HelpContent.ldlCholesterol)
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
            healthKitEnabled = existing.healthKitEnabled
        }
        // iCloud sync is stored in UserDefaults, not in the profile
        iCloudSyncEnabled = iCloudManager.isEnabled
        // Clear pending restart flag since app has restarted
        iCloudManager.clearPendingRestart()
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
            existing.healthKitEnabled = healthKitEnabled
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
            newProfile.healthKitEnabled = healthKitEnabled
            modelContext.insert(newProfile)
        }

        // Explicitly save to persist immediately
        do {
            try modelContext.save()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }

    private func handleHealthKitToggle(enabled: Bool) async {
        if enabled {
            let authorized = await healthKitManager.requestAuthorization()
            if authorized {
                saveProfile()
                await healthKitManager.syncBPReadings(with: modelContext)
            } else {
                healthKitEnabled = false
            }
        } else {
            saveProfile()
        }
    }

    @ViewBuilder
    private var syncStatusView: some View {
        switch healthKitManager.syncStatus {
        case .idle:
            Text("Ready")
                .foregroundColor(.secondary)
        case .syncing:
            ProgressView()
                .controlSize(.small)
        case .completed(let count):
            if count > 0 {
                Text("\(count) imported")
                    .foregroundColor(.green)
            } else {
                Text("Up to date")
                    .foregroundColor(.green)
            }
        case .error(let message):
            Text(message)
                .foregroundColor(.red)
                .font(.caption)
        }
    }

    @ViewBuilder
    private var iCloudSyncStatusView: some View {
        switch iCloudManager.syncStatus {
        case .idle:
            Text("Ready")
                .foregroundColor(.secondary)
        case .syncing:
            ProgressView()
                .controlSize(.small)
        case .synced:
            Text("Synced")
                .foregroundColor(.green)
        case .error(let message):
            Text(message)
                .foregroundColor(.red)
                .font(.caption)
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
        .environmentObject(HealthKitManager())
        .modelContainer(for: [UserProfile.self, BPReading.self, LipidReading.self], inMemory: true)
}
