//
//  MetricsViewModel.swift
//  DialDeck
//

import Foundation
import SwiftData

@MainActor
@Observable
final class MetricsViewModel {
    var selectedTimeRange: TimeRange = .week
    var isShowingExport: Bool = false
    var exportContent: String = ""
    var dailyGoal: Int = 50

    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
    }

    func todayMetrics(from allMetrics: [CallMetrics]) -> CallMetrics? {
        allMetrics.first { Calendar.current.isDateInToday($0.date) }
    }

    func filteredMetrics(_ all: [CallMetrics]) -> [CallMetrics] {
        let days: Int
        switch selectedTimeRange {
        case .week: days = 7
        case .month: days = 30
        case .quarter: days = 90
        }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return all.filter { $0.date >= cutoff }
    }

    func totalCallsForRange(_ metrics: [CallMetrics]) -> Int {
        filteredMetrics(metrics).reduce(0) { $0 + $1.totalCalls }
    }

    func totalConnectedForRange(_ metrics: [CallMetrics]) -> Int {
        filteredMetrics(metrics).reduce(0) { $0 + $1.connectedCalls }
    }

    func totalConversionsForRange(_ metrics: [CallMetrics]) -> Int {
        filteredMetrics(metrics).reduce(0) { $0 + $1.conversions }
    }

    func connectionRateForRange(_ metrics: [CallMetrics]) -> Double {
        let total = totalCallsForRange(metrics)
        let connected = totalConnectedForRange(metrics)
        guard total > 0 else { return 0 }
        return Double(connected) / Double(total)
    }

    func conversionRateForRange(_ metrics: [CallMetrics]) -> Double {
        let connected = totalConnectedForRange(metrics)
        let conversions = totalConversionsForRange(metrics)
        guard connected > 0 else { return 0 }
        return Double(conversions) / Double(connected)
    }

    func streak(from metrics: [CallMetrics]) -> Int {
        MetricsAnalytics.shared.callStreak(from: metrics, goalPerDay: max(1, dailyGoal / 10))
    }

    func chartData(from metrics: [CallMetrics]) -> [(date: String, calls: Int, connected: Int)] {
        let days: Int
        switch selectedTimeRange {
        case .week: days = 7
        case .month: days = 30
        case .quarter: days = 90
        }
        return MetricsAnalytics.shared.chartData(from: metrics, days: days)
    }

    func generateExport(prospects: [Prospect], logs: [CallLog], metrics: [CallMetrics]) {
        let prospectCSV = ExportService.shared.exportProspectsCSV(prospects: prospects)
        let logsCSV = ExportService.shared.exportCallLogsCSV(logs: logs)
        let metricsCSV = ExportService.shared.exportMetricsCSV(metrics: metrics)
        exportContent = "=== PROSPECTS ===\n\(prospectCSV)\n=== CALL LOGS ===\n\(logsCSV)\n=== METRICS ===\n\(metricsCSV)"
        isShowingExport = true
        AnalyticsService.shared.track(.exportGenerated)
    }
}
