//
//  MetricsAnalytics.swift
//  DialDeck
//

import Foundation
import SwiftData

@MainActor
final class MetricsAnalytics {
    static let shared = MetricsAnalytics()
    private init() {}

    struct WeeklySummary {
        var totalCalls: Int
        var connectedCalls: Int
        var conversions: Int
        var talkTime: TimeInterval
        var connectionRate: Double
        var conversionRate: Double
        var bestDay: String
        var worstDay: String
    }

    struct MonthlySummary {
        var totalCalls: Int
        var connectedCalls: Int
        var conversions: Int
        var avgDailyCalls: Double
        var totalTalkTime: TimeInterval
        var bestWeek: Int
    }

    func weeklySummary(from metrics: [CallMetrics]) -> WeeklySummary {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = metrics.filter { $0.date >= sevenDaysAgo }

        let total = recent.reduce(0) { $0 + $1.totalCalls }
        let connected = recent.reduce(0) { $0 + $1.connectedCalls }
        let conversions = recent.reduce(0) { $0 + $1.conversions }
        let talkTime = recent.reduce(0.0) { $0 + $1.totalTalkTime }

        let bestDay = recent.max(by: { $0.totalCalls < $1.totalCalls })
        let worstDay = recent.min(by: { $0.totalCalls < $1.totalCalls })

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return WeeklySummary(
            totalCalls: total,
            connectedCalls: connected,
            conversions: conversions,
            talkTime: talkTime,
            connectionRate: total > 0 ? Double(connected) / Double(total) : 0,
            conversionRate: connected > 0 ? Double(conversions) / Double(connected) : 0,
            bestDay: bestDay.map { formatter.string(from: $0.date) } ?? "N/A",
            worstDay: worstDay.map { formatter.string(from: $0.date) } ?? "N/A"
        )
    }

    func monthlySummary(from metrics: [CallMetrics]) -> MonthlySummary {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recent = metrics.filter { $0.date >= thirtyDaysAgo }

        let total = recent.reduce(0) { $0 + $1.totalCalls }
        let connected = recent.reduce(0) { $0 + $1.connectedCalls }
        let conversions = recent.reduce(0) { $0 + $1.conversions }
        let talkTime = recent.reduce(0.0) { $0 + $1.totalTalkTime }
        let avgDaily = recent.isEmpty ? 0 : Double(total) / Double(recent.count)

        // Find best week
        var weekBuckets: [Int: Int] = [:]
        for m in recent {
            let week = Calendar.current.component(.weekOfYear, from: m.date)
            weekBuckets[week, default: 0] += m.totalCalls
        }
        let bestWeek = weekBuckets.max(by: { $0.value < $1.value })?.key ?? 0

        return MonthlySummary(
            totalCalls: total,
            connectedCalls: connected,
            conversions: conversions,
            avgDailyCalls: avgDaily,
            totalTalkTime: talkTime,
            bestWeek: bestWeek
        )
    }

    func callStreak(from metrics: [CallMetrics], goalPerDay: Int = 1) -> Int {
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())

        let sorted = metrics.sorted { $0.date > $1.date }

        for _ in 0..<365 {
            let dayMetrics = sorted.first { Calendar.current.isDate($0.date, inSameDayAs: checkDate) }
            if let m = dayMetrics, m.totalCalls >= goalPerDay {
                streak += 1
            } else if streak > 0 {
                break
            }
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        return streak
    }

    func chartData(from metrics: [CallMetrics], days: Int = 7) -> [(date: String, calls: Int, connected: Int)] {
        let startDate = Calendar.current.date(byAdding: .day, value: -(days - 1), to: Calendar.current.startOfDay(for: Date())) ?? Date()

        let formatter = DateFormatter()
        formatter.dateFormat = days <= 7 ? "EEE" : "M/d"

        return (0..<days).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: startDate) ?? startDate
            let m = metrics.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
            return (
                date: formatter.string(from: date),
                calls: m?.totalCalls ?? 0,
                connected: m?.connectedCalls ?? 0
            )
        }
    }
}
