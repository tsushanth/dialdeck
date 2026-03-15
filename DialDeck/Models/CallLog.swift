//
//  CallLog.swift
//  DialDeck
//

import Foundation
import SwiftData

@Model
final class CallLog {
    var id: UUID
    var prospectName: String
    var prospectCompany: String
    var outcome: CallOutcome
    var duration: TimeInterval
    var notes: String
    var calledAt: Date
    var followUpDate: Date?
    var scriptUsed: String
    var objectionHandled: String
    var nextSteps: String
    var sentiment: CallSentiment

    var prospect: Prospect?

    init(
        prospect: Prospect? = nil,
        outcome: CallOutcome = .noAnswer,
        duration: TimeInterval = 0,
        notes: String = "",
        calledAt: Date = Date(),
        followUpDate: Date? = nil,
        scriptUsed: String = "",
        objectionHandled: String = "",
        nextSteps: String = "",
        sentiment: CallSentiment = .neutral
    ) {
        self.id = UUID()
        self.prospect = prospect
        self.prospectName = prospect?.fullName ?? ""
        self.prospectCompany = prospect?.company ?? ""
        self.outcome = outcome
        self.duration = duration
        self.notes = notes
        self.calledAt = calledAt
        self.followUpDate = followUpDate
        self.scriptUsed = scriptUsed
        self.objectionHandled = objectionHandled
        self.nextSteps = nextSteps
        self.sentiment = sentiment
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var isConnected: Bool {
        outcome == .connected || outcome == .converted || outcome == .leftVoicemail
    }
}

enum CallOutcome: String, Codable, CaseIterable {
    case noAnswer = "No Answer"
    case voicemail = "Voicemail"
    case leftVoicemail = "Left Voicemail"
    case connected = "Connected"
    case converted = "Converted"
    case notInterested = "Not Interested"
    case callBack = "Call Back"
    case wrongNumber = "Wrong Number"
    case busy = "Busy"
    case doNotCall = "Do Not Call"

    var icon: String {
        switch self {
        case .noAnswer: return "phone.slash"
        case .voicemail: return "voicemail"
        case .leftVoicemail: return "voicemail.badge.minus"
        case .connected: return "phone.fill"
        case .converted: return "checkmark.seal.fill"
        case .notInterested: return "xmark.circle.fill"
        case .callBack: return "arrow.clockwise.circle.fill"
        case .wrongNumber: return "exclamationmark.triangle.fill"
        case .busy: return "phone.slash.fill"
        case .doNotCall: return "nosign"
        }
    }

    var isPositive: Bool {
        self == .connected || self == .converted || self == .leftVoicemail || self == .callBack
    }
}

enum CallSentiment: String, Codable, CaseIterable {
    case veryPositive = "Very Positive"
    case positive = "Positive"
    case neutral = "Neutral"
    case negative = "Negative"
    case veryNegative = "Very Negative"

    var emoji: String {
        switch self {
        case .veryPositive: return "😄"
        case .positive: return "🙂"
        case .neutral: return "😐"
        case .negative: return "🙁"
        case .veryNegative: return "😠"
        }
    }

    var value: Int {
        switch self {
        case .veryPositive: return 5
        case .positive: return 4
        case .neutral: return 3
        case .negative: return 2
        case .veryNegative: return 1
        }
    }
}
