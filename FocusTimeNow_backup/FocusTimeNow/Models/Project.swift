import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var category: String
    var description: String?
    var isActive: Bool
    var createdAt: Date
    var targetHours: Double?
    
    init(
        name: String,
        category: String,
        description: String? = nil,
        isActive: Bool = true,
        targetHours: Double? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.description = description
        self.isActive = isActive
        self.createdAt = Date()
        self.targetHours = targetHours
    }
    
    func archive() {
        isActive = false
    }
    
    func activate() {
        isActive = true
    }
}