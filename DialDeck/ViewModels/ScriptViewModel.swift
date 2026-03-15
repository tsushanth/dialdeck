//
//  ScriptViewModel.swift
//  DialDeck
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ScriptViewModel {
    var searchQuery: String = ""
    var selectedCategory: ScriptCategory? = nil
    var isShowingAddScript: Bool = false
    var selectedScript: CallScript? = nil
    var isShowingScriptDetail: Bool = false
    var filterFavorites: Bool = false

    // Edit state
    var editTitle: String = ""
    var editCategory: ScriptCategory = .coldCall
    var editIntro: String = ""
    var editValueProp: String = ""
    var editQuestions: [String] = [""]
    var editTalkingPoints: [String] = [""]
    var editClosingStatement: String = ""
    var editIndustry: String = ""
    var editDurationMinutes: Int = 5

    func filteredScripts(_ scripts: [CallScript]) -> [CallScript] {
        var filtered = scripts

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            filtered = filtered.filter {
                $0.title.lowercased().contains(q) ||
                $0.industry.lowercased().contains(q) ||
                $0.intro.lowercased().contains(q)
            }
        }

        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        if filterFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }

        return filtered.sorted { $0.usageCount > $1.usageCount }
    }

    func prepareForEdit(_ script: CallScript) {
        editTitle = script.title
        editCategory = script.category
        editIntro = script.intro
        editValueProp = script.valueProposition
        editQuestions = script.questions.isEmpty ? [""] : script.questions
        editTalkingPoints = script.talkingPoints.isEmpty ? [""] : script.talkingPoints
        editClosingStatement = script.closingStatement
        editIndustry = script.industry
        editDurationMinutes = script.estimatedDurationMinutes
    }

    func resetEditState() {
        editTitle = ""
        editCategory = .coldCall
        editIntro = ""
        editValueProp = ""
        editQuestions = [""]
        editTalkingPoints = [""]
        editClosingStatement = ""
        editIndustry = ""
        editDurationMinutes = 5
    }

    func saveScript(_ script: CallScript, context: ModelContext) {
        script.title = editTitle
        script.category = editCategory
        script.intro = editIntro
        script.valueProposition = editValueProp
        script.questions = editQuestions.filter { !$0.isEmpty }
        script.talkingPoints = editTalkingPoints.filter { !$0.isEmpty }
        script.closingStatement = editClosingStatement
        script.industry = editIndustry
        script.estimatedDurationMinutes = editDurationMinutes
        script.updatedAt = Date()
        try? context.save()
    }

    func createScript(context: ModelContext) {
        let script = CallScript(
            title: editTitle,
            category: editCategory,
            intro: editIntro,
            valueProposition: editValueProp,
            questions: editQuestions.filter { !$0.isEmpty },
            closingStatement: editClosingStatement,
            talkingPoints: editTalkingPoints.filter { !$0.isEmpty },
            industry: editIndustry,
            estimatedDurationMinutes: editDurationMinutes
        )
        context.insert(script)
        try? context.save()
        AnalyticsService.shared.track(.scriptCreated)
    }

    func toggleFavorite(_ script: CallScript, context: ModelContext) {
        script.isFavorite.toggle()
        try? context.save()
    }

    func deleteScript(_ script: CallScript, context: ModelContext) {
        context.delete(script)
        try? context.save()
    }

    func seedDefaultTemplates(scripts: [CallScript], context: ModelContext) {
        guard scripts.filter({ $0.isTemplate }).isEmpty else { return }
        for template in CallScript.defaultTemplates() {
            context.insert(template)
        }
        try? context.save()
    }
}
