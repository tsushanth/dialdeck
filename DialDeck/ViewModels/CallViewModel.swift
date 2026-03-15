//
//  CallViewModel.swift
//  DialDeck
//

import Foundation
import SwiftData

@MainActor
@Observable
final class CallViewModel {
    // Call session state
    var selectedProspect: Prospect? = nil
    var selectedScript: CallScript? = nil
    var callOutcome: CallOutcome = .noAnswer
    var callNotes: String = ""
    var nextSteps: String = ""
    var objectionHandled: String = ""
    var followUpDate: Date? = nil
    var callSentiment: CallSentiment = .neutral
    var isSchedulingFollowUp: Bool = false
    var isShowingScriptPicker: Bool = false
    var isShowingObjectionGuide: Bool = false
    var isCallActive: Bool = false

    var callTracker: CallTracker { CallTracker.shared }

    // Recent logs
    var recentLogs: [CallLog] = []
    var logSearchQuery: String = ""

    var formattedCallDuration: String {
        let duration = callTracker.callDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func startCall() {
        callTracker.startCall()
        isCallActive = true
    }

    func endAndLogCall(context: ModelContext) {
        isCallActive = false
        callTracker.logCall(
            prospect: selectedProspect,
            outcome: callOutcome,
            notes: callNotes,
            nextSteps: nextSteps,
            scriptUsed: selectedScript?.title ?? "",
            objectionHandled: objectionHandled,
            sentiment: callSentiment,
            followUpDate: followUpDate,
            context: context
        )

        // Schedule follow-up notification if needed
        if isSchedulingFollowUp, let followUpDate {
            let followUp = FollowUp(
                prospect: selectedProspect,
                title: "Follow up with \(selectedProspect?.fullName ?? "prospect")",
                notes: nextSteps,
                scheduledDate: followUpDate
            )
            context.insert(followUp)
            try? context.save()
            Task { await NotificationManager.shared.scheduleFollowUpReminder(for: followUp) }
        }

        // Update script usage
        if let script = selectedScript {
            script.usageCount += 1
            try? context.save()
            AnalyticsService.shared.track(.scriptUsed)
        }

        resetCallSession()
    }

    func resetCallSession() {
        callNotes = ""
        nextSteps = ""
        objectionHandled = ""
        followUpDate = nil
        callSentiment = .neutral
        callOutcome = .noAnswer
        isSchedulingFollowUp = false
    }

    func filteredLogs(_ logs: [CallLog]) -> [CallLog] {
        guard !logSearchQuery.isEmpty else { return logs }
        let q = logSearchQuery.lowercased()
        return logs.filter {
            $0.prospectName.lowercased().contains(q) ||
            $0.prospectCompany.lowercased().contains(q) ||
            $0.outcome.rawValue.lowercased().contains(q)
        }
    }
}
