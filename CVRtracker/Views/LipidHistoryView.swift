import SwiftUI
import SwiftData
import Charts

struct LipidHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LipidReading.timestamp, order: .reverse) private var readings: [LipidReading]
    @Query private var profiles: [UserProfile]

    @State private var showingAddLipid = false
    @State private var showingChart = false

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
            Group {
                if readings.isEmpty {
                    emptyState
                } else {
                    readingsList
                }
            }
            .navigationTitle("Lipids")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if readings.count >= 2 {
                            Button {
                                showingChart = true
                            } label: {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                            }
                        }
                        Button {
                            showingAddLipid = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddLipid) {
                LipidEntryView()
            }
            .sheet(isPresented: $showingChart) {
                LipidChartView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Lipid Readings", systemImage: "drop.fill")
        } description: {
            Text("Add your first lipid panel to start tracking your cholesterol levels.")
        } actions: {
            Button {
                showingAddLipid = true
            } label: {
                Text("Add Lipid Reading")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var readingsList: some View {
        List {
            ForEach(readings) { reading in
                LipidReadingRow(
                    reading: reading,
                    cholesterolUnit: cholesterolUnit,
                    triglycerideUnit: triglycerideUnit
                )
            }
            .onDelete(perform: deleteReadings)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteReadings(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(readings[index])
            }
        }
    }
}

struct LipidReadingRow: View {
    let reading: LipidReading
    let cholesterolUnit: CholesterolUnit
    let triglycerideUnit: TriglycerideUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reading.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f", reading.totalHDLRatio))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorForRatio(reading.totalHDLRatio))
                    Text("TC/HDL")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 16) {
                lipidValue(
                    label: "Total",
                    value: reading.displayTotalCholesterol(unit: cholesterolUnit),
                    unit: cholesterolUnit.rawValue
                )

                lipidValue(
                    label: "HDL",
                    value: reading.displayHDLCholesterol(unit: cholesterolUnit),
                    unit: cholesterolUnit.rawValue
                )

                if let ldl = reading.displayLDLCholesterol(unit: cholesterolUnit) {
                    lipidValue(
                        label: "LDL",
                        value: ldl,
                        unit: cholesterolUnit.rawValue
                    )
                }

                if let trig = reading.displayTriglycerides(unit: triglycerideUnit) {
                    lipidValue(
                        label: "Trig",
                        value: trig,
                        unit: triglycerideUnit.rawValue
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func lipidValue(label: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private func colorForRatio(_ ratio: Double) -> Color {
        if ratio < 3.5 {
            return .green
        } else if ratio < 5.0 {
            return .orange
        } else {
            return .red
        }
    }
}

struct LipidChartView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \LipidReading.timestamp, order: .forward) private var readings: [LipidReading]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? {
        profiles.first
    }

    private var cholesterolUnit: CholesterolUnit {
        profile?.cholesterolUnit ?? .mgdL
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Total Cholesterol Chart
                    chartSection(title: "Total Cholesterol") {
                        Chart {
                            ForEach(readings, id: \.id) { reading in
                                LineMark(
                                    x: .value("Date", reading.timestamp),
                                    y: .value("Total", reading.displayTotalCholesterol(unit: cholesterolUnit))
                                )
                                .foregroundStyle(.blue)
                                .symbol(Circle())
                            }
                        }
                        .frame(height: 180)
                    }

                    // HDL Chart
                    chartSection(title: "HDL Cholesterol") {
                        Chart {
                            ForEach(readings, id: \.id) { reading in
                                LineMark(
                                    x: .value("Date", reading.timestamp),
                                    y: .value("HDL", reading.displayHDLCholesterol(unit: cholesterolUnit))
                                )
                                .foregroundStyle(.green)
                                .symbol(Circle())
                            }
                        }
                        .frame(height: 180)
                    }

                    // TC/HDL Ratio Chart
                    chartSection(title: "Total/HDL Ratio") {
                        Chart {
                            ForEach(readings, id: \.id) { reading in
                                LineMark(
                                    x: .value("Date", reading.timestamp),
                                    y: .value("Ratio", reading.totalHDLRatio)
                                )
                                .foregroundStyle(.purple)
                                .symbol(Circle())
                            }

                            RuleMark(y: .value("Target", 3.5))
                                .foregroundStyle(.green.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
                        .frame(height: 180)
                    }
                }
                .padding()
            }
            .navigationTitle("Lipid Trends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func chartSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

#Preview {
    LipidHistoryView()
        .modelContainer(for: [LipidReading.self, UserProfile.self], inMemory: true)
}
