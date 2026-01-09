import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BPReading.timestamp, order: .reverse) private var readings: [BPReading]

    @State private var showingTrendChart = false

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

struct ReadingRow: View {
    let reading: BPReading

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(reading.systolic)/\(reading.diastolic)")
                    .font(.headline)

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
            }
        }
        .padding(.vertical, 4)
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
