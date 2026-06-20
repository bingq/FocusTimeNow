import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class GoalsViewModel {
    private var modelContext: ModelContext?
    var goals: [Goal] = []
    var projects: [Project] = []
    var finishedActivities: [ActivityEvent] = []

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        load()
    }

    func load() {
        guard let modelContext else { return }
        let goalDesc = FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)])
        goals = (try? modelContext.fetch(goalDesc)) ?? []

        let projDesc = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)])
        projects = (try? modelContext.fetch(projDesc)) ?? []

        let actDesc = FetchDescriptor<ActivityEvent>(sortBy: [SortDescriptor(\.startAt)])
        let all = (try? modelContext.fetch(actDesc)) ?? []
        finishedActivities = all.filter { $0.endAt != nil }
    }

    // MARK: - Filtered collections

    var activeGoals: [Goal] { goals.filter { !$0.archived } }
    var activeProjects: [Project] { projects.filter { $0.isActive } }

    func projects(for goal: Goal) -> [Project] {
        activeProjects.filter { $0.goalId == goal.id }
    }

    var goallessProjects: [Project] {
        activeProjects.filter { $0.goalId == nil }
    }

    func project(id: UUID?) -> Project? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    func goal(id: UUID?) -> Goal? {
        guard let id else { return nil }
        return goals.first { $0.id == id }
    }

    // MARK: - Time rollups

    private func seconds(for projectIds: Set<UUID>, since: Date?) -> Int {
        finishedActivities.reduce(0) { acc, a in
            guard let pid = a.projectId, projectIds.contains(pid), let d = a.duration else { return acc }
            if let since, a.startAt < since { return acc }
            return acc + d
        }
    }

    private func projectIdSet(for goal: Goal) -> Set<UUID> {
        Set(activeProjects.filter { $0.goalId == goal.id }.map(\.id))
    }

    func allTimeSeconds(for goal: Goal) -> Int {
        seconds(for: projectIdSet(for: goal), since: nil)
    }

    func weeklySeconds(for goal: Goal) -> Int {
        seconds(for: projectIdSet(for: goal), since: Self.startOfWeek())
    }

    func allTimeSeconds(for project: Project) -> Int {
        seconds(for: [project.id], since: nil)
    }

    /// Weekly target progress 0...1 (clamped). Returns nil when the goal has no target.
    func weeklyProgress(for goal: Goal) -> Double? {
        guard let target = goal.weeklyTargetMinutes, target > 0 else { return nil }
        return min(1.0, Double(weeklySeconds(for: goal)) / Double(target * 60))
    }

    /// "On track" once the elapsed fraction of the week is matched by progress.
    func isOnTrack(for goal: Goal) -> Bool {
        guard let progress = weeklyProgress(for: goal) else { return true }
        return progress >= Self.weekElapsedFraction()
    }

    func remainingToTargetSeconds(for goal: Goal) -> Int {
        guard let target = goal.weeklyTargetMinutes else { return 0 }
        return max(0, target * 60 - weeklySeconds(for: goal))
    }

    /// Number of distinct weeks (with any logged time) the goal has been running.
    func weeksRunning(for goal: Goal) -> Int {
        let ids = projectIdSet(for: goal)
        let cal = Calendar.current
        let weeks = Set(finishedActivities.compactMap { a -> Date? in
            guard let pid = a.projectId, ids.contains(pid) else { return nil }
            return cal.dateInterval(of: .weekOfYear, for: a.startAt)?.start
        })
        return weeks.count
    }

    /// Last 6 weeks of total seconds (oldest → newest, last entry = current week).
    func momentum(for goal: Goal, weeks: Int = 6) -> [Int] {
        let ids = projectIdSet(for: goal)
        let cal = Calendar.current
        let thisWeekStart = Self.startOfWeek()
        var result: [Int] = []
        for i in stride(from: weeks - 1, through: 0, by: -1) {
            let start = cal.date(byAdding: .day, value: -7 * i, to: thisWeekStart)!
            let end = cal.date(byAdding: .day, value: 7, to: start)!
            let secs = finishedActivities.reduce(0) { acc, a in
                guard let pid = a.projectId, ids.contains(pid), let d = a.duration,
                      a.startAt >= start, a.startAt < end else { return acc }
                return acc + d
            }
            result.append(secs)
        }
        return result
    }

    // MARK: - CRUD: Goals

    @discardableResult
    func addGoal(name: String, colorHex: String, icon: String, weeklyTargetMinutes: Int?, trackBy: GoalTrackBy) -> Goal {
        let goal = Goal(name: name, colorHex: colorHex, icon: icon,
                        weeklyTargetMinutes: weeklyTargetMinutes, trackBy: trackBy,
                        sortOrder: (goals.map(\.sortOrder).max() ?? 0) + 1)
        modelContext?.insert(goal)
        save(); load()
        return goal
    }

    func archiveGoal(_ goal: Goal) {
        goal.archived = true
        save(); load()
    }

    func deleteGoal(_ goal: Goal) {
        // Detach projects so their history survives.
        for p in projects where p.goalId == goal.id { p.goalId = nil }
        modelContext?.delete(goal)
        save(); load()
    }

    // MARK: - CRUD: Projects

    @discardableResult
    func addProject(name: String, category: String, goalId: UUID?, pinned: Bool) -> Project {
        let project = Project(name: name, category: category, goalId: goalId,
                              pinnedToQuickStart: pinned,
                              sortOrder: (projects.map(\.sortOrder).max() ?? 0) + 1)
        modelContext?.insert(project)
        save(); load()
        return project
    }

    func archiveProject(_ project: Project) {
        project.isActive = false
        save(); load()
    }

    func deleteProject(_ project: Project) {
        // Untag activities so their logged time stays in the timeline/summary.
        for a in finishedActivities where a.projectId == project.id { a.projectId = nil }
        modelContext?.delete(project)
        save(); load()
    }

    // MARK: - Milestones

    func addMilestone(to goal: Goal, title: String) {
        let m = Milestone(title: title, sortOrder: (goal.milestones.map(\.sortOrder).max() ?? 0) + 1)
        goal.milestones.append(m)
        save(); load()
    }

    func toggleMilestone(_ milestone: Milestone) {
        milestone.done.toggle()
        save(); load()
    }

    func deleteMilestone(_ milestone: Milestone, from goal: Goal) {
        goal.milestones.removeAll { $0.id == milestone.id }
        modelContext?.delete(milestone)
        save(); load()
    }

    func save() {
        do { try modelContext?.save() }
        catch { print("Goals save failed: \(error)") }
    }

    // MARK: - Calendar helpers

    static func startOfWeek(_ date: Date = Date()) -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? Calendar.current.startOfDay(for: date)
    }

    static func weekElapsedFraction(_ date: Date = Date()) -> Double {
        let start = startOfWeek(date)
        let elapsed = date.timeIntervalSince(start)
        return min(1.0, max(0.0, elapsed / (7 * 24 * 3600)))
    }
}
