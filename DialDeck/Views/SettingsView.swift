//
//  SettingsView.swift
//  DialDeck
//

import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var context
    @Query private var metrics: [CallMetrics]

    @AppStorage("com.appfactory.dialdeck.dailyGoal") private var dailyGoal = 50
    @AppStorage("com.appfactory.dialdeck.dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("com.appfactory.dialdeck.reminderHour") private var reminderHour = 9

    @State private var showPaywall = false
    @State private var showResetConfirm = false
    @State private var notificationManager = NotificationManager.shared

    var body: some View {
        NavigationStack {
            List {
                // Premium section
                Section {
                    if premiumManager.isPremium {
                        HStack {
                            Image(systemName: "crown.fill").foregroundColor(.yellow)
                            Text("DialDeck Pro Active")
                                .font(.headline)
                            Spacer()
                            Text("Active")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(8)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill").foregroundColor(.yellow)
                                VStack(alignment: .leading) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Unlimited prospects, analytics & more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Call settings
                Section("Call Goals") {
                    HStack {
                        Text("Daily Call Goal")
                        Spacer()
                        Stepper("\(dailyGoal)", value: $dailyGoal, in: 5...500, step: 5)
                    }
                }

                // Notifications
                Section("Notifications") {
                    Toggle("Daily Reminder", isOn: $dailyReminderEnabled)
                        .onChange(of: dailyReminderEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await notificationManager.requestAuthorization()
                                    if granted {
                                        await notificationManager.scheduleDailyCallGoalReminder(hour: reminderHour)
                                    } else {
                                        dailyReminderEnabled = false
                                    }
                                }
                            } else {
                                notificationManager.cancelAllReminders()
                            }
                        }

                    if dailyReminderEnabled {
                        Picker("Reminder Time", selection: $reminderHour) {
                            ForEach(6..<22, id: \.self) { hour in
                                let display = Calendar.current.date(from: DateComponents(hour: hour, minute: 0)).map {
                                    DateFormatter().apply { $0.timeStyle = .short }.string(from: $0)
                                } ?? "\(hour):00"
                                Text(display).tag(hour)
                            }
                        }
                        .onChange(of: reminderHour) { _, hour in
                            if dailyReminderEnabled {
                                Task { await notificationManager.scheduleDailyCallGoalReminder(hour: hour) }
                            }
                        }
                    }
                }

                // App info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Button {
                        if let url = URL(string: "https://dialdeck.app/privacy") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square").foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Button {
                        if let url = URL(string: "https://dialdeck.app/terms") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square").foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Button {
                        Task { await premiumManager.storeKitManager.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                    }
                }

                // Data
                Section("Data") {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .confirmationDialog(
                "Reset All Data",
                isPresented: $showResetConfirm
            ) {
                Button("Reset Everything", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your prospects, call logs, scripts, and metrics. This cannot be undone.")
            }
        }
    }

    private func resetAllData() {
        do {
            try context.delete(model: Prospect.self)
            try context.delete(model: CallLog.self)
            try context.delete(model: CallScript.self)
            try context.delete(model: Objection.self)
            try context.delete(model: FollowUp.self)
            try context.delete(model: CallMetrics.self)
            try context.save()
        } catch {
            print("[Settings] Failed to reset data: \(error)")
        }
    }
}

// MARK: - DateFormatter Helper
extension DateFormatter {
    @discardableResult
    func apply(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}

#Preview {
    SettingsView()
        .environment(PremiumManager())
        .modelContainer(for: [CallMetrics.self, Prospect.self], inMemory: true)
}
