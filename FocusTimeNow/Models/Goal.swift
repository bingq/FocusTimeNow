import Foundation
import SwiftData
import SwiftUI

enum GoalTrackBy: String, Codable {
    case time
    case milestones
}

@Model
final class Milestone {
    var id: UUID
    var title: String
    var done: Bool
    var sortOrder: Int

    init(title: String, done: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.done = done
        self.sortOrder = sortOrder
    }
}

@Model
final class Goal {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    /// Optional weekly target in minutes. `nil` = no target (neutral grouping).
    var weeklyTargetMinutes: Int?
    var trackByRaw: String
    var archived: Bool
    var sortOrder: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var milestones: [Milestone]

    init(
        name: String,
        colorHex: String = "2E6BE6",
        icon: String = "book.fill",
        weeklyTargetMinutes: Int? = nil,
        trackBy: GoalTrackBy = .time,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.weeklyTargetMinutes = weeklyTargetMinutes
        self.trackByRaw = trackBy.rawValue
        self.archived = false
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.milestones = []
    }

    var color: Color { Color(hex: colorHex) }

    var trackBy: GoalTrackBy {
        get { GoalTrackBy(rawValue: trackByRaw) ?? .time }
        set { trackByRaw = newValue.rawValue }
    }

    var hasMilestones: Bool { !milestones.isEmpty }

    var milestonesDone: Int { milestones.filter { $0.done }.count }

    /// Palette offered in Edit Goal (icon + color pickers).
    static let palette: [String] = ["2E6BE6", "1FA567", "E0962E", "7A5AF0", "DB5A92"]
    static let icons: [String] = ["book.fill", "figure.run", "gamecontroller.fill", "target", "bolt.fill", "briefcase.fill", "heart.fill", "graduationcap.fill"]
}
