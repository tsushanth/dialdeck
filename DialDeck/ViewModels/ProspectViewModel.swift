//
//  ProspectViewModel.swift
//  DialDeck
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ProspectViewModel {
    var searchQuery: String = ""
    var selectedStatus: ProspectStatus? = nil
    var selectedPriority: ProspectPriority? = nil
    var sortOption: SortOption = .recentlyUpdated
    var isShowingAddProspect: Bool = false
    var isShowingImport: Bool = false
    var selectedProspect: Prospect? = nil
    var errorMessage: String? = nil

    enum SortOption: String, CaseIterable {
        case recentlyUpdated = "Recently Updated"
        case nameAZ = "Name A-Z"
        case nameZA = "Name Z-A"
        case company = "Company"
        case priority = "Priority"
        case mostCalls = "Most Calls"
    }

    func filteredProspects(_ prospects: [Prospect]) -> [Prospect] {
        var filtered = prospects

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter {
                $0.fullName.lowercased().contains(query) ||
                $0.company.lowercased().contains(query) ||
                $0.phone.contains(query)
            }
        }

        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }

        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority == priority }
        }

        switch sortOption {
        case .recentlyUpdated:
            filtered.sort { $0.updatedAt > $1.updatedAt }
        case .nameAZ:
            filtered.sort { $0.fullName < $1.fullName }
        case .nameZA:
            filtered.sort { $0.fullName > $1.fullName }
        case .company:
            filtered.sort { $0.company < $1.company }
        case .priority:
            filtered.sort { $0.priority.sortOrder > $1.priority.sortOrder }
        case .mostCalls:
            filtered.sort { $0.totalCalls > $1.totalCalls }
        }

        return filtered
    }

    func deleteProspect(_ prospect: Prospect, context: ModelContext) {
        ProspectService.shared.deleteProspect(prospect, context: context)
    }

    func addProspect(
        firstName: String,
        lastName: String,
        company: String,
        phone: String,
        email: String,
        title: String,
        notes: String,
        priority: ProspectPriority,
        industry: String,
        context: ModelContext
    ) {
        let prospect = Prospect(
            firstName: firstName,
            lastName: lastName,
            company: company,
            phone: phone,
            email: email,
            title: title,
            notes: notes,
            priority: priority,
            industry: industry
        )
        ProspectService.shared.addProspect(prospect, context: context)
    }
}
