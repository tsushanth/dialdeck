//
//  ProspectService.swift
//  DialDeck
//

import Foundation
import SwiftData

@MainActor
final class ProspectService {
    static let shared = ProspectService()
    private init() {}

    func addProspect(
        _ prospect: Prospect,
        context: ModelContext
    ) {
        context.insert(prospect)
        try? context.save()
        AnalyticsService.shared.track(.prospectAdded)
    }

    func deleteProspect(_ prospect: Prospect, context: ModelContext) {
        context.delete(prospect)
        try? context.save()
    }

    func updateProspect(_ prospect: Prospect, context: ModelContext) {
        prospect.updatedAt = Date()
        try? context.save()
    }

    func fetchProspects(
        in context: ModelContext,
        status: ProspectStatus? = nil,
        priority: ProspectPriority? = nil,
        searchQuery: String = ""
    ) throws -> [Prospect] {
        var descriptor = FetchDescriptor<Prospect>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        if !searchQuery.isEmpty {
            descriptor.predicate = #Predicate<Prospect> { prospect in
                prospect.firstName.localizedStandardContains(searchQuery) ||
                prospect.lastName.localizedStandardContains(searchQuery) ||
                prospect.company.localizedStandardContains(searchQuery)
            }
        }

        let all = try context.fetch(descriptor)

        return all.filter { prospect in
            let statusMatch = status == nil || prospect.status == status
            let priorityMatch = priority == nil || prospect.priority == priority
            return statusMatch && priorityMatch
        }
    }

    func importProspects(from csv: String, context: ModelContext) -> (imported: Int, failed: Int) {
        let lines = csv.components(separatedBy: "\n").dropFirst()
        var imported = 0
        var failed = 0

        for line in lines {
            let fields = line.components(separatedBy: ",")
            guard fields.count >= 3 else { failed += 1; continue }
            let prospect = Prospect(
                firstName: fields[0].trimmingCharacters(in: .whitespaces),
                lastName: fields.count > 1 ? fields[1].trimmingCharacters(in: .whitespaces) : "",
                company: fields.count > 2 ? fields[2].trimmingCharacters(in: .whitespaces) : "",
                phone: fields.count > 3 ? fields[3].trimmingCharacters(in: .whitespaces) : "",
                email: fields.count > 4 ? fields[4].trimmingCharacters(in: .whitespaces) : ""
            )
            context.insert(prospect)
            imported += 1
        }

        try? context.save()
        return (imported, failed)
    }
}
