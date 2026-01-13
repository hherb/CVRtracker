import SwiftUI
import SwiftData
import Charts

struct LipidHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LipidReading.timestamp, order: .reverse) private var readings: [LipidReading]
    @Query private var profiles: [UserProfile]

    @State private var showingAddLipid = false
    @State private var showingChart = false
    @State private var readingToEdit: LipidReading?

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
            .sheet(item: $readingToEdit) { reading in
                LipidEntryView(readingToEdit: reading)
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
                .contentShape(Rectangle())
                .onTapGesture {
                    readingToEdit = reading
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        modelContext.delete(reading)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        readingToEdit = reading
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }

            // Medical Disclaimer section
            Section {
                CompactMedicalDisclaimer()
            }
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
                    Text(reading.totalHDLRatioCategory.description)
                        .font(.caption2)
                        .foregroundColor(colorForRatio(reading.totalHDLRatio))
                }
            }

            HStack(spacing: 12) {
                lipidValueWithHint(
                    label: "Total",
                    value: reading.displayTotalCholesterol(unit: cholesterolUnit),
                    hint: reading.totalCholesterolCategory.hint,
                    color: colorForTotalCholesterol(reading.totalCholesterolCategory)
                )

                lipidValueWithHint(
                    label: "HDL",
                    value: reading.displayHDLCholesterol(unit: cholesterolUnit),
                    hint: reading.hdlCategory.hint,
                    color: colorForHDL(reading.hdlCategory)
                )

                if let ldl = reading.displayLDLCholesterol(unit: cholesterolUnit),
                   let ldlCat = reading.ldlCategory {
                    lipidValueWithHint(
                        label: "LDL",
                        value: ldl,
                        hint: ldlCat.hint,
                        color: colorForLDL(ldlCat)
                    )
                }

                if let trig = reading.displayTriglycerides(unit: triglycerideUnit),
                   let trigCat = reading.triglyceridesCategory {
                    lipidValueWithHint(
                        label: "Trig",
                        value: trig,
                        hint: trigCat.hint,
                        color: colorForTriglycerides(trigCat)
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func lipidValueWithHint(label: String, value: Double, hint: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(String(format: "%.1f", value))
                .font(.subheadline)
                .fontWeight(.medium)
            Text(hint)
                .font(.caption2)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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

    private func colorForTotalCholesterol(_ category: TotalCholesterolCategory) -> Color {
        switch category {
        case .desirable: return .green
        case .borderline: return .orange
        case .high: return .red
        }
    }

    private func colorForHDL(_ category: HDLCholesterolCategory) -> Color {
        switch category {
        case .low: return .red
        case .acceptable: return .orange
        case .optimal: return .green
        }
    }

    private func colorForLDL(_ category: LDLCholesterolCategory) -> Color {
        switch category {
        case .optimal, .nearOptimal: return .green
        case .borderline: return .orange
        case .high, .veryHigh: return .red
        }
    }

    private func colorForTriglycerides(_ category: TriglyceridesCategory) -> Color {
        switch category {
        case .normal: return .green
        case .borderline: return .orange
        case .high, .veryHigh: return .red
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
