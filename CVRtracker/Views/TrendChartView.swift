import SwiftUI
import SwiftData
import Charts

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All"

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .all: return nil
        }
    }
}

struct TrendChartView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BPReading.timestamp, order: .forward) private var allReadings: [BPReading]

    @State private var selectedRange: TimeRange = .month

    private var filteredReadings: [BPReading] {
        guard let days = selectedRange.days else {
            return allReadings
        }

        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return allReadings.filter { $0.timestamp >= cutoff }
    }

    private var averageFPP: Double {
        guard !filteredReadings.isEmpty else { return 0 }
        let sum = filteredReadings.reduce(0) { $0 + $1.fractionalPulsePressure }
        return sum / Double(filteredReadings.count)
    }

    private var minFPP: Double {
        filteredReadings.map { $0.fractionalPulsePressure }.min() ?? 0
    }

    private var maxFPP: Double {
        filteredReadings.map { $0.fractionalPulsePressure }.max() ?? 0
    }

    private var trend: String {
        guard filteredReadings.count >= 2 else { return "Not enough data" }
        let firstHalf = Array(filteredReadings.prefix(filteredReadings.count / 2))
        let secondHalf = Array(filteredReadings.suffix(filteredReadings.count / 2))

        let firstAvg = firstHalf.reduce(0) { $0 + $1.fractionalPulsePressure } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0) { $0 + $1.fractionalPulsePressure } / Double(secondHalf.count)

        if secondAvg < firstAvg - 0.01 {
            return "Improving"
        } else if secondAvg > firstAvg + 0.01 {
            return "Worsening"
        } else {
            return "Stable"
        }
    }

    private var trendColor: Color {
        switch trend {
        case "Improving": return .green
        case "Worsening": return .red
        default: return .orange
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Main Chart
                    if filteredReadings.isEmpty {
                        ContentUnavailableView {
                            Label("No Data", systemImage: "chart.line.downtrend.xyaxis")
                        } description: {
                            Text("No readings in this time period.")
                        }
                        .frame(height: 300)
                    } else {
                        chartView
                            .frame(height: 300)
                            .padding()
                    }

                    // Statistics
                    if !filteredReadings.isEmpty {
                        statisticsView
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("fPP Trend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var chartView: some View {
        Chart {
            ForEach(filteredReadings, id: \.id) { reading in
                LineMark(
                    x: .value("Date", reading.timestamp),
                    y: .value("fPP", reading.fractionalPulsePressure)
                )
                .foregroundStyle(.red)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", reading.timestamp),
                    y: .value("fPP", reading.fractionalPulsePressure)
                )
                .foregroundStyle(colorForFPP(reading.fractionalPulsePressure))
                .symbolSize(40)
            }

            // Normal threshold line
            RuleMark(y: .value("Normal Threshold", 0.4))
                .foregroundStyle(.green.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Normal < 0.40")
                        .font(.caption2)
                        .foregroundColor(.green)
                }

            // Elevated threshold line
            RuleMark(y: .value("Elevated Threshold", 0.5))
                .foregroundStyle(.orange.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Elevated < 0.50")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
        }
        .chartYScale(domain: (min(minFPP - 0.05, 0.3))...(max(maxFPP + 0.05, 0.55)))
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }

    private var statisticsView: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.headline)

            HStack(spacing: 0) {
                statItem(title: "Average", value: String(format: "%.3f", averageFPP))
                Divider()
                statItem(title: "Lowest", value: String(format: "%.3f", minFPP))
                Divider()
                statItem(title: "Highest", value: String(format: "%.3f", maxFPP))
                Divider()
                VStack(spacing: 4) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trend)
                        .font(.headline)
                        .foregroundColor(trendColor)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 60)

            Text("\(filteredReadings.count) readings in selected period")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .padding(.horizontal)
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
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
    TrendChartView()
        .modelContainer(for: BPReading.self, inMemory: true)
}
