//
//  Prospect.swift
//  DialDeck
//

import Foundation
import SwiftData

@Model
final class Prospect {
    var id: UUID
    var firstName: String
    var lastName: String
    var company: String
    var phone: String
    var email: String
    var title: String
    var notes: String
    var status: ProspectStatus
    var priority: ProspectPriority
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var lastContactedAt: Date?
    var linkedInURL: String
    var industry: String

    @Relationship(deleteRule: .cascade, inverse: \CallLog.prospect)
    var callLogs: [CallLog] = []

    @Relationship(deleteRule: .cascade, inverse: \FollowUp.prospect)
    var followUps: [FollowUp] = []

    init(
        firstName: String,
        lastName: String,
        company: String,
        phone: String,
        email: String = "",
        title: String = "",
        notes: String = "",
        status: ProspectStatus = .new,
        priority: ProspectPriority = .medium,
        tags: [String] = [],
        linkedInURL: String = "",
        industry: String = ""
    ) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.phone = phone
        self.email = email
        self.title = title
        self.notes = notes
        self.status = status
        self.priority = priority
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.linkedInURL = linkedInURL
        self.industry = industry
    }

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var initials: String {
        let f = firstName.prefix(1).uppercased()
        let l = lastName.prefix(1).uppercased()
        return "\(f)\(l)"
    }

    var totalCalls: Int { callLogs.count }

    var connectedCalls: Int {
        callLogs.filter { $0.outcome == .connected || $0.outcome == .converted }.count
    }

    var connectionRate: Double {
        guard totalCalls > 0 else { return 0 }
        return Double(connectedCalls) / Double(totalCalls)
    }
}

enum ProspectStatus: String, Codable, CaseIterable {
    case new = "New"
    case contacted = "Contacted"
    case interested = "Interested"
    case notInterested = "Not Interested"
    case followUp = "Follow Up"
    case converted = "Converted"
    case doNotCall = "Do Not Call"

    var color: String {
        switch self {
        case .new: return "blue"
        case .contacted: return "orange"
        case .interested: return "green"
        case .notInterested: return "red"
        case .followUp: return "purple"
        case .converted: return "teal"
        case .doNotCall: return "gray"
        }
    }

    var icon: String {
        switch self {
        case .new: return "star.fill"
        case .contacted: return "phone.fill"
        case .interested: return "hand.thumbsup.fill"
        case .notInterested: return "hand.thumbsdown.fill"
        case .followUp: return "clock.fill"
        case .converted: return "checkmark.seal.fill"
        case .doNotCall: return "phone.slash.fill"
        }
    }
}

enum ProspectPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }
}
