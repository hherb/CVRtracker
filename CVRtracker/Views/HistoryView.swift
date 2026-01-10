import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BPReading.timestamp, order: .reverse) private var readings: [BPReading]

    @State private var showingTrendChart = false
    @State private var readingToEdit: BPReading?

    var body: some View {
        NavigationStack {
            Group {
                if readings.isEmpty {
                    emptyState
                } else {
                    readingsList
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !readings.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingTrendChart = true
                        } label: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingTrendChart) {
                TrendChartView()
            }
            .sheet(item: $readingToEdit) { reading in
                NavigationStack {
                    BPEntryView(readingToEdit: reading)
                        .navigationTitle("Edit Reading")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    readingToEdit = nil
                                }
                            }
                        }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Readings", systemImage: "heart.text.square")
        } description: {
            Text("Add your first blood pressure reading to start tracking your vascular health.")
        }
    }

    private var readingsList: some View {
        List {
            ForEach(readings) { reading in
                ReadingRow(reading: reading)
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

struct ReadingRow: View {
    let reading: BPReading

    var body: some View {
        HStack {
            // BP Category indicator
            bpCategoryIndicator

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(reading.systolic)/\(reading.diastolic)")
                        .font(.headline)

                    // Show warning for urgent readings
                    if reading.bpCategory.isUrgent {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(reading.bpCategory.color)
                            .font(.caption)
                    }
                }

                Text(reading.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(reading.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.3f", reading.fractionalPulsePressure))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorForFPP(reading.fractionalPulsePressure))

                Text("fPP")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Show BP category label for non-normal readings
                if reading.bpCategory != .normal {
                    Text(reading.bpCategory.rawValue)
                        .font(.caption2)
                        .foregroundColor(reading.bpCategory.color)
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// Colored indicator showing BP category
    private var bpCategoryIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(reading.bpCategory.color)
            .frame(width: 4)
            .padding(.vertical, 2)
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
}

#Preview {
    HistoryView()
        .modelContainer(for: BPReading.self, inMemory: true)
}
