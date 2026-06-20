import SwiftUI
import SwiftData

// MARK: - Project Picker (bottom sheet)
// Lists projects grouped by goal (2 levels). Picking one tags the activity and
// inherits the project's default category. "Keep without a project" escapes.

struct ProjectPickerSheet: View {
    let activityLabel: String
    let onPick: (Project?) -> Void

    @Query(sort: [SortDescriptor<Goal>(\.sortOrder), SortDescriptor<Goal>(\.createdAt)])
    private var goals: [Goal]
    @Query(sort: [SortDescriptor<Project>(\.sortOrder), SortDescriptor<Project>(\.createdAt)])
    private var projects: [Project]
    @Environment(\.dismiss) private var dismiss

    private var activeProjects: [Project] { projects.filter { $0.isActive } }
    private var activeGoals: [Goal] { goals.filter { !$0.archived } }
    private var goallessProjects: [Project] { activeProjects.filter { $0.goalId == nil } }

    var body: some View {
        VStack(spacing: 10) {
            Capsule().fill(Theme.hair).frame(width: 38, height: 5)
                .padding(.top, 8).padding(.bottom, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Link to a project")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
                Text(activityLabel)
                    .font(.system(size: 13)).foregroundStyle(Theme.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(activeGoals) { goal in
                        let projs = activeProjects.filter { $0.goalId == goal.id }
                        if !projs.isEmpty {
                            goalGroup(goal: goal, projects: projs)
                        }
                    }
                    if !goallessProjects.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            groupHeader(color: Theme.ink3, title: "NO GOAL")
                            ForEach(goallessProjects) { p in projectButton(p) }
                        }
                    }
                    if activeProjects.isEmpty {
                        Text("No projects yet. Create one from the Goals tab.")
                            .font(.system(size: 13)).foregroundStyle(Theme.ink2)
                            .padding(.vertical, 12)
                    }
                }
            }

            Button { onPick(nil); dismiss() } label: {
                Text("Keep without a project")
                    .font(.system(size: 15)).foregroundStyle(Theme.ink2)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.bgApp)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    private func goalGroup(goal: Goal, projects: [Project]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            groupHeader(color: goal.color, title: goal.name.uppercased())
            ForEach(projects) { p in projectButton(p) }
        }
    }

    private func groupHeader(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title).font(.system(size: 11, weight: .bold)).tracking(0.6)
                .foregroundStyle(Theme.ink3)
        }
        .padding(.leading, 2)
    }

    private func projectButton(_ project: Project) -> some View {
        Button { onPick(project); dismiss() } label: {
            HStack(spacing: 10) {
                Image(systemName: ActivityCategory.getCategoryIcon(for: project.category))
                    .font(.system(size: 14))
                    .foregroundStyle(ActivityCategory.getCategoryColor(for: project.category))
                    .frame(width: 28, height: 28)
                    .background(ActivityCategory.getCategoryColor(for: project.category).tinted(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(project.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
