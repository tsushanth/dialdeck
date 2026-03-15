//
//  ExportService.swift
//  DialDeck
//

import Foundation
import SwiftData

@MainActor
final class ExportService {
    static let shared = ExportService()
    private init() {}

    // MARK: - CSV Export

    func exportProspectsCSV(prospects: [Prospect]) -> String {
        var csv = "First Name,Last Name,Company,Phone,Email,Title,Status,Priority,Industry,Last Contacted,Total Calls,Connection Rate,Notes\n"

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none

        for p in prospects {
            let lastContacted = p.lastContactedAt.map { formatter.string(from: $0) } ?? ""
            let connectionRate = String(format: "%.1f%%", p.connectionRate * 100)
            let row = [
                escape(p.firstName),
                escape(p.lastName),
                escape(p.company),
                escape(p.phone),
                escape(p.email),
                escape(p.title),
                escape(p.status.rawValue),
                escape(p.priority.rawValue),
                escape(p.industry),
                escape(lastContacted),
                "\(p.totalCalls)",
                connectionRate,
                escape(p.notes)
            ].joined(separator: ",")
            csv += row + "\n"
        }

        AnalyticsService.shared.track(.exportGenerated)
        return csv
    }

    func exportCallLogsCSV(logs: [CallLog]) -> String {
        var csv = "Date,Prospect Name,Company,Outcome,Duration,Sentiment,Script Used,Objection Handled,Next Steps,Notes\n"

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        for log in logs {
            let row = [
                escape(formatter.string(from: log.calledAt)),
                escape(log.prospectName),
                escape(log.prospectCompany),
                escape(log.outcome.rawValue),
                escape(log.formattedDuration),
                escape(log.sentiment.rawValue),
                escape(log.scriptUsed),
                escape(log.objectionHandled),
                escape(log.nextSteps),
                escape(log.notes)
            ].joined(separator: ",")
            csv += row + "\n"
        }

        return csv
    }

    func exportMetricsCSV(metrics: [CallMetrics]) -> String {
        var csv = "Date,Total Calls,Connected,Voicemails,No Answers,Conversions,Connection Rate,Conversion Rate,Talk Time,Goal,Goal Progress\n"

        let formatter = DateFormatter()
        formatter.dateStyle = .short

        for m in metrics.sorted(by: { $0.date > $1.date }) {
            let row = [
                escape(formatter.string(from: m.date)),
                "\(m.totalCalls)",
                "\(m.connectedCalls)",
                "\(m.voicemails)",
                "\(m.noAnswers)",
                "\(m.conversions)",
                String(format: "%.1f%%", m.connectionRate * 100),
                String(format: "%.1f%%", m.conversionRate * 100),
                escape(m.formattedTalkTime),
                "\(m.goalCalls)",
                String(format: "%.1f%%", m.goalProgress * 100)
            ].joined(separator: ",")
            csv += row + "\n"
        }

        return csv
    }

    // MARK: - File URL

    func writeCSVToFile(_ csv: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(filename).appendingPathExtension("csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("[ExportService] Failed to write CSV: \(error)")
            return nil
        }
    }

    // MARK: - Helpers

    private func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
