//
//  ObjectionsView.swift
//  DialDeck
//

import SwiftUI
import SwiftData

struct ObjectionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Objection.usageCount, order: .reverse) private var objections: [Objection]

    @State private var searchQuery = ""
    @State private var selectedCategory: ObjectionCategory? = nil
    @State private var selectedObjection: Objection? = nil
    @State private var showAddObjection = false

    var filteredObjections: [Objection] {
        var result = objections
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) ||
                $0.objectionText.lowercased().contains(q)
            }
        }
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if objections.isEmpty {
                    EmptyObjectionsView {
                        seedDefaultObjections()
                    }
                } else {
                    List {
                        ForEach(ObjectionCategory.allCases, id: \.self) { category in
                            let catObjections = filteredObjections.filter { $0.category == category }
                            if !catObjections.isEmpty {
                                Section {
                                    ForEach(catObjections) { objection in
                                        ObjectionListRow(objection: objection)
                                            .onTapGesture {
                                                objection.usageCount += 1
                                                try? context.save()
                                                selectedObjection = objection
                                                AnalyticsService.shared.track(.objectionViewed(category: objection.category.rawValue))
                                            }
                                    }
                                } header: {
                                    Label(category.rawValue, systemImage: category.icon)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Objection Guide")
            .searchable(text: $searchQuery, prompt: "Search objections")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All Categories") { selectedCategory = nil }
                        ForEach(ObjectionCategory.allCases, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Label(cat.rawValue, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddObjection = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $selectedObjection) { objection in
                ObjectionDetailView(objection: objection)
            }
            .sheet(isPresented: $showAddObjection) {
                AddObjectionView()
            }
            .onAppear {
                if objections.isEmpty { seedDefaultObjections() }
            }
        }
    }

    private func seedDefaultObjections() {
        for objection in Objection.defaultObjections() {
            context.insert(objection)
        }
        try? context.save()
    }
}

// MARK: - Objection List Row
struct ObjectionListRow: View {
    let objection: Objection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(objection.title)
                    .font(.subheadline.bold())
                Spacer()
                if objection.isFavorite {
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                }
                Text("\(objection.responses.count) responses")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(objection.objectionText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Objection Detail View
struct ObjectionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var objection: Objection
    @State private var copiedIndex: Int? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Objection
                    VStack(alignment: .leading, spacing: 8) {
                        Label("The Objection", systemImage: "exclamationmark.bubble.fill")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(objection.objectionText)
                            .font(.body)
                            .italic()
                            .padding(14)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(12)
                    }

                    // Responses
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Proven Responses", systemImage: "checkmark.bubble.fill")
                            .font(.headline)
                            .foregroundColor(.green)

                        ForEach(objection.responses.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                Text(objection.responses[i])
                                    .font(.subheadline)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = objection.responses[i]
                                    copiedIndex = i
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedIndex = nil }
                                } label: {
                                    Image(systemName: copiedIndex == i ? "checkmark" : "doc.on.doc")
                                        .font(.caption)
                                        .foregroundColor(copiedIndex == i ? .green : .secondary)
                                }
                            }
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }

                    // Tips
                    if !objection.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Pro Tips", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundColor(.orange)
                            ForEach(objection.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                        .padding(.top, 3)
                                    Text(tip).font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle(objection.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        objection.isFavorite.toggle()
                        try? context.save()
                    } label: {
                        Image(systemName: objection.isFavorite ? "star.fill" : "star")
                            .foregroundColor(objection.isFavorite ? .yellow : .secondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Objection View
struct AddObjectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var category: ObjectionCategory = .other
    @State private var objectionText = ""
    @State private var responses: [String] = [""]
    @State private var tips: [String] = [""]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(ObjectionCategory.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    TextField("Objection text...", text: $objectionText, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Responses") {
                    ForEach($responses.indices, id: \.self) { i in
                        TextField("Response \(i + 1)", text: $responses[i], axis: .vertical)
                            .lineLimit(2...4)
                    }
                    Button("+ Add Response") { responses.append("") }
                }

                Section("Tips") {
                    ForEach($tips.indices, id: \.self) { i in
                        TextField("Tip \(i + 1)", text: $tips[i])
                    }
                    Button("+ Add Tip") { tips.append("") }
                }
            }
            .navigationTitle("Add Objection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let obj = Objection(
                            title: title,
                            category: category,
                            objectionText: objectionText,
                            responses: responses.filter { !$0.isEmpty },
                            tips: tips.filter { !$0.isEmpty },
                            isCustom: true
                        )
                        context.insert(obj)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(title.isEmpty || objectionText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Empty Objections View
struct EmptyObjectionsView: View {
    let onSeed: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Objection Handlers")
                .font(.title2.bold())
            Text("Load our proven objection-handling library")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Load Default Library", action: onSeed)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ObjectionsView()
        .modelContainer(for: Objection.self, inMemory: true)
}
