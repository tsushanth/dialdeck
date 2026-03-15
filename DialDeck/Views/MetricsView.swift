//
//  MetricsView.swift
//  DialDeck
//

import SwiftUI
import SwiftData
import Charts

struct MetricsView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var context
    @Query(sort: \CallMetrics.date, order: .reverse) private var metrics: [CallMetrics]
    @Query private var allLogs: [CallLog]
    @Query private var allProspects: [Prospect]

    @State private var viewModel = MetricsViewModel()
    @State private var showPaywall = false
    @State private var showExportSheet = false
    @State private var exportURL: URL? = nil

    private var todayMetrics: CallMetrics? {
        metrics.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                        ForEach(MetricsViewModel.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Summary cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(
                            title: "Total Calls",
                            value: "\(viewModel.totalCallsForRange(metrics))",
                            icon: "phone.fill",
                            color: .blue
                        )
                        MetricCard(
                            title: "Connected",
                            value: "\(viewModel.totalConnectedForRange(metrics))",
                            icon: "person.fill.checkmark",
                            color: .green
                        )
                        MetricCard(
                            title: "Connect Rate",
                            value: String(format: "%.1f%%", viewModel.connectionRateForRange(metrics) * 100),
                            icon: "waveform.path.ecg",
                            color: .teal
                        )
                        MetricCard(
                            title: "Conversions",
                            value: "\(viewModel.totalConversionsForRange(metrics))",
                            icon: "checkmark.seal.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    // Streak card
                    StreakCard(streak: viewModel.streak(from: metrics))

                    // Chart
                    if premiumManager.isPremium {
                        CallActivityChart(data: viewModel.chartData(from: metrics))
                    } else {
                        LockedChartView { showPaywall = true }
                    }

                    // Today's breakdown
                    if let today = todayMetrics {
                        TodayBreakdownCard(metrics: today)
                    }

                    // Outcome breakdown
                    OutcomeBreakdownCard(logs: allLogs)

                    // Prospect stats
                    ProspectStatsCard(prospects: allProspects)

                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .navigationTitle("Metrics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if premiumManager.isPremium {
                            viewModel.generateExport(
                                prospects: allProspects,
                                logs: allLogs,
                                metrics: metrics
                            )
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingExport) {
                ExportSheet(content: viewModel.exportContent)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                AnalyticsService.shared.track(.metricsViewed)
            }
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 16) {
            Text("🔥")
                .font(.system(size: 48))
            VStack(alignment: .leading, spacing: 4) {
                Text("\(streak) Day Streak")
                    .font(.title2.bold())
                Text("Keep making calls every day to maintain your streak!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.orange.opacity(0.12), Color.red.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Call Activity Chart
struct CallActivityChart: View {
    let data: [(date: String, calls: Int, connected: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Call Activity")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(data.indices, id: \.self) { i in
                    BarMark(
                        x: .value("Date", data[i].date),
                        y: .value("Calls", data[i].calls)
                    )
                    .foregroundStyle(Color.blue.opacity(0.6))

                    BarMark(
                        x: .value("Date", data[i].date),
                        y: .value("Connected", data[i].connected)
                    )
                    .foregroundStyle(Color.green.opacity(0.8))
                }
            }
            .frame(height: 180)
            .padding(.horizontal)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.blue.opacity(0.6)).frame(width: 16, height: 10)
                    Text("Total").font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.green.opacity(0.8)).frame(width: 16, height: 10)
                    Text("Connected").font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Locked Chart View
struct LockedChartView: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 220)

            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
                Text("Advanced Charts")
                    .font(.headline)
                Text("Unlock with Pro to see detailed activity charts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Unlock Pro", action: onUnlock)
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Today Breakdown Card
struct TodayBreakdownCard: View {
    let metrics: CallMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Breakdown")
                .font(.headline)
            Divider()
            BreakdownRow(label: "Connected", value: metrics.connectedCalls, total: metrics.totalCalls, color: .green)
            BreakdownRow(label: "Voicemails", value: metrics.voicemails, total: metrics.totalCalls, color: .orange)
            BreakdownRow(label: "No Answer", value: metrics.noAnswers, total: metrics.totalCalls, color: .red)
            Divider()
            HStack {
                Text("Talk Time")
                    .foregroundColor(.secondary)
                Spacer()
                Text(metrics.formattedTalkTime)
                    .bold()
            }
            HStack {
                Text("Avg Duration")
                    .foregroundColor(.secondary)
                Spacer()
                let avgMin = Int(metrics.avgCallDuration) / 60
                let avgSec = Int(metrics.avgCallDuration) % 60
                Text("\(avgMin)m \(avgSec)s").bold()
            }
        }
        .font(.subheadline)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct BreakdownRow: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color

    var pct: Double { total > 0 ? Double(value) / Double(total) : 0 }

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            ProgressView(value: pct)
                .progressViewStyle(.linear)
                .tint(color)
            Text("\(value)")
                .bold()
                .frame(width: 30, alignment: .trailing)
            Text(String(format: "(%.0f%%)", pct * 100))
                .foregroundColor(.secondary)
                .frame(width: 46, alignment: .leading)
        }
    }
}

// MARK: - Outcome Breakdown Card
struct OutcomeBreakdownCard: View {
    let logs: [CallLog]

    var outcomeCounts: [(outcome: CallOutcome, count: Int)] {
        var counts: [CallOutcome: Int] = [:]
        for log in logs { counts[log.outcome, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    var body: some View {
        if !outcomeCounts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("All-Time Outcome Distribution")
                    .font(.headline)
                ForEach(outcomeCounts.prefix(5), id: \.outcome) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.outcome.icon)
                            .foregroundColor(item.outcome.isPositive ? .green : .secondary)
                            .frame(width: 20)
                        Text(item.outcome.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count)")
                            .font(.subheadline.bold())
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// MARK: - Prospect Stats Card
struct ProspectStatsCard: View {
    let prospects: [Prospect]

    var statusCounts: [(status: ProspectStatus, count: Int)] {
        var counts: [ProspectStatus: Int] = [:]
        for p in prospects { counts[p.status, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    var body: some View {
        if !prospects.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pipeline Overview")
                    .font(.headline)
                ForEach(statusCounts, id: \.status) { item in
                    HStack {
                        Image(systemName: item.status.icon)
                            .frame(width: 20)
                        Text(item.status.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count)")
                            .font(.subheadline.bold())
                        Text(String(format: "%.0f%%", Double(item.count) / Double(prospects.count) * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// MARK: - Export Sheet
struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let content: String
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Export Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let tempURL = ExportService.shared.writeCSVToFile(content, filename: "dialdeck_export")
                        if let url = tempURL {
                            shareItems = [url]
                            showShareSheet = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    MetricsView()
        .environment(PremiumManager())
        .modelContainer(for: [CallMetrics.self, CallLog.self, Prospect.self], inMemory: true)
}
