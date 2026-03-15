//
//  ScriptsView.swift
//  DialDeck
//

import SwiftUI
import SwiftData

struct ScriptsView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var context
    @Query(sort: \CallScript.usageCount, order: .reverse) private var scripts: [CallScript]

    @State private var viewModel = ScriptViewModel()
    @State private var showAddScript = false
    @State private var showPaywall = false
    @State private var scriptToEdit: CallScript? = nil

    private let freeScriptLimit = 5

    var body: some View {
        NavigationStack {
            Group {
                if scripts.isEmpty {
                    EmptyScriptsView {
                        viewModel.resetEditState()
                        showAddScript = true
                    }
                } else {
                    List {
                        ForEach(ScriptCategory.allCases, id: \.self) { category in
                            let categoryScripts = viewModel.filteredScripts(scripts).filter { $0.category == category }
                            if !categoryScripts.isEmpty {
                                Section(category.rawValue) {
                                    ForEach(categoryScripts) { script in
                                        ScriptListRow(script: script) {
                                            viewModel.toggleFavorite(script, context: context)
                                        }
                                        .onTapGesture {
                                            viewModel.selectedScript = script
                                            viewModel.isShowingScriptDetail = true
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                viewModel.deleteScript(script, context: context)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            Button {
                                                viewModel.prepareForEdit(script)
                                                scriptToEdit = script
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Scripts")
            .searchable(text: $viewModel.searchQuery, prompt: "Search scripts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if !premiumManager.isPremium && scripts.filter({ !$0.isTemplate }).count >= freeScriptLimit {
                            showPaywall = true
                        } else {
                            viewModel.resetEditState()
                            showAddScript = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Toggle("Favorites Only", isOn: $viewModel.filterFavorites)
                        Section("Category") {
                            Button("All") { viewModel.selectedCategory = nil }
                            ForEach(ScriptCategory.allCases, id: \.self) { cat in
                                Button(cat.rawValue) { viewModel.selectedCategory = cat }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddScript) {
                ScriptEditorView(viewModel: viewModel, existingScript: nil)
            }
            .sheet(item: $scriptToEdit) { script in
                ScriptEditorView(viewModel: viewModel, existingScript: script)
            }
            .sheet(isPresented: $viewModel.isShowingScriptDetail) {
                if let script = viewModel.selectedScript {
                    ScriptDetailView(script: script)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                viewModel.seedDefaultTemplates(scripts: scripts, context: context)
            }
        }
    }
}

// MARK: - Script List Row
struct ScriptListRow: View {
    let script: CallScript
    let onFavoriteTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: script.category.icon)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(script.title)
                        .font(.subheadline.bold())
                    if script.isTemplate {
                        Text("Template")
                            .font(.caption2)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                Text(script.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !script.industry.isEmpty {
                    Text(script.industry)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Button(action: onFavoriteTap) {
                    Image(systemName: script.isFavorite ? "star.fill" : "star")
                        .foregroundColor(script.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                Text("Used \(script.usageCount)x")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Script Detail View
struct ScriptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let script: CallScript

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: script.category.icon)
                            .font(.title2)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(script.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if !script.industry.isEmpty {
                                Text(script.industry)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text("~\(script.estimatedDurationMinutes) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    ScriptSection(title: "Opening", content: script.intro, icon: "play.fill")
                    ScriptSection(title: "Value Proposition", content: script.valueProposition, icon: "star.fill")

                    if !script.talkingPoints.isEmpty {
                        ScriptListSection(title: "Talking Points", items: script.talkingPoints, icon: "checkmark.circle.fill")
                    }

                    if !script.questions.isEmpty {
                        ScriptListSection(title: "Discovery Questions", items: script.questions, icon: "questionmark.circle.fill")
                    }

                    ScriptSection(title: "Closing Statement", content: script.closingStatement, icon: "flag.fill")
                }
                .padding()
            }
            .navigationTitle(script.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ScriptSection: View {
    let title: String
    let content: String
    let icon: String

    var body: some View {
        if !content.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(.blue)
                Text(content)
                    .font(.body)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
        }
    }
}

struct ScriptListSection: View {
    let title: String
    let items: [String]
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text(items[index])
                            .font(.subheadline)
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Script Editor View
struct ScriptEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var viewModel: ScriptViewModel
    let existingScript: CallScript?

    var isEditing: Bool { existingScript != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Script Title", text: $viewModel.editTitle)
                    Picker("Category", selection: $viewModel.editCategory) {
                        ForEach(ScriptCategory.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    TextField("Industry (optional)", text: $viewModel.editIndustry)
                    Stepper("Est. Duration: \(viewModel.editDurationMinutes) min", value: $viewModel.editDurationMinutes, in: 1...60)
                }

                Section("Opening") {
                    TextField("Intro statement...", text: $viewModel.editIntro, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Value Proposition") {
                    TextField("Why they should care...", text: $viewModel.editValueProp, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Talking Points") {
                    ForEach($viewModel.editTalkingPoints.indices, id: \.self) { i in
                        TextField("Point \(i + 1)", text: $viewModel.editTalkingPoints[i])
                    }
                    Button("+ Add Point") { viewModel.editTalkingPoints.append("") }
                }

                Section("Discovery Questions") {
                    ForEach($viewModel.editQuestions.indices, id: \.self) { i in
                        TextField("Question \(i + 1)", text: $viewModel.editQuestions[i])
                    }
                    Button("+ Add Question") { viewModel.editQuestions.append("") }
                }

                Section("Closing Statement") {
                    TextField("Close...", text: $viewModel.editClosingStatement, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "Edit Script" : "New Script")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let script = existingScript {
                            viewModel.saveScript(script, context: context)
                        } else {
                            viewModel.createScript(context: context)
                        }
                        dismiss()
                    }
                    .disabled(viewModel.editTitle.isEmpty)
                }
            }
        }
    }
}

// MARK: - Empty Scripts View
struct EmptyScriptsView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Scripts Yet")
                .font(.title2.bold())
            Text("Create a call script or use one of our templates")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Create Script", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ScriptsView()
        .environment(PremiumManager())
        .modelContainer(for: CallScript.self, inMemory: true)
}
