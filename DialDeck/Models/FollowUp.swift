//
//  FollowUp.swift
//  DialDeck
//

import Foundation
import SwiftData

@Model
final class FollowUp {
    var id: UUID
    var title: String
    var notes: String
    var scheduledDate: Date
    var isCompleted: Bool
    var completedAt: Date?
    var priority: FollowUpPriority
    var type: FollowUpType
    var createdAt: Date

    var prospect: Prospect?

    init(
        prospect: Prospect? = nil,
        title: String,
        notes: String = "",
        scheduledDate: Date,
        priority: FollowUpPriority = .medium,
        type: FollowUpType = .call
    ) {
        self.id = UUID()
        self.prospect = prospect
        self.title = title
        self.notes = notes
        self.scheduledDate = scheduledDate
        self.isCompleted = false
        self.priority = priority
        self.type = type
        self.createdAt = Date()
    }

    var isOverdue: Bool {
        !isCompleted && scheduledDate < Date()
    }

    var isDueToday: Bool {
        !isCompleted && Calendar.current.isDateInToday(scheduledDate)
    }

    var isDueTomorrow: Bool {
        !isCompleted && Calendar.current.isDateInTomorrow(scheduledDate)
    }
}

enum FollowUpPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

enum FollowUpType: String, Codable, CaseIterable {
    case call = "Call"
    case email = "Email"
    case meeting = "Meeting"
    case text = "Text"
    case linkedIn = "LinkedIn"
    case demo = "Demo"
    case proposal = "Proposal"

    var icon: String {
        switch self {
        case .call: return "phone.fill"
        case .email: return "envelope.fill"
        case .meeting: return "calendar"
        case .text: return "message.fill"
        case .linkedIn: return "link"
        case .demo: return "play.rectangle.fill"
        case .proposal: return "doc.fill"
        }
    }
}
