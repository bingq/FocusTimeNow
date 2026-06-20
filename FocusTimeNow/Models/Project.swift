import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    /// Default category, inherited when the project is started.
    var category: String
    var projectDescription: String?
    var isActive: Bool
    var createdAt: Date
    var targetHours: Double?
    /// Optional parent goal (two-level hierarchy; a project may have no goal).
    var goalId: UUID?
    /// Show this project in Today's "usually" quick-start list.
    var pinnedToQuickStart: Bool = true
    var sortOrder: Int = 0

    init(
        name: String,
        category: String,
        projectDescription: String? = nil,
        isActive: Bool = true,
        targetHours: Double? = nil,
        goalId: UUID? = nil,
        pinnedToQuickStart: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.projectDescription = projectDescription
        self.isActive = isActive
        self.createdAt = Date()
        self.targetHours = targetHours
        self.goalId = goalId
        self.pinnedToQuickStart = pinnedToQuickStart
        self.sortOrder = sortOrder
    }

    /// Archive preserves history; the project just stops appearing in active lists.
    func archive() {
        isActive = false
    }

    func activate() {
        isActive = true
    }
}
