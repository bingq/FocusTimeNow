import SwiftUI
import SwiftData

// MARK: - Manage Goals & Projects

struct ManageGoalsView: View {
    let viewModel: GoalsViewModel

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Goals with their projects. Add or edit; archive keeps history.")
                        .font(.system(size: 13)).foregroundStyle(Theme.ink2)
                        .padding(.horizontal, 2)

                    ForEach(viewModel.activeGoals) { goal in
                        goalBlock(goal)
                    }

                    if !viewModel.goallessProjects.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PROJECTS WITHOUT A GOAL")
                                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                                .foregroundStyle(Theme.ink3).padding(.leading, 2)
                            VStack(spacing: 0) {
                                ForEach(viewModel.goallessProjects) { p in
                                    projectRow(p)
                                }
                            }
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Goals & Projects")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgApp, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    EditGoalView(viewModel: viewModel, goal: nil)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func goalBlock(_ goal: Goal) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                GoalIcon(goal: goal, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name).font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                    Text(subtitle(for: goal))
                        .font(.system(size: 12)).foregroundStyle(Theme.ink2)
                }
                Spacer()
                NavigationLink {
                    EditGoalView(viewModel: viewModel, goal: goal)
                } label: {
                    Text("Edit").font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ActivityCategory.getCategoryColor(for: "Learning"))
                }
            }
            .padding(14)

            Divider().background(Theme.hair)

            ForEach(viewModel.projects(for: goal)) { p in
                projectRow(p)
            }

            NavigationLink {
                EditProjectView(viewModel: viewModel, project: nil, presetGoalId: goal.id)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle").font(.system(size: 15))
                    Text("Add project").font(.system(size: 14))
                    Spacer()
                }
                .foregroundStyle(Theme.ink2)
                .padding(.horizontal, 14).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }

    private func projectRow(_ project: Project) -> some View {
        NavigationLink {
            EditProjectView(viewModel: viewModel, project: project, presetGoalId: project.goalId)
        } label: {
            HStack(spacing: 10) {
                Circle().fill(ActivityCategory.getCategoryColor(for: project.category))
                    .frame(width: 8, height: 8)
                Text(project.name).font(.system(size: 14)).foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.ink3)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func subtitle(for goal: Goal) -> String {
        let count = viewModel.projects(for: goal).count
        let projPart = "\(count) project\(count == 1 ? "" : "s")"
        if let target = goal.weeklyTargetMinutes {
            return "\(projPart) · \(TimeFmt.duration(seconds: target * 60))/wk target"
        }
        return projPart
    }
}

// MARK: - Edit Goal

struct EditGoalView: View {
    let viewModel: GoalsViewModel
    let goal: Goal?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var colorHex = Goal.palette[0]
    @State private var icon = Goal.icons[0]
    @State private var hasTarget = false
    @State private var targetHours = 10
    @State private var newMilestone = ""
    @State private var milestoneTitles: [String] = []

    var body: some View {
        Form {
            Section {
                TextField("Goal name", text: $name)
            }

            Section("Color") {
                HStack(spacing: 14) {
                    ForEach(Goal.palette, id: \.self) { hex in
                        Circle().fill(Color(hex: hex))
                            .frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(Theme.ink, lineWidth: colorHex == hex ? 3 : 0))
                            .onTapGesture { colorHex = hex }
                    }
                }
            }

            Section("Icon") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(Goal.icons, id: \.self) { ic in
                        Image(systemName: ic)
                            .font(.system(size: 18))
                            .foregroundStyle(icon == ic ? .white : Theme.ink2)
                            .frame(width: 40, height: 40)
                            .background(icon == ic ? Color(hex: colorHex) : Theme.field)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .onTapGesture { icon = ic }
                    }
                }
            }

            Section("Weekly target (optional)") {
                Toggle("Set a weekly target", isOn: $hasTarget)
                if hasTarget {
                    Stepper("\(targetHours)h / week", value: $targetHours, in: 1...80)
                }
            }

            Section("Milestones (optional)") {
                ForEach(Array(milestoneTitles.enumerated()), id: \.offset) { idx, title in
                    Text(title)
                }
                .onDelete { milestoneTitles.remove(atOffsets: $0) }
                HStack {
                    TextField("Add a milestone", text: $newMilestone)
                    Button {
                        let t = newMilestone.trimmingCharacters(in: .whitespaces)
                        guard !t.isEmpty else { return }
                        milestoneTitles.append(t)
                        newMilestone = ""
                    } label: { Image(systemName: "plus.circle.fill") }
                    .disabled(newMilestone.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if let goal {
                Section {
                    Button(role: .destructive) {
                        viewModel.deleteGoal(goal)
                        dismiss()
                    } label: {
                        Text("Delete goal").frame(maxWidth: .infinity)
                    }
                    Button {
                        viewModel.archiveGoal(goal)
                        dismiss()
                    } label: {
                        Text("Archive instead (keeps history)").frame(maxWidth: .infinity)
                            .foregroundStyle(Theme.ink2)
                    }
                }
            }
        }
        .navigationTitle(goal == nil ? "New goal" : "Edit goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear(perform: hydrate)
    }

    private func hydrate() {
        guard let goal else { return }
        name = goal.name
        colorHex = goal.colorHex
        icon = goal.icon
        if let t = goal.weeklyTargetMinutes { hasTarget = true; targetHours = max(1, t / 60) }
        milestoneTitles = goal.milestones.sorted { $0.sortOrder < $1.sortOrder }.map(\.title)
    }

    private func save() {
        let trackBy: GoalTrackBy = milestoneTitles.isEmpty ? .time : .milestones
        let targetMinutes = hasTarget ? targetHours * 60 : nil
        if let goal {
            goal.name = name
            goal.colorHex = colorHex
            goal.icon = icon
            goal.weeklyTargetMinutes = targetMinutes
            goal.trackBy = trackBy
            syncMilestones(on: goal)
            viewModel.save(); viewModel.load()
        } else {
            let g = viewModel.addGoal(name: name, colorHex: colorHex, icon: icon,
                                      weeklyTargetMinutes: targetMinutes, trackBy: trackBy)
            syncMilestones(on: g)
            viewModel.save(); viewModel.load()
        }
        dismiss()
    }

    private func syncMilestones(on goal: Goal) {
        let existing = goal.milestones.sorted { $0.sortOrder < $1.sortOrder }
        // Reconcile by title list: keep done-state where titles match positionally.
        var rebuilt: [Milestone] = []
        for (idx, title) in milestoneTitles.enumerated() {
            if idx < existing.count {
                let m = existing[idx]
                m.title = title
                m.sortOrder = idx
                rebuilt.append(m)
            } else {
                rebuilt.append(Milestone(title: title, sortOrder: idx))
            }
        }
        // Delete any trailing removed milestones.
        if existing.count > milestoneTitles.count {
            for m in existing[milestoneTitles.count...] {
                goal.milestones.removeAll { $0.id == m.id }
            }
        }
        goal.milestones = rebuilt
    }
}

// MARK: - Edit Project

struct EditProjectView: View {
    let viewModel: GoalsViewModel
    let project: Project?
    let presetGoalId: UUID?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "Learning"
    @State private var goalId: UUID?
    @State private var pinned = true

    var body: some View {
        Form {
            Section {
                TextField("Project name", text: $name)
            }

            Section("Belongs to goal") {
                Picker("Goal", selection: $goalId) {
                    Text("No goal").tag(UUID?.none)
                    ForEach(viewModel.activeGoals) { g in
                        Text(g.name).tag(UUID?.some(g.id))
                    }
                }
            }

            Section("Default category — inherited when you start this project") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(ActivityCategory.defaultCategories) { cat in
                        Image(systemName: cat.icon)
                            .font(.system(size: 17))
                            .foregroundStyle(cat.color)
                            .frame(width: 40, height: 40)
                            .background(cat.color.tinted(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(cat.color, lineWidth: category == cat.name ? 2 : 0)
                            )
                            .onTapGesture { category = cat.name }
                    }
                }
            }

            Section("Pin to Today's quick-start") {
                Toggle("Show in \"usually\" list", isOn: $pinned)
            }

            if let project {
                Section {
                    Button(role: .destructive) {
                        viewModel.deleteProject(project)
                        dismiss()
                    } label: {
                        Text("Delete project").frame(maxWidth: .infinity)
                    }
                    Button {
                        viewModel.archiveProject(project)
                        dismiss()
                    } label: {
                        Text("Archive instead (keeps \(TimeFmt.duration(seconds: viewModel.allTimeSeconds(for: project))) of history)")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Theme.ink2)
                    }
                }
            }
        }
        .navigationTitle(project == nil ? "New project" : "Edit project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear(perform: hydrate)
    }

    private func hydrate() {
        if let project {
            name = project.name
            category = project.category
            goalId = project.goalId
            pinned = project.pinnedToQuickStart
        } else {
            goalId = presetGoalId
        }
    }

    private func save() {
        if let project {
            project.name = name
            project.category = category
            project.goalId = goalId
            project.pinnedToQuickStart = pinned
            viewModel.save(); viewModel.load()
        } else {
            viewModel.addProject(name: name, category: category, goalId: goalId, pinned: pinned)
        }
        dismiss()
    }
}
