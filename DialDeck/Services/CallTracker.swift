//
//  CallTracker.swift
//  DialDeck
//

import Foundation
import SwiftData

@MainActor
@Observable
final class CallTracker {
    static let shared = CallTracker()

    var isCallActive: Bool = false
    var callStartTime: Date?
    var callDuration: TimeInterval = 0
    private var timer: Timer?

    private init() {}

    func startCall() {
        isCallActive = true
        callStartTime = Date()
        callDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.callStartTime else { return }
                self.callDuration = Date().timeIntervalSince(start)
            }
        }
    }

    func endCall() -> TimeInterval {
        isCallActive = false
        timer?.invalidate()
        timer = nil
        let duration = callDuration
        callDuration = 0
        callStartTime = nil
        return duration
    }

    func logCall(
        prospect: Prospect?,
        outcome: CallOutcome,
        notes: String,
        nextSteps: String,
        scriptUsed: String,
        objectionHandled: String,
        sentiment: CallSentiment,
        followUpDate: Date?,
        context: ModelContext
    ) {
        let duration = endCall()
        let log = CallLog(
            prospect: prospect,
            outcome: outcome,
            duration: duration,
            notes: notes,
            calledAt: Date(),
            followUpDate: followUpDate,
            scriptUsed: scriptUsed,
            objectionHandled: objectionHandled,
            nextSteps: nextSteps,
            sentiment: sentiment
        )
        context.insert(log)

        // Update prospect status
        if let prospect {
            prospect.lastContactedAt = Date()
            switch outcome {
            case .converted: prospect.status = .converted
            case .notInterested, .doNotCall: prospect.status = .notInterested
            case .callBack: prospect.status = .followUp
            case .connected: prospect.status = .contacted
            default: break
            }
        }

        try? context.save()

        // Track analytics
        AnalyticsService.shared.track(.callLogged(outcome: outcome.rawValue))

        // Update daily metrics
        updateDailyMetrics(outcome: outcome, duration: duration, context: context)
    }

    private func updateDailyMetrics(outcome: CallOutcome, duration: TimeInterval, context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<CallMetrics>()

        guard let allMetrics = try? context.fetch(descriptor) else { return }
        let todayMetrics = allMetrics.first { Calendar.current.isDate($0.date, inSameDayAs: today) }

        let metrics = todayMetrics ?? {
            let m = CallMetrics(date: today)
            context.insert(m)
            return m
        }()

        metrics.totalCalls += 1
        metrics.totalTalkTime += duration

        switch outcome {
        case .connected, .converted: metrics.connectedCalls += 1
        case .voicemail, .leftVoicemail: metrics.voicemails += 1
        case .noAnswer: metrics.noAnswers += 1
        default: break
        }

        if outcome == .converted { metrics.conversions += 1 }
        if metrics.totalCalls > 0 {
            metrics.avgCallDuration = metrics.totalTalkTime / Double(metrics.totalCalls)
        }

        if metrics.totalCalls >= metrics.goalCalls {
            AnalyticsService.shared.track(.dailyGoalReached)
        }

        try? context.save()
    }
}
