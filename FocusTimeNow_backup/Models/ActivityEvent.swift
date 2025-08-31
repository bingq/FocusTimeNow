import Foundation
import SwiftData

@Model
final class ActivityEvent {
    var id: UUID
    var title: String
    var category: String
    var startAt: Date
    var endAt: Date?
    var duration: Int?
    var note: String?
    var tags: [String]?
    var sourceApp: String?
    var projectId: UUID?
    
    init(
        title: String = "",
        category: String,
        startAt: Date = Date(),
        endAt: Date? = nil,
        note: String? = nil,
        tags: [String]? = nil,
        sourceApp: String? = nil,
        projectId: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.startAt = startAt
        self.endAt = endAt
        self.note = note
        self.tags = tags
        self.sourceApp = sourceApp
        self.projectId = projectId
        self.duration = self.calculateDuration()
    }
    
    func calculateDuration() -> Int? {
        guard let endAt = endAt else { return nil }
        return Int(endAt.timeIntervalSince(startAt))
    }
    
    func stop() {
        endAt = Date()
        duration = calculateDuration()
    }
    
    var isOngoing: Bool {
        endAt == nil
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "Now" }
        let minutes = duration / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let start = formatter.string(from: startAt)
        
        if let endAt = endAt {
            let end = formatter.string(from: endAt)
            return "\(start) – \(end)"
        } else {
            return "\(start) – Now"
        }
    }
}