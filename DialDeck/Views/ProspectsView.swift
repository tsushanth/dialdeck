//
//  ProspectsView.swift
//  DialDeck
//

import SwiftUI
import SwiftData

struct ProspectsView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var context
    @Query(sort: \Prospect.updatedAt, order: .reverse) private var prospects: [Prospect]

    @State private var viewModel = ProspectViewModel()
    @State private var showAddProspect = false
    @State private var showPaywall = false
    @State private var prospectToDelete: Prospect? = nil
    @State private var showDeleteConfirm = false

    private let freeProspectLimit = 25

    var body: some View {
        NavigationStack {
            Group {
                if prospects.isEmpty {
                    EmptyProspectsView { showAddProspect = true }
                } else {
                    List {
                        ForEach(viewModel.filteredProspects(prospects)) { prospect in
                            NavigationLink(destination: ProspectDetailView(prospect: prospect)) {
                                ProspectListRow(prospect: prospect)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    prospectToDelete = prospect
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    prospect.isFavorite.toggle()
                                    try? context.save()
                                } label: {
                                    Label("Favorite", systemImage: "star.fill")
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Prospects")
            .searchable(text: $viewModel.searchQuery, prompt: "Search name, company, phone")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if !premiumManager.isPremium && prospects.count >= freeProspectLimit {
                            showPaywall = true
                        } else {
                            showAddProspect = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Section("Filter by Status") {
                            Button("All") { viewModel.selectedStatus = nil }
                            ForEach(ProspectStatus.allCases, id: \.self) { status in
                                Button(status.rawValue) { viewModel.selectedStatus = status }
                            }
                        }
                        Section("Sort") {
                            ForEach(ProspectViewModel.SortOption.allCases, id: \.self) { option in
                                Button(option.rawValue) { viewModel.sortOption = option }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddProspect) {
                AddProspectView(viewModel: viewModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .confirmationDialog("Delete prospect?", isPresented: $showDeleteConfirm, presenting: prospectToDelete) { prospect in
                Button("Delete \(prospect.fullName)", role: .destructive) {
                    viewModel.deleteProspect(prospect, context: context)
                }
            }
        }
    }
}

// MARK: - Prospect List Row
struct ProspectListRow: View {
    let prospect: Prospect

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text(prospect.initials)
                    .font(.callout.bold())
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(prospect.fullName)
                        .font(.subheadline.bold())
                    if prospect.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                Text(prospect.company)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(prospect.phone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: prospect.status)
                Text("\(prospect.totalCalls) calls")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Prospects View
struct EmptyProspectsView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Prospects Yet")
                .font(.title2.bold())
            Text("Add your first prospect and start making calls")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Prospect", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Add Prospect View
struct AddProspectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var viewModel: ProspectViewModel

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var company = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: ProspectPriority = .medium
    @State private var industry = ""

    var isValid: Bool {
        !firstName.isEmpty && !phone.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Info") {
                    TextField("First Name *", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Phone *", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
                Section("Company") {
                    TextField("Company", text: $company)
                    TextField("Title/Role", text: $title)
                    TextField("Industry", text: $industry)
                }
                Section("Details") {
                    Picker("Priority", selection: $priority) {
                        ForEach(ProspectPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Prospect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addProspect(
                            firstName: firstName, lastName: lastName,
                            company: company, phone: phone,
                            email: email, title: title, notes: notes,
                            priority: priority, industry: industry, context: context
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Prospect Detail View
struct ProspectDetailView: View {
    @Environment(\.modelContext) private var context
    @State var prospect: Prospect
    @State private var showCallSession = false
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .overlay(Text(prospect.initials).font(.title.bold()).foregroundColor(.blue))
                    Text(prospect.fullName)
                        .font(.title2.bold())
                    Text(prospect.title.isEmpty ? prospect.company : "\(prospect.title) at \(prospect.company)")
                        .foregroundColor(.secondary)
                    StatusBadge(status: prospect.status)
                }
                .padding()

                // Contact buttons
                HStack(spacing: 16) {
                    ContactButton(label: "Call", icon: "phone.fill", color: .green) {
                        showCallSession = true
                    }
                    if let url = URL(string: "sms:\(prospect.phone)") {
                        Link(destination: url) {
                            Label("Text", systemImage: "message.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.blue)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    if !prospect.email.isEmpty, let url = URL(string: "mailto:\(prospect.email)") {
                        Link(destination: url) {
                            Label("Email", systemImage: "envelope.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)

                // Info cards
                ProspectInfoCard(prospect: prospect)

                // Call history
                if !prospect.callLogs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Call History")
                            .font(.headline)
                            .padding(.horizontal)
                        ForEach(prospect.callLogs.sorted { $0.calledAt > $1.calledAt }) { log in
                            CallLogRow(log: log)
                        }
                    }
                }
            }
        }
        .navigationTitle(prospect.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showCallSession) {
            CallSessionView(preselectedProspect: prospect)
        }
        .sheet(isPresented: $showEdit) {
            EditProspectView(prospect: prospect)
        }
    }
}

struct ContactButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundColor(color)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(color.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

// MARK: - Prospect Info Card
struct ProspectInfoCard: View {
    let prospect: Prospect

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            Divider()
            InfoRow(label: "Phone", value: prospect.phone, icon: "phone")
            if !prospect.email.isEmpty { InfoRow(label: "Email", value: prospect.email, icon: "envelope") }
            if !prospect.industry.isEmpty { InfoRow(label: "Industry", value: prospect.industry, icon: "building.2") }
            InfoRow(label: "Priority", value: prospect.priority.rawValue, icon: "flag")
            if !prospect.notes.isEmpty { InfoRow(label: "Notes", value: prospect.notes, icon: "note.text") }

            Divider()
            HStack {
                VStack {
                    Text("\(prospect.totalCalls)")
                        .font(.title2.bold())
                    Text("Total Calls")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack {
                    Text("\(Int(prospect.connectionRate * 100))%")
                        .font(.title2.bold())
                    Text("Connect Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack {
                    Text("\(prospect.connectedCalls)")
                        .font(.title2.bold())
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

// MARK: - Call Log Row
struct CallLogRow: View {
    let log: CallLog

    var outcomeColor: Color {
        log.outcome.isPositive ? .green : .secondary
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.outcome.icon)
                .foregroundColor(outcomeColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(log.outcome.rawValue)
                    .font(.subheadline.bold())
                Text(log.calledAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(log.formattedDuration)
                    .font(.caption.bold())
                Text(log.sentiment.emoji)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Edit Prospect View
struct EditProspectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var prospect: Prospect

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Info") {
                    TextField("First Name", text: $prospect.firstName)
                    TextField("Last Name", text: $prospect.lastName)
                    TextField("Phone", text: $prospect.phone).keyboardType(.phonePad)
                    TextField("Email", text: $prospect.email).keyboardType(.emailAddress)
                }
                Section("Company") {
                    TextField("Company", text: $prospect.company)
                    TextField("Title", text: $prospect.title)
                    TextField("Industry", text: $prospect.industry)
                }
                Section("Status") {
                    Picker("Status", selection: $prospect.status) {
                        ForEach(ProspectStatus.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
                    }
                    Picker("Priority", selection: $prospect.priority) {
                        ForEach(ProspectPriority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) }
                    }
                }
                Section {
                    TextField("Notes", text: $prospect.notes, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Prospect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        prospect.updatedAt = Date()
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Prospect Extension for isFavorite
extension Prospect {
    var isFavorite: Bool {
        get { tags.contains("favorite") }
        set {
            if newValue { if !tags.contains("favorite") { tags.append("favorite") } }
            else { tags.removeAll { $0 == "favorite" } }
        }
    }
}

#Preview {
    ProspectsView()
        .environment(PremiumManager())
        .modelContainer(for: Prospect.self, inMemory: true)
}
