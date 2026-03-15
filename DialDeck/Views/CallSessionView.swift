//
//  CallSessionView.swift
//  DialDeck
//

import SwiftUI
import SwiftData

struct CallSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Prospect.updatedAt, order: .reverse) private var prospects: [Prospect]
    @Query(sort: \CallScript.usageCount, order: .reverse) private var scripts: [CallScript]

    @State private var viewModel = CallViewModel()
    var preselectedProspect: Prospect?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Prospect picker
                    ProspectPickerSection(
                        prospects: prospects,
                        selectedProspect: $viewModel.selectedProspect
                    )

                    // Timer & call controls
                    CallTimerSection(viewModel: viewModel)

                    // Script picker
                    ScriptPickerSection(scripts: scripts, selectedScript: $viewModel.selectedScript)

                    // Outcome picker
                    OutcomePickerSection(selectedOutcome: $viewModel.callOutcome)

                    // Sentiment
                    SentimentPickerSection(selectedSentiment: $viewModel.callSentiment)

                    // Notes
                    CallNotesSection(viewModel: viewModel)

                    // Follow-up
                    FollowUpSection(viewModel: viewModel)

                    // Log call button
                    if !viewModel.isCallActive {
                        Button {
                            viewModel.endAndLogCall(context: context)
                            dismiss()
                        } label: {
                            Label("Log Call", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .navigationTitle("Call Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let p = preselectedProspect {
                    viewModel.selectedProspect = p
                }
            }
        }
    }
}

// MARK: - Prospect Picker Section
struct ProspectPickerSection: View {
    let prospects: [Prospect]
    @Binding var selectedProspect: Prospect?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prospect")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button {
                        selectedProspect = nil
                    } label: {
                        Text("Quick Call")
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedProspect == nil ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundColor(selectedProspect == nil ? .white : .primary)
                            .cornerRadius(20)
                    }

                    ForEach(prospects.prefix(10)) { p in
                        Button {
                            selectedProspect = p
                        } label: {
                            HStack(spacing: 6) {
                                Text(p.initials)
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                                Text(p.firstName)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedProspect?.id == p.id ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundColor(selectedProspect?.id == p.id ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Call Timer Section
struct CallTimerSection: View {
    @Bindable var viewModel: CallViewModel

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isCallActive {
                Text(viewModel.formattedCallDuration)
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .foregroundColor(.green)

                Button {
                    _ = viewModel.callTracker.endCall()
                    viewModel.isCallActive = false
                } label: {
                    Label("End Call", systemImage: "phone.down.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(16)
                }
            } else {
                Button {
                    viewModel.startCall()
                } label: {
                    Label("Start Timer", systemImage: "phone.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(16)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Script Picker Section
struct ScriptPickerSection: View {
    let scripts: [CallScript]
    @Binding var selectedScript: CallScript?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Label("Script", systemImage: "doc.text.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if let script = selectedScript {
                        Text(script.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(scripts.prefix(8)) { script in
                            Button {
                                selectedScript = selectedScript?.id == script.id ? nil : script
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(script.title)
                                        .font(.caption.bold())
                                        .lineLimit(2)
                                    Text(script.category.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .frame(width: 130)
                                .background(selectedScript?.id == script.id ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedScript?.id == script.id ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                }

                if let script = selectedScript {
                    ScriptPreviewCard(script: script)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ScriptPreviewCard: View {
    let script: CallScript
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Script Preview")
                    .font(.subheadline.bold())
                Spacer()
                Button(isExpanded ? "Collapse" : "Expand") {
                    withAnimation { isExpanded.toggle() }
                }
                .font(.caption)
            }

            if !script.intro.isEmpty {
                Text("Intro: \(script.intro)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
            }

            if isExpanded {
                if !script.valueProposition.isEmpty {
                    Text("Value Prop: \(script.valueProposition)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !script.closingStatement.isEmpty {
                    Text("Close: \(script.closingStatement)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Outcome Picker Section
struct OutcomePickerSection: View {
    @Binding var selectedOutcome: CallOutcome

    let outcomes: [CallOutcome] = [.connected, .leftVoicemail, .noAnswer, .converted, .notInterested, .callBack, .busy, .wrongNumber]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Outcome")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(outcomes, id: \.self) { outcome in
                    Button {
                        selectedOutcome = outcome
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: outcome.icon)
                                .font(.subheadline)
                            Text(outcome.rawValue)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedOutcome == outcome ? (outcome.isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.1)) : Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedOutcome == outcome ? (outcome.isPositive ? Color.green : Color.red) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Sentiment Picker
struct SentimentPickerSection: View {
    @Binding var selectedSentiment: CallSentiment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Call Sentiment")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 8) {
                ForEach(CallSentiment.allCases, id: \.self) { s in
                    Button {
                        selectedSentiment = s
                    } label: {
                        VStack(spacing: 4) {
                            Text(s.emoji).font(.title2)
                            Text(s.rawValue)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedSentiment == s ? Color.blue.opacity(0.12) : Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedSentiment == s ? Color.blue : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Call Notes Section
struct CallNotesSection: View {
    @Bindable var viewModel: CallViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 10) {
                TextField("Call notes...", text: $viewModel.callNotes, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)

                TextField("Next steps...", text: $viewModel.nextSteps, axis: .vertical)
                    .lineLimit(2...3)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)

                TextField("Objection handled...", text: $viewModel.objectionHandled)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Follow Up Section
struct FollowUpSection: View {
    @Bindable var viewModel: CallViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.isSchedulingFollowUp) {
                Label("Schedule Follow-Up", systemImage: "clock.badge.plus")
                    .font(.headline)
            }
            .padding(.horizontal)

            if viewModel.isSchedulingFollowUp {
                DatePicker(
                    "Follow-Up Date",
                    selection: Binding(
                        get: { viewModel.followUpDate ?? Date().addingTimeInterval(86400) },
                        set: { viewModel.followUpDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    CallSessionView()
        .modelContainer(for: [Prospect.self, CallLog.self, CallScript.self, FollowUp.self, CallMetrics.self], inMemory: true)
}
