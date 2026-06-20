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
        return TimeFmt.duration(seconds: duration)
    }

    /// 12-hour range, e.g. "7:50 – 8:30 AM".
    var timeRange: String {
        let start = TimeFmt.clock12(startAt)
        if let endAt = endAt {
            return "\(start) – \(TimeFmt.clock12(endAt))"
        }
        return "\(start) – Now"
    }
}

// MARK: - Shared formatting

enum TimeFmt {
    /// Compact duration from seconds: "45m", "1h 20m", "2h".
    static func duration(seconds: Int) -> String {
        let totalMinutes = max(0, Int((Double(seconds) / 60).rounded()))
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        let h = totalMinutes / 60, m = totalMinutes % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    static func duration(_ interval: TimeInterval) -> String {
        duration(seconds: Int(interval))
    }

    /// Stopwatch clock: "00:42" or "1:02:05".
    static func clock(_ interval: TimeInterval) -> String {
        let s = max(0, Int(interval))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }

    private static let clock12Formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    static func clock12(_ date: Date) -> String {
        clock12Formatter.string(from: date)
    }
}
