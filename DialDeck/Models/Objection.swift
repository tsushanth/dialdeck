//
//  Objection.swift
//  DialDeck
//

import Foundation
import SwiftData

@Model
final class Objection {
    var id: UUID
    var title: String
    var category: ObjectionCategory
    var objectionText: String
    var responses: [String]
    var tips: [String]
    var isFavorite: Bool
    var usageCount: Int
    var createdAt: Date
    var isCustom: Bool

    init(
        title: String,
        category: ObjectionCategory,
        objectionText: String,
        responses: [String] = [],
        tips: [String] = [],
        isFavorite: Bool = false,
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.objectionText = objectionText
        self.responses = responses
        self.tips = tips
        self.isFavorite = isFavorite
        self.usageCount = 0
        self.createdAt = Date()
        self.isCustom = isCustom
    }
}

enum ObjectionCategory: String, Codable, CaseIterable {
    case price = "Price"
    case timing = "Timing"
    case authority = "Authority"
    case need = "Need"
    case trust = "Trust"
    case competition = "Competition"
    case status = "Status Quo"
    case other = "Other"

    var icon: String {
        switch self {
        case .price: return "dollarsign.circle"
        case .timing: return "clock"
        case .authority: return "person.badge.shield.checkmark"
        case .need: return "questionmark.circle"
        case .trust: return "shield.lefthalf.filled"
        case .competition: return "figure.2.arms.open"
        case .status: return "arrow.2.squarepath"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Default Objections
extension Objection {
    static func defaultObjections() -> [Objection] {
        [
            Objection(
                title: "Too Expensive",
                category: .price,
                objectionText: "That's too expensive / We don't have budget for that.",
                responses: [
                    "I understand budget is always a consideration. Can I ask — what is the cost of NOT solving [problem] each month?",
                    "That's fair. Let me ask you this: if the ROI were 3x within 6 months, would it be worth exploring?",
                    "Many of our clients felt the same way before they saw the numbers. Can I share what the typical payback period looks like?"
                ],
                tips: [
                    "Never apologize for your pricing",
                    "Reframe cost as an investment",
                    "Quantify the cost of the status quo"
                ]
            ),
            Objection(
                title: "Not a Good Time",
                category: .timing,
                objectionText: "It's not a good time / Call me back next quarter.",
                responses: [
                    "I completely understand. Just so I can be more helpful when I follow up — what's making this a tough time right now?",
                    "That makes sense. When would be the ideal time, and what would need to change between now and then?",
                    "I hear you. The reason I'm reaching out now is [specific reason - quarter ending, market shift]. Would 5 minutes help me understand if this is even relevant?"
                ],
                tips: [
                    "Understand if it's a brush-off or genuine timing issue",
                    "Set a concrete callback date",
                    "Give them a reason to talk now"
                ]
            ),
            Objection(
                title: "Not the Decision Maker",
                category: .authority,
                objectionText: "I'm not the one who makes these decisions / You need to talk to my boss.",
                responses: [
                    "I appreciate you telling me that. Could you help me understand who the best person would be, and what their priorities usually are?",
                    "That's helpful. Would you be willing to make a brief introduction? I'll keep it short.",
                    "Got it. What typically drives decision-making in your organization for something like this?"
                ],
                tips: [
                    "Get a referral, not just a name",
                    "Understand the buying process",
                    "Make this person your internal champion"
                ]
            ),
            Objection(
                title: "We're Happy With Current Solution",
                category: .status,
                objectionText: "We already have something / We're happy with what we have.",
                responses: [
                    "That's great to hear — what do you like most about your current solution?",
                    "A lot of our best clients felt the same way before we showed them [differentiator]. What's working best and what, if anything, would you improve?",
                    "I'm glad it's working. What would have to be true for you to consider switching or adding something?"
                ],
                tips: [
                    "Find the cracks in the current solution",
                    "Don't attack their existing vendor",
                    "Plant seeds for future opportunities"
                ]
            ),
            Objection(
                title: "Send Me Information",
                category: .other,
                objectionText: "Just send me an email / Send me some information.",
                responses: [
                    "Absolutely, I'd love to. To make sure I send the most relevant info, can I ask you two quick questions?",
                    "Of course. What specifically would be most useful for you to see?",
                    "Happy to. If the information addresses [their concern], what would be the next step on your end?"
                ],
                tips: [
                    "This is often a polite brush-off",
                    "Get commitment to a follow-up call when sending",
                    "Make the email targeted, not generic"
                ]
            ),
            Objection(
                title: "We Use a Competitor",
                category: .competition,
                objectionText: "We already work with [Competitor] / We're under contract with someone else.",
                responses: [
                    "I'm familiar with them — they do some things well. Out of curiosity, what made you choose them originally?",
                    "Understood. When does your contract come up for renewal? I'd love to be in the conversation at that point.",
                    "That makes sense. A few of our clients actually switched from them because of [key differentiator]. Would it be worth a quick comparison?"
                ],
                tips: [
                    "Know your competitors' weaknesses",
                    "Never badmouth the competition",
                    "Focus on what you do uniquely better"
                ]
            )
        ]
    }
}
