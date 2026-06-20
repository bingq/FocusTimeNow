import SwiftUI
import SwiftData

// MARK: - Goals tab (root)

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GoalsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        if viewModel.activeGoals.isEmpty {
                            emptyState
                        } else {
                            ForEach(viewModel.activeGoals) { goal in
                                NavigationLink {
                                    GoalDetailView(goal: goal, viewModel: viewModel)
                                } label: {
                                    GoalCard(goal: goal, viewModel: viewModel)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ManageGoalsView(viewModel: viewModel)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(ActivityCategory.getCategoryColor(for: "Learning"))
                    }
                }
            }
            .toolbarBackground(Theme.bgApp, for: .navigationBar)
            .onAppear { viewModel.setModelContext(modelContext) }
        }
        .tint(ActivityCategory.getCategoryColor(for: "Learning"))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "flag")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.ink3)
            Text("No goals yet")
                .font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.ink)
            Text("Group your projects into goals to see\nwhether you're making progress.")
                .font(.system(size: 14)).foregroundStyle(Theme.ink2)
                .multilineTextAlignment(.center)
            NavigationLink {
                ManageGoalsView(viewModel: viewModel)
            } label: {
                Text("Create a goal")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 11)
                    .background(ActivityCategory.getCategoryColor(for: "Learning"))
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Goal card (Goals tab)

private struct GoalCard: View {
    let goal: Goal
    let viewModel: GoalsViewModel

    var body: some View {
        let weekly = viewModel.weeklySeconds(for: goal)
        let progress = viewModel.weeklyProgress(for: goal)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                GoalIcon(goal: goal, size: 34)
                Text(goal.name)
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.ink)
                Spacer()
                if let target = goal.weeklyTargetMinutes {
                    Text("\(TimeFmt.duration(seconds: weekly)) / \(TimeFmt.duration(seconds: target * 60))")
                        .font(.system(size: 13, weight: .semibold)).monospacedDigit()
                        .foregroundStyle(Theme.ink2)
                } else {
                    Text(TimeFmt.duration(seconds: weekly))
                        .font(.system(size: 13, weight: .semibold)).monospacedDigit()
                        .foregroundStyle(Theme.ink2)
                }
            }

            if let progress {
                MeterBar(fraction: progress, color: goal.color)
                Text("\(Int(progress * 100))% of weekly target · \(viewModel.isOnTrack(for: goal) ? "on track" : "behind pace")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(viewModel.isOnTrack(for: goal) ? ActivityCategory.getCategoryColor(for: "Sports") : Theme.ink3)
            }

            let projs = viewModel.projects(for: goal)
            if !projs.isEmpty {
                VStack(spacing: 6) {
                    ForEach(projs) { p in
                        HStack(spacing: 7) {
                            Circle().fill(goal.color).frame(width: 6, height: 6)
                            Text(p.name).font(.system(size: 13)).foregroundStyle(Theme.ink2)
                            Spacer()
                            Text(TimeFmt.duration(seconds: viewModel.allTimeSeconds(for: p)))
                                .font(.system(size: 13, weight: .medium)).monospacedDigit()
                                .foregroundStyle(Theme.ink2)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }
}

// MARK: - Goal Detail

struct GoalDetailView: View {
    let goal: Goal
    let viewModel: GoalsViewModel
    @State private var showMilestones = false

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if goal.hasMilestones {
                        Picker("View", selection: $showMilestones) {
                            Text("Time").tag(false)
                            Text("Milestones").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }

                    if showMilestones && goal.hasMilestones {
                        milestonesView
                    } else {
                        timeView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgApp, for: .navigationBar)
        .onAppear { showMilestones = goal.trackBy == .milestones && goal.hasMilestones }
    }

    // By time invested ★
    private var timeView: some View {
        let weekly = viewModel.weeklySeconds(for: goal)
        let allTime = viewModel.allTimeSeconds(for: goal)
        let progress = viewModel.weeklyProgress(for: goal)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 18) {
                ProgressRing(progress: progress ?? 0, color: goal.color, lineWidth: 9, size: 92) {
                    VStack(spacing: 0) {
                        Text(progress != nil ? "\(Int((progress ?? 0) * 100))%" : TimeFmt.duration(seconds: weekly))
                            .font(.system(size: 18, weight: .heavy)).foregroundStyle(Theme.ink)
                        Text(progress != nil ? "THIS WK" : "this wk")
                            .font(.system(size: 8, weight: .bold)).tracking(0.6).foregroundStyle(Theme.ink3)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    if let target = goal.weeklyTargetMinutes {
                        (Text(TimeFmt.duration(seconds: weekly)).font(.system(size: 20, weight: .heavy))
                         + Text(" / \(TimeFmt.duration(seconds: target * 60)) target").font(.system(size: 13)))
                            .foregroundStyle(Theme.ink)
                    }
                    Text("\(TimeFmt.duration(seconds: allTime)) invested all-time · \(viewModel.weeksRunning(for: goal)) weeks running")
                        .font(.system(size: 13)).foregroundStyle(Theme.ink2)
                    if let progress {
                        HStack(spacing: 5) {
                            Circle().fill(viewModel.isOnTrack(for: goal) ? ActivityCategory.getCategoryColor(for: "Sports") : Theme.ink3)
                                .frame(width: 7, height: 7)
                            Text(viewModel.isOnTrack(for: goal)
                                 ? "On track — \(TimeFmt.duration(seconds: viewModel.remainingToTargetSeconds(for: goal))) to go this week"
                                 : "Behind pace — \(TimeFmt.duration(seconds: viewModel.remainingToTargetSeconds(for: goal))) to go")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(viewModel.isOnTrack(for: goal) ? ActivityCategory.getCategoryColor(for: "Sports") : Theme.ink3)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))

            sectionLabel("WEEKLY MOMENTUM")
            MomentumChart(weeks: viewModel.momentum(for: goal), color: goal.color)
                .padding(16)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))

            sectionLabel("PROJECTS IN THIS GOAL")
            let projs = viewModel.projects(for: goal)
            if projs.isEmpty {
                Text("No projects yet.").font(.system(size: 13)).foregroundStyle(Theme.ink2)
            } else {
                let maxSecs = max(1, projs.map { viewModel.allTimeSeconds(for: $0) }.max() ?? 1)
                VStack(spacing: 10) {
                    ForEach(projs) { p in
                        let secs = viewModel.allTimeSeconds(for: p)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(p.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink)
                                Spacer()
                                Text(TimeFmt.duration(seconds: secs))
                                    .font(.system(size: 13, weight: .bold)).monospacedDigit().foregroundStyle(Theme.ink)
                            }
                            MeterBar(fraction: Double(secs) / Double(maxSecs), color: goal.color)
                        }
                        .padding(14)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }

    private var milestonesView: some View {
        let done = goal.milestonesDone
        let total = goal.milestones.count
        let pct = total > 0 ? Double(done) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    (Text("\(done)").font(.system(size: 22, weight: .heavy))
                     + Text(" of \(total) milestones done").font(.system(size: 15)))
                        .foregroundStyle(Theme.ink)
                    Text("\(TimeFmt.duration(seconds: viewModel.allTimeSeconds(for: goal))) invested · \(Int(pct * 100))% complete")
                        .font(.system(size: 13)).foregroundStyle(Theme.ink2)
                }
                Spacer()
                ProgressRing(progress: pct, color: ActivityCategory.getCategoryColor(for: "Sports"), lineWidth: 9, size: 72) {
                    Text("\(Int(pct * 100))%").font(.system(size: 15, weight: .heavy)).foregroundStyle(Theme.ink)
                }
            }
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))

            sectionLabel("MILESTONES — OUTCOME, NOT JUST HOURS")
            VStack(spacing: 0) {
                ForEach(goal.milestones.sorted { $0.sortOrder < $1.sortOrder }) { m in
                    Button { viewModel.toggleMilestone(m) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: m.done ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(m.done ? ActivityCategory.getCategoryColor(for: "Sports") : Theme.ink3)
                            Text(m.title)
                                .font(.system(size: 15))
                                .strikethrough(m.done)
                                .foregroundStyle(m.done ? Theme.ink3 : Theme.ink)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    if m.id != goal.milestones.sorted(by: { $0.sortOrder < $1.sortOrder }).last?.id {
                        Divider().background(Theme.hair)
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold)).tracking(0.8)
            .foregroundStyle(Theme.ink3)
            .padding(.leading, 2)
    }
}

// MARK: - Shared small components

struct GoalIcon: View {
    let goal: Goal
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: goal.icon)
            .font(.system(size: size * 0.5))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(goal.color)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

struct MeterBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.field)
                Capsule().fill(color)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: 6)
    }
}

struct ProgressRing<Center: View>: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 9
    var size: CGFloat = 92
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle().stroke(Theme.field, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            center()
        }
        .frame(width: size, height: size)
    }
}

struct MomentumChart: View {
    let weeks: [Int]
    let color: Color

    var body: some View {
        let maxSecs = max(1, weeks.max() ?? 1)
        let labels = momentumLabels(count: weeks.count)
        let avg = weeks.isEmpty ? 0 : weeks.reduce(0, +) / weeks.count
        let trendingUp = weeks.count >= 2 && (weeks.last ?? 0) >= (weeks.first ?? 0)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { idx, secs in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(idx == weeks.count - 1 ? color : color.opacity(0.45))
                            .frame(height: max(4, CGFloat(secs) / CGFloat(maxSecs) * 80))
                        Text(labels[idx]).font(.system(size: 9, weight: .medium)).foregroundStyle(Theme.ink3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100, alignment: .bottom)

            HStack {
                Text("6-week trend").font(.system(size: 11)).foregroundStyle(Theme.ink3)
                Spacer()
                Text("\(trendingUp ? "▲ trending up" : "▼ easing") · avg \(TimeFmt.duration(seconds: avg))/wk")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(trendingUp ? ActivityCategory.getCategoryColor(for: "Sports") : Theme.ink3)
            }
        }
    }

    private func momentumLabels(count: Int) -> [String] {
        guard count > 0 else { return [] }
        return (0..<count).map { $0 == count - 1 ? "Now" : "W\($0 + 1)" }
    }
}
