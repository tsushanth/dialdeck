//
//  CallMetrics.swift
//  DialDeck
//

import Foundation
import SwiftData

@Model
final class CallMetrics {
    var id: UUID
    var date: Date
    var totalCalls: Int
    var connectedCalls: Int
    var voicemails: Int
    var noAnswers: Int
    var conversions: Int
    var totalTalkTime: TimeInterval
    var goalCalls: Int
    var streak: Int
    var avgCallDuration: TimeInterval
    var bestOutcomeCount: Int

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.totalCalls = 0
        self.connectedCalls = 0
        self.voicemails = 0
        self.noAnswers = 0
        self.conversions = 0
        self.totalTalkTime = 0
        self.goalCalls = 50
        self.streak = 0
        self.avgCallDuration = 0
        self.bestOutcomeCount = 0
    }

    var connectionRate: Double {
        guard totalCalls > 0 else { return 0 }
        return Double(connectedCalls) / Double(totalCalls)
    }

    var conversionRate: Double {
        guard connectedCalls > 0 else { return 0 }
        return Double(conversions) / Double(connectedCalls)
    }

    var goalProgress: Double {
        guard goalCalls > 0 else { return 0 }
        return min(Double(totalCalls) / Double(goalCalls), 1.0)
    }

    var formattedTalkTime: String {
        let hours = Int(totalTalkTime) / 3600
        let minutes = Int(totalTalkTime) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
