//
//  NotificationManager.swift
//  DialDeck
//

import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    var isAuthorized: Bool = false
    private let center = UNUserNotificationCenter.current()

    private init() {
        Task { await checkAuthorization() }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            print("[NotificationManager] Authorization error: \(error)")
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func scheduleFollowUpReminder(for followUp: FollowUp) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Follow-Up Reminder"
        content.body = "Time to follow up with \(followUp.prospect?.fullName ?? "your prospect")"
        content.sound = .default
        content.userInfo = ["followUpID": followUp.id.uuidString]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: followUp.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: followUp.id.uuidString, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("[NotificationManager] Failed to schedule: \(error)")
        }
    }

    func scheduleDailyCallGoalReminder(hour: Int = 9, minute: Int = 0) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to Hit Your Call Goal!"
        content.body = "Open DialDeck and start dialing. You've got this!"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyCallGoal", content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("[NotificationManager] Failed to schedule daily reminder: \(error)")
        }
    }

    func cancelFollowUpReminder(id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }
}
