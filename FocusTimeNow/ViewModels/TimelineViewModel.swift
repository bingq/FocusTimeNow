import Foundation
import SwiftData
import SwiftUI

/// An item in the Today list: either a logged activity or an untracked gap between two activities.
enum TimelineEntry: Identifiable {
    case activity(ActivityEvent)
    case gap(id: String, start: Date, end: Date)

    var id: String {
        switch self {
        case .activity(let a): return a.id.uuidString
        case .gap(let id, _, _): return id
        }
    }
}

struct ProportionSegment: Identifiable {
    let category: String
    let color: Color
    let fraction: Double // 0...1 of tracked time
    var id: String { category }
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let text: String
}

@MainActor
@Observable
class TimelineViewModel {
    private var modelContext: ModelContext?
    var activities: [ActivityEvent] = []
    var ongoingActivity: ActivityEvent?
    var shouldShowFullScreenTimer: Bool = false
    var toast: ToastMessage?

    var coachDismissed: Bool {
        get { UserDefaults.standard.bool(forKey: "ftn_coachDismissed") }
        set { UserDefaults.standard.set(newValue, forKey: "ftn_coachDismissed") }
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadTodaysActivities()
    }

    func loadTodaysActivities() {
        guard let modelContext = modelContext else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let predicate = #Predicate<ActivityEvent> { activity in
            activity.startAt >= today && activity.startAt < tomorrow
        }
        let descriptor = FetchDescriptor<ActivityEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )

        do {
            activities = try modelContext.fetch(descriptor)
            ongoingActivity = activities.first { $0.isOngoing }
        } catch {
            print("Failed to fetch activities: \(error)")
        }
    }

    // MARK: - Start / switch / stop

    /// Tap-to-start and tap-to-switch. Starting anything auto-logs the current running session first (zero gap).
    func startActivity(category: String, backMinutes: Int = 0, openTimer: Bool = true) {
        guard let modelContext = modelContext else { return }

        let wasRunning = ongoingActivity != nil
        if let ongoing = ongoingActivity {
            ongoing.stop()
        }

        let start = Date().addingTimeInterval(TimeInterval(-backMinutes * 60))
        let newActivity = ActivityEvent(
            title: ActivityCategory.defaultTitle(for: category),
            category: category,
            startAt: start
        )
        modelContext.insert(newActivity)
        save()
        loadTodaysActivities()
        shouldShowFullScreenTimer = openTimer

        if wasRunning {
            showToast(category: category, text: "Switched to \(category)")
        }
    }

    func stopOngoingActivity() {
        guard let ongoing = ongoingActivity else { return }
        let seconds = Int(Date().timeIntervalSince(ongoing.startAt))
        ongoing.stop()
        shouldShowFullScreenTimer = false
        save()
        loadTodaysActivities()
        showToast(category: ongoing.category,
                  text: "Logged \(TimeFmt.duration(seconds: seconds)) · \(ongoing.category)")
    }

    /// Shift an ongoing session's start forward to exclude paused time.
    func extendStart(of activity: ActivityEvent, by seconds: TimeInterval) {
        activity.startAt = activity.startAt.addingTimeInterval(seconds)
        save()
    }

    // MARK: - Gaps, recategorize, repeat, delete

    func logGap(category: String, start: Date, end: Date) {
        guard let modelContext = modelContext else { return }
        let activity = ActivityEvent(
            title: ActivityCategory.defaultTitle(for: category),
            category: category,
            startAt: start,
            endAt: end
        )
        modelContext.insert(activity)
        save()
        loadTodaysActivities()
        showToast(category: category,
                  text: "Filled \(TimeFmt.duration(seconds: Int(end.timeIntervalSince(start)))) · \(category)")
    }

    func recategorize(_ activity: ActivityEvent, to category: String) {
        // If the title was just the old category's default, move it to the new default too.
        if activity.title == ActivityCategory.defaultTitle(for: activity.category) {
            activity.title = ActivityCategory.defaultTitle(for: category)
        }
        activity.category = category
        save()
        loadTodaysActivities()
    }

    func deleteActivity(_ activity: ActivityEvent) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(activity)
        save()
        loadTodaysActivities()
    }

    private func save() {
        do { try modelContext?.save() }
        catch { print("Save failed: \(error)") }
    }

    private func showToast(category: String, text: String) {
        let cat = ActivityCategory.category(for: category)
        toast = ToastMessage(icon: cat.icon, color: cat.color, text: text)
    }

    // MARK: - Derived data

    /// Finished activities only (excludes the ongoing session).
    private var finishedActivities: [ActivityEvent] {
        activities.filter { !$0.isOngoing }
    }

    var dailyTotals: [String: Int] {
        var totals: [String: Int] = [:]
        for a in finishedActivities {
            if let d = a.duration { totals[a.category, default: 0] += d }
        }
        return totals
    }

    var totalTrackedSeconds: Int {
        dailyTotals.values.reduce(0, +)
    }

    var wasteSeconds: Int {
        dailyTotals["Waste"] ?? 0
    }

    /// Proportion bar segments, in the fixed category order, only for categories with time.
    var proportionSegments: [ProportionSegment] {
        let total = totalTrackedSeconds
        guard total > 0 else { return [] }
        return ActivityCategory.defaultCategories.compactMap { cat in
            let secs = dailyTotals[cat.name] ?? 0
            guard secs > 0 else { return nil }
            return ProportionSegment(category: cat.name, color: cat.color,
                                     fraction: Double(secs) / Double(total))
        }
    }

    /// Interleave finished activities (newest first) with untracked gap rows.
    var entries: [TimelineEntry] {
        let finished = finishedActivities
            .filter { $0.endAt != nil }
            .sorted { $0.startAt < $1.startAt }

        var built: [TimelineEntry] = []
        let threshold = TimeInterval(Theme.gapThresholdMinutes * 60)
        for (i, a) in finished.enumerated() {
            if i > 0, let prevEnd = finished[i - 1].endAt {
                let gap = a.startAt.timeIntervalSince(prevEnd)
                if gap >= threshold {
                    built.append(.gap(id: "gap-\(a.id.uuidString)", start: prevEnd, end: a.startAt))
                }
            }
            built.append(.activity(a))
        }
        return built.reversed()
    }

    func formattedTotal(for category: String) -> String {
        TimeFmt.duration(seconds: dailyTotals[category] ?? 0)
    }
}
