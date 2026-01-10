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

/// Direction of a trend over time
enum TrendDirection {
    case increasing
    case stable
    case decreasing
    case insufficient

    var symbol: String {
        switch self {
        case .increasing: return "↑"
        case .stable: return "→"
        case .decreasing: return "↓"
        case .insufficient: return "—"
        }
    }
}

/// Interpretation of combined pulse pressure and MAP trends
struct TrendInterpretation {
    let category: Category
    let title: String
    let description: String
    let color: Color

    enum Category {
        case bestScenario
        case good
        case neutral
        case needsAttention
        case concerning
        case mostConcerning
        case insufficient
    }

    static func interpret(ppTrend: TrendDirection, mapTrend: TrendDirection) -> TrendInterpretation {
        // Handle insufficient data
        if ppTrend == .insufficient || mapTrend == .insufficient {
            return TrendInterpretation(
                category: .insufficient,
                title: "Not Enough Data",
                description: "Continue tracking to see trend analysis.",
                color: .secondary
            )
        }

        // PP Decreasing scenarios (generally good for arterial health)
        if ppTrend == .decreasing {
            switch mapTrend {
            case .decreasing:
                return TrendInterpretation(
                    category: .bestScenario,
                    title: "Excellent Progress",
                    description: "Both your arterial stiffness and overall blood pressure are improving. This is the ideal response to treatment or lifestyle changes.",
                    color: .green
                )
            case .stable:
                return TrendInterpretation(
                    category: .good,
                    title: "Good Progress",
                    description: "Your arterial flexibility is improving while blood pressure remains stable. Your arteries are becoming healthier.",
                    color: .green
                )
            case .increasing:
                return TrendInterpretation(
                    category: .needsAttention,
                    title: "Mixed Results",
                    description: "Your arterial stiffness is improving, but overall blood pressure is rising. Discuss this pattern with your doctor.",
                    color: .orange
                )
            case .insufficient:
                return TrendInterpretation(category: .insufficient, title: "", description: "", color: .secondary)
            }
        }

        // PP Stable scenarios
        if ppTrend == .stable {
            switch mapTrend {
            case .decreasing:
                return TrendInterpretation(
                    category: .good,
                    title: "Blood Pressure Improving",
                    description: "Your blood pressure is decreasing while arterial stiffness remains stable. Your small arteries are relaxing.",
                    color: .green
                )
            case .stable:
                return TrendInterpretation(
                    category: .neutral,
                    title: "Stable Readings",
                    description: "Both metrics are stable. This is fine if your values are healthy, or may indicate a need for treatment adjustments.",
                    color: .blue
                )
            case .increasing:
                return TrendInterpretation(
                    category: .concerning,
                    title: "Blood Pressure Rising",
                    description: "Your blood pressure is increasing without improvement in arterial flexibility. Consider lifestyle changes or consult your doctor.",
                    color: .orange
                )
            case .insufficient:
                return TrendInterpretation(category: .insufficient, title: "", description: "", color: .secondary)
            }
        }

        // PP Increasing scenarios (concerning for arterial health)
        if ppTrend == .increasing {
            switch mapTrend {
            case .decreasing:
                return TrendInterpretation(
                    category: .concerning,
                    title: "Arterial Stiffening",
                    description: "Despite lower overall pressure, your arteries are becoming stiffer. This paradoxical pattern may indicate progressive arterial disease.",
                    color: .orange
                )
            case .stable:
                return TrendInterpretation(
                    category: .concerning,
                    title: "Increasing Arterial Stress",
                    description: "Your pulse pressure is rising, meaning more pressure waves are reaching your organs without cushioning. Monitor closely.",
                    color: .orange
                )
            case .increasing:
                return TrendInterpretation(
                    category: .mostConcerning,
                    title: "Worsening Trend",
                    description: "Both arterial stiffness and blood pressure are increasing. This double burden requires attention—consult your healthcare provider.",
                    color: .red
                )
            case .insufficient:
                return TrendInterpretation(category: .insufficient, title: "", description: "", color: .secondary)
            }
        }

        // Fallback
        return TrendInterpretation(
            category: .neutral,
            title: "Stable",
            description: "Your readings are relatively stable.",
            color: .blue
        )
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

    // MARK: - Trend Analysis

    /// Trend direction for pulse pressure
    private var ppTrend: TrendDirection {
        guard filteredReadings.count >= 2 else { return .insufficient }
        let firstHalf = Array(filteredReadings.prefix(filteredReadings.count / 2))
        let secondHalf = Array(filteredReadings.suffix(filteredReadings.count / 2))

        let firstAvg = firstHalf.reduce(0) { $0 + Double($1.pulsePressure) } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0) { $0 + Double($1.pulsePressure) } / Double(secondHalf.count)

        let change = secondAvg - firstAvg
        if change < -2 {
            return .decreasing
        } else if change > 2 {
            return .increasing
        } else {
            return .stable
        }
    }

    /// Trend direction for mean arterial pressure
    private var mapTrend: TrendDirection {
        guard filteredReadings.count >= 2 else { return .insufficient }
        let firstHalf = Array(filteredReadings.prefix(filteredReadings.count / 2))
        let secondHalf = Array(filteredReadings.suffix(filteredReadings.count / 2))

        let firstAvg = firstHalf.reduce(0) { $0 + $1.meanArterialPressure } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0) { $0 + $1.meanArterialPressure } / Double(secondHalf.count)

        let change = secondAvg - firstAvg
        if change < -3 {
            return .decreasing
        } else if change > 3 {
            return .increasing
        } else {
            return .stable
        }
    }

    /// Legacy fPP trend for backward compatibility
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

    /// Comprehensive trend interpretation based on PP and MAP changes
    private var trendInterpretation: TrendInterpretation {
        TrendInterpretation.interpret(ppTrend: ppTrend, mapTrend: mapTrend)
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
            // Statistics card
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

            // Trend interpretation card
            trendInterpretationCard
        }
        .padding(.horizontal)
    }

    private var trendInterpretationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForInterpretation(trendInterpretation.category))
                    .foregroundColor(trendInterpretation.color)
                    .font(.title2)

                Text(trendInterpretation.title)
                    .font(.headline)
                    .foregroundColor(trendInterpretation.color)

                Spacer()

                InfoButton(topic: HelpContent.interpretingTrends)
            }

            Text(trendInterpretation.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Show component trends
            if trendInterpretation.category != .insufficient {
                Divider()

                HStack(spacing: 20) {
                    trendIndicator(label: "Pulse Pressure", trend: ppTrend)
                    trendIndicator(label: "Mean Pressure", trend: mapTrend)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private func trendIndicator(label: String, trend: TrendDirection) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Text(trend.symbol)
                    .font(.headline)
                Text(trendLabel(for: trend))
                    .font(.caption)
            }
            .foregroundColor(colorForTrendDirection(trend))
        }
    }

    private func trendLabel(for trend: TrendDirection) -> String {
        switch trend {
        case .increasing: return "Rising"
        case .stable: return "Stable"
        case .decreasing: return "Falling"
        case .insufficient: return "—"
        }
    }

    private func colorForTrendDirection(_ trend: TrendDirection) -> Color {
        switch trend {
        case .increasing: return .red
        case .stable: return .blue
        case .decreasing: return .green
        case .insufficient: return .secondary
        }
    }

    private func iconForInterpretation(_ category: TrendInterpretation.Category) -> String {
        switch category {
        case .bestScenario: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .neutral: return "equal.circle.fill"
        case .needsAttention: return "exclamationmark.circle.fill"
        case .concerning: return "exclamationmark.triangle.fill"
        case .mostConcerning: return "exclamationmark.octagon.fill"
        case .insufficient: return "questionmark.circle"
        }
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
