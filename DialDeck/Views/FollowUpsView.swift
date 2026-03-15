//
//  FollowUpsView.swift
//  DialDeck
//

import SwiftUI
import SwiftData

struct FollowUpsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FollowUp.scheduledDate) private var followUps: [FollowUp]
    @Query private var prospects: [Prospect]

    @State private var showAddFollowUp = false
    @State private var selectedFollowUp: FollowUp? = nil
    @State private var showCompleted = false

    var activeFollowUps: [FollowUp] {
        followUps.filter { !$0.isCompleted }
    }

    var completedFollowUps: [FollowUp] {
        followUps.filter { $0.isCompleted }
    }

    var overdueCount: Int {
        activeFollowUps.filter { $0.isOverdue }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if followUps.isEmpty {
                    EmptyFollowUpsView { showAddFollowUp = true }
                } else {
                    List {
                        if overdueCount > 0 {
                            Section {
                                ForEach(activeFollowUps.filter { $0.isOverdue }) { fu in
                                    FollowUpRow(followUp: fu, onComplete: { completeFollowUp(fu) })
                                }
                            } header: {
                                Label("Overdue (\(overdueCount))", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                        }

                        let todayItems = activeFollowUps.filter { $0.isDueToday }
                        if !todayItems.isEmpty {
                            Section("Due Today") {
                                ForEach(todayItems) { fu in
                                    FollowUpRow(followUp: fu, onComplete: { completeFollowUp(fu) })
                                }
                            }
                        }

                        let upcomingItems = activeFollowUps.filter { !$0.isOverdue && !$0.isDueToday }
                        if !upcomingItems.isEmpty {
                            Section("Upcoming") {
                                ForEach(upcomingItems) { fu in
                                    FollowUpRow(followUp: fu, onComplete: { completeFollowUp(fu) })
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                context.delete(fu)
                                                try? context.save()
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }

                        if showCompleted && !completedFollowUps.isEmpty {
                            Section("Completed") {
                                ForEach(completedFollowUps.prefix(20)) { fu in
                                    FollowUpRow(followUp: fu, onComplete: nil)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Follow-Ups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddFollowUp = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { showCompleted.toggle() }
                    } label: {
                        Text(showCompleted ? "Hide Done" : "Show Done")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showAddFollowUp) {
                AddFollowUpView(prospects: prospects)
            }
        }
    }

    private func completeFollowUp(_ followUp: FollowUp) {
        withAnimation {
            followUp.isCompleted = true
            followUp.completedAt = Date()
            try? context.save()
        }
        AnalyticsService.shared.track(.followUpCompleted)
    }
}

// MARK: - Follow Up Row
struct FollowUpRow: View {
    let followUp: FollowUp
    let onComplete: (() -> Void)?

    var priorityColor: Color {
        switch followUp.priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var dateColor: Color {
        if followUp.isOverdue { return .red }
        if followUp.isDueToday { return .orange }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 12) {
            // Complete button
            if let onComplete {
                Button(action: onComplete) {
                    Image(systemName: followUp.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(followUp.isCompleted ? .green : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }

            // Icon
            Image(systemName: followUp.type.icon)
                .foregroundColor(priorityColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(followUp.prospect?.fullName ?? "Unknown Prospect")
                    .font(.subheadline.bold())
                    .strikethrough(followUp.isCompleted)
                Text(followUp.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(followUp.scheduledDate, style: .date)
                    .font(.caption)
                    .foregroundColor(dateColor)
                Text(followUp.type.rawValue)
                    .font(.caption2)
                    .foregroundColor(priorityColor)
            }
        }
        .opacity(followUp.isCompleted ? 0.5 : 1.0)
    }
}

// MARK: - Add Follow Up View
struct AddFollowUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let prospects: [Prospect]

    @State private var selectedProspect: Prospect? = nil
    @State private var title = ""
    @State private var notes = ""
    @State private var scheduledDate = Date().addingTimeInterval(86400)
    @State private var priority: FollowUpPriority = .medium
    @State private var type: FollowUpType = .call

    var body: some View {
        NavigationStack {
            Form {
                Section("Prospect") {
                    Picker("Select Prospect", selection: $selectedProspect) {
                        Text("None").tag(Optional<Prospect>.none)
                        ForEach(prospects) { p in
                            Text(p.fullName).tag(Optional(p))
                        }
                    }
                }
                Section("Details") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(FollowUpType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(FollowUpPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                }
                Section("Schedule") {
                    DatePicker("Date & Time", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Notes") {
                    TextField("Notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Follow-Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let followUp = FollowUp(
                            prospect: selectedProspect,
                            title: title.isEmpty ? "Follow up" : title,
                            notes: notes,
                            scheduledDate: scheduledDate,
                            priority: priority,
                            type: type
                        )
                        context.insert(followUp)
                        try? context.save()
                        Task { await NotificationManager.shared.scheduleFollowUpReminder(for: followUp) }
                        AnalyticsService.shared.track(.followUpCreated)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Empty Follow Ups View
struct EmptyFollowUpsView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Follow-Ups")
                .font(.title2.bold())
            Text("Schedule follow-ups to stay on top of your pipeline")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Follow-Up", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    FollowUpsView()
        .modelContainer(for: [FollowUp.self, Prospect.self], inMemory: true)
}
