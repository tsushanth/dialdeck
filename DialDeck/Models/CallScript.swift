//
//  CallScript.swift
//  DialDeck
//

import Foundation
import SwiftData

@Model
final class CallScript {
    var id: UUID
    var title: String
    var category: ScriptCategory
    var intro: String
    var valueProposition: String
    var questions: [String]
    var closingStatement: String
    var talkingPoints: [String]
    var tags: [String]
    var isTemplate: Bool
    var isFavorite: Bool
    var usageCount: Int
    var createdAt: Date
    var updatedAt: Date
    var industry: String
    var estimatedDurationMinutes: Int

    init(
        title: String,
        category: ScriptCategory = .coldCall,
        intro: String = "",
        valueProposition: String = "",
        questions: [String] = [],
        closingStatement: String = "",
        talkingPoints: [String] = [],
        tags: [String] = [],
        isTemplate: Bool = false,
        isFavorite: Bool = false,
        industry: String = "",
        estimatedDurationMinutes: Int = 5
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.intro = intro
        self.valueProposition = valueProposition
        self.questions = questions
        self.closingStatement = closingStatement
        self.talkingPoints = talkingPoints
        self.tags = tags
        self.isTemplate = isTemplate
        self.isFavorite = isFavorite
        self.usageCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
        self.industry = industry
        self.estimatedDurationMinutes = estimatedDurationMinutes
    }

    var fullScript: String {
        var parts: [String] = []
        if !intro.isEmpty { parts.append("INTRO:\n\(intro)") }
        if !valueProposition.isEmpty { parts.append("VALUE PROP:\n\(valueProposition)") }
        if !talkingPoints.isEmpty {
            parts.append("TALKING POINTS:\n" + talkingPoints.enumerated().map { "  \($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        }
        if !questions.isEmpty {
            parts.append("DISCOVERY QUESTIONS:\n" + questions.enumerated().map { "  \($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        }
        if !closingStatement.isEmpty { parts.append("CLOSE:\n\(closingStatement)") }
        return parts.joined(separator: "\n\n")
    }
}

enum ScriptCategory: String, Codable, CaseIterable {
    case coldCall = "Cold Call"
    case followUp = "Follow Up"
    case discovery = "Discovery"
    case demo = "Demo"
    case closing = "Closing"
    case objectionHandling = "Objection Handling"
    case referral = "Referral"
    case reEngagement = "Re-Engagement"

    var icon: String {
        switch self {
        case .coldCall: return "phone.arrow.up.right"
        case .followUp: return "arrow.clockwise"
        case .discovery: return "magnifyingglass"
        case .demo: return "play.rectangle"
        case .closing: return "checkmark.seal"
        case .objectionHandling: return "shield"
        case .referral: return "person.badge.plus"
        case .reEngagement: return "arrow.2.circlepath"
        }
    }
}

// MARK: - Default Templates
extension CallScript {
    static func defaultTemplates() -> [CallScript] {
        [
            {
                let s = CallScript(
                    title: "Classic Cold Call Opener",
                    category: .coldCall,
                    intro: "Hi [Name], this is [Your Name] from [Company]. I know I'm calling out of the blue, so I'll be brief.",
                    valueProposition: "We help [target industry] companies [specific outcome] without [common pain point]. I was wondering if that's something you're currently focused on?",
                    questions: [
                        "How are you currently handling [problem area]?",
                        "What does your current process look like for [task]?",
                        "What would it mean for your team if you could [desired outcome]?"
                    ],
                    closingStatement: "Based on what you've shared, I think there's a strong fit here. Can we schedule 15 minutes next week to explore this further?",
                    talkingPoints: [
                        "Quick, respectful of their time",
                        "Lead with value, not features",
                        "Listen 70%, talk 30%"
                    ],
                    isTemplate: true,
                    estimatedDurationMinutes: 5
                )
                return s
            }(),
            {
                let s = CallScript(
                    title: "SaaS Follow-Up Script",
                    category: .followUp,
                    intro: "Hi [Name], it's [Your Name] from [Company]. We spoke [X days] ago about [topic].",
                    valueProposition: "I wanted to follow up because [reason - new info, their timeline, etc.]. Have you had a chance to think about what we discussed?",
                    questions: [
                        "Where are you in the decision-making process?",
                        "Has anything changed since we last spoke?",
                        "What would you need to see to feel confident moving forward?"
                    ],
                    closingStatement: "I'd love to keep the momentum going. Are you free for 20 minutes this week to dig deeper?",
                    talkingPoints: [
                        "Reference previous conversation",
                        "Add new value or information",
                        "Move toward a clear next step"
                    ],
                    isTemplate: true,
                    estimatedDurationMinutes: 8
                )
                return s
            }(),
            {
                let s = CallScript(
                    title: "Executive-Level Opening",
                    category: .coldCall,
                    intro: "Hi [Name], [Your Name] at [Company]. I'll get straight to the point.",
                    valueProposition: "We've helped companies like [similar client] achieve [specific result] in [timeframe]. I wanted to explore whether that's relevant to your priorities right now.",
                    questions: [
                        "What's your biggest operational challenge this quarter?",
                        "How are you thinking about [strategic area]?",
                        "If you could change one thing about your current [process], what would it be?"
                    ],
                    closingStatement: "I don't want to take more of your time. Can we book 20 minutes to look at this more concretely?",
                    talkingPoints: [
                        "Be direct and confident",
                        "Lead with business outcomes",
                        "Use peer company references"
                    ],
                    isTemplate: true,
                    estimatedDurationMinutes: 6
                )
                return s
            }()
        ]
    }
}
