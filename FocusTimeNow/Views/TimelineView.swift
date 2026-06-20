import SwiftUI
import SwiftData

// MARK: - Today (home)

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TimelineViewModel()
    @State private var sheetMode: SheetMode?
    @State private var showCoach = false
    @State private var linkTarget: LinkTarget?

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bgApp.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                TodayRail(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                ScrollView {
                    VStack(spacing: 12) {
                        if showCoach {
                            GestureCoachCard {
                                viewModel.coachDismissed = true
                                withAnimation { showCoach = false }
                            }
                        }

                        if let ongoing = viewModel.ongoingActivity {
                            OngoingCard(activity: ongoing,
                                        project: viewModel.project(for: ongoing),
                                        onOpen: { viewModel.shouldShowFullScreenTimer = true },
                                        onStop: { viewModel.stopOngoingActivity() },
                                        onLink: { linkTarget = LinkTarget(activity: ongoing) })
                        }

                        ActivityListSection(viewModel: viewModel,
                                            onEdit: { sheetMode = .edit(activity: $0) },
                                            onGap: { start, end in sheetMode = .gap(start: start, end: end) })
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .frame(maxHeight: .infinity)

                StartArea(viewModel: viewModel,
                          onTapCategory: { viewModel.startActivity(category: $0) },
                          onHoldCategory: { sheetMode = .start(category: $0) })
            }

            if let toast = viewModel.toast {
                ToastView(toast: toast)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            showCoach = !viewModel.coachDismissed
        }
        .onChange(of: viewModel.toast?.id) { _, _ in
            guard viewModel.toast != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation { viewModel.toast = nil }
            }
        }
        .sheet(item: $sheetMode) { mode in
            ActivitySheet(mode: mode, viewModel: viewModel)
        }
        .sheet(item: $linkTarget) { target in
            ProjectPickerSheet(
                activityLabel: linkLabel(for: target.activity),
                onPick: { project in viewModel.linkProject(project, to: target.activity) }
            )
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowFullScreenTimer) {
            if let ongoing = viewModel.ongoingActivity {
                FullScreenTimerView(activity: ongoing, viewModel: viewModel)
            }
        }
    }

    private func linkLabel(for activity: ActivityEvent) -> String {
        let cat = ActivityCategory.category(for: activity.category)
        let title = activity.title.isEmpty ? cat.name : activity.title
        return "\(title) · \(cat.name) · \(activity.formattedDuration)"
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Today")
                    .font(.system(size: 30, weight: .heavy)).tracking(-0.6)
                    .foregroundStyle(Theme.ink)
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 13)).foregroundStyle(Theme.ink2)
            }
            Spacer()
            Button {
                withAnimation { showCoach = true }
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink2)
                    .frame(width: 28, height: 28)
                    .background(Theme.field)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}

// MARK: - Today rail (total + proportion bar)

private struct TodayRail: View {
    let viewModel: TimelineViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(viewModel.totalTrackedSeconds > 0
                         ? TimeFmt.duration(seconds: viewModel.totalTrackedSeconds) : "0m")
                        .font(.system(size: 23, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                    Text("tracked")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink2)
                }
                Spacer()
                if viewModel.wasteSeconds > 0 {
                    HStack(spacing: 5) {
                        Circle().fill(ActivityCategory.getCategoryColor(for: "Waste"))
                            .frame(width: 7, height: 7)
                        Text("\(TimeFmt.duration(seconds: viewModel.wasteSeconds)) gray")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(ActivityCategory.getCategoryColor(for: "Waste"))
                    }
                }
            }
            ProportionBar(segments: viewModel.proportionSegments)
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }
}

private struct ProportionBar: View {
    let segments: [ProportionSegment]

    var body: some View {
        GeometryReader { geo in
            if segments.isEmpty {
                RoundedRectangle(cornerRadius: 6).fill(Theme.field)
            } else {
                let gap: CGFloat = 2
                let totalGaps = gap * CGFloat(max(0, segments.count - 1))
                let usable = max(0, geo.size.width - totalGaps)
                HStack(spacing: gap) {
                    ForEach(segments) { seg in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(seg.color)
                            .frame(width: usable * seg.fraction)
                    }
                }
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Ongoing card

private struct OngoingCard: View {
    let activity: ActivityEvent
    let project: Project?
    let onOpen: () -> Void
    let onStop: () -> Void
    let onLink: () -> Void
    @State private var elapsed: TimeInterval = 0
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let cat = ActivityCategory.category(for: activity.category)
        VStack(spacing: 10) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    Image(systemName: cat.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(cat.color)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Now · \(cat.name)")
                            .font(.system(size: 11, weight: .bold)).tracking(0.4)
                            .foregroundStyle(cat.color)
                        Text(activity.title.isEmpty ? cat.name : activity.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("running \(TimeFmt.clock(elapsed))")
                            .font(.system(size: 13)).monospacedDigit()
                            .foregroundStyle(Theme.ink2)
                    }
                    Spacer()
                    Button(action: onStop) {
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2).fill(.white).frame(width: 9, height: 9)
                            Text("Stop").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(Theme.ink)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .buttonStyle(.plain)

            HStack {
                if let project {
                    HStack(spacing: 5) {
                        Circle().fill(cat.color).frame(width: 6, height: 6)
                        Text(project.name).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.ink2)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Theme.card)
                    .clipShape(Capsule())
                }
                Button(action: onLink) {
                    Label(project == nil ? "Link to a project" : "Change project", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(cat.color)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(14)
        .background(cat.color.tinted(0.14))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .onAppear { elapsed = Date().timeIntervalSince(activity.startAt) }
        .onReceive(tick) { _ in elapsed = Date().timeIntervalSince(activity.startAt) }
    }
}

// MARK: - Activity list

private struct ActivityListSection: View {
    let viewModel: TimelineViewModel
    let onEdit: (ActivityEvent) -> Void
    let onGap: (Date, Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.ongoingActivity != nil ? "EARLIER TODAY" : "TODAY")
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(Theme.ink3)
                .padding(.leading, 2)

            let entries = viewModel.entries
            if entries.isEmpty {
                Text("Nothing logged yet.\nTap a category below to start.")
                    .font(.system(size: 14)).foregroundStyle(Theme.ink2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else {
                ForEach(entries) { entry in
                    switch entry {
                    case .activity(let a):
                        let proj = viewModel.project(for: a)
                        SwipeRow(activity: a,
                                 project: proj,
                                 goalName: proj.flatMap { viewModel.goalName(for: $0) },
                                 goalColor: proj.flatMap { viewModel.goalColor(for: $0) },
                                 onTap: { onEdit(a) })
                    case .gap(_, let start, let end):
                        GapRow(start: start, end: end) { onGap(start, end) }
                    }
                }
            }
        }
    }
}

private struct GapRow: View {
    let start: Date
    let end: Date
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("+")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Theme.ink3)
                    .frame(width: 36, height: 36)
                    .background(Theme.bgApp)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Theme.hair, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(TimeFmt.duration(end.timeIntervalSince(start))) untracked")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink2)
                    Text("\(TimeFmt.clock12(start)) – \(TimeFmt.clock12(end)) · what were you doing?")
                        .font(.system(size: 12)).foregroundStyle(Theme.ink3)
                }
                Spacer()
                Text("tap to fill").font(.system(size: 12)).foregroundStyle(Theme.ink3)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.hair, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Swipeable activity row

private struct SwipeRow: View {
    let activity: ActivityEvent
    let project: Project?
    let goalName: String?
    let goalColor: Color?
    let onTap: () -> Void

    var body: some View {
        let cat = ActivityCategory.category(for: activity.category)
        // With a project, show the project name and keep the category in the
        // sub-line. Without one, the category name is the title, so drop the
        // redundant category suffix after the time.
        let title = project?.name ?? cat.name
        let subline = project != nil ? "\(activity.timeRange) · \(cat.name)" : activity.timeRange

        Button(action: onTap) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 5).fill(cat.color)
                    .frame(width: 9, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                    Text(subline)
                        .font(.system(size: 12)).foregroundStyle(Theme.ink2)
                    if let goalName {
                        HStack(spacing: 5) {
                            Circle().fill(goalColor ?? cat.color).frame(width: 5, height: 5)
                            Text(goalName).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.ink2)
                        }
                    }
                }
                Spacer()
                Text(activity.formattedDuration)
                    .font(.system(size: 14, weight: .bold)).monospacedDigit()
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Start area (ranked "usually" list + category grid)

private struct StartArea: View {
    let viewModel: TimelineViewModel
    let onTapCategory: (String) -> Void
    let onHoldCategory: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var running: Bool { viewModel.ongoingActivity != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            categoryGrid
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.bgApp)
    }

    private var header: some View {
        Group {
            if running {
                (Text("Tap to ") + Text("switch instantly").foregroundColor(ActivityCategory.getCategoryColor(for: "Learning")) + Text(" →"))
            } else {
                Text("Start something →")
            }
        }
        .font(.system(size: 11, weight: .bold)).tracking(0.6)
        .foregroundStyle(Theme.ink3)
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(ActivityCategory.defaultCategories) { cat in
                CategoryChip(cat: cat,
                             onTap: { onTapCategory(cat.name) },
                             onHold: { onHoldCategory(cat.name) })
            }
        }
    }
}

// MARK: - Link target wrapper (project picker sheet routing)

struct LinkTarget: Identifiable {
    let activity: ActivityEvent
    var id: UUID { activity.id }
}

private struct CategoryChip: View {
    let cat: ActivityCategory
    let onTap: () -> Void
    let onHold: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: cat.icon)
                .font(.system(size: 17))
                .foregroundStyle(cat.color)
                .frame(width: 30, height: 30)
            Text(cat.name)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cat.color.tinted(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture { onTap() }
        .onLongPressGesture(minimumDuration: Theme.longPress) {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
            onHold()
        }
    }
}

// MARK: - Gesture coach

private struct GestureCoachCard: View {
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Quick gestures")
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            coachLine("bolt.fill", "Tap any chip to switch", "no need to stop first; the current session logs automatically.")
            coachLine("hand.draw.fill", "Swipe a row", "left to delete, right to repeat it.")
            coachLine("clock.fill", "Long-press a chip", "to backdate (\u{201C}started 10 min ago\u{201D}).")
            coachLine("plus", "Tap a dashed gap", "to fill untracked time.")
        }
        .padding(14)
        .background(Color(hex: "1B1B1D"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }

    private func coachLine(_ icon: String, _ bold: String, _ rest: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 18)
            (Text(bold).fontWeight(.bold).foregroundColor(.white)
             + Text(" — \(rest)").foregroundColor(.white.opacity(0.7)))
                .font(.system(size: 13))
        }
    }
}

// MARK: - Toast

private struct ToastView: View {
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.icon).font(.system(size: 12))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(toast.color)
                .clipShape(Circle())
            Text(toast.text).font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(Color(hex: "1B1B1D"))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
}

// MARK: - Full-screen Pomodoro Timer (soft rounds: focus → break → complete)

struct FullScreenTimerView: View {
    @Bindable var activity: ActivityEvent
    let viewModel: TimelineViewModel
    @Environment(\.dismiss) private var dismiss

    enum Phase { case focus, breakTime, complete }

    @State private var phase: Phase = .focus
    @State private var now = Date()
    @State private var roundsCompleted = 0
    @State private var breakStartedAt: Date?
    @State private var paused = false
    @State private var pauseStartedAt: Date?
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Focused time excludes pauses & breaks (start is shifted forward for both).
    private var totalFocused: TimeInterval { max(0, now.timeIntervalSince(activity.startAt)) }
    private var roundElapsed: TimeInterval { totalFocused - Double(roundsCompleted) * Theme.focusRoundSeconds }
    private var roundRemaining: TimeInterval { max(0, Theme.focusRoundSeconds - roundElapsed) }
    private var breakRemaining: TimeInterval {
        guard let breakStartedAt else { return Theme.breakSeconds }
        return max(0, Theme.breakSeconds - now.timeIntervalSince(breakStartedAt))
    }

    var body: some View {
        ZStack {
            Color(hex: "0C0C0F").ignoresSafeArea()
            switch phase {
            case .focus: focusView
            case .breakTime: breakView
            case .complete: completeView
            }
        }
        .statusBarHidden()
        .onAppear { now = Date() }
        .onReceive(tick) { _ in advance() }
    }

    // MARK: Focus round

    private var focusView: some View {
        let cat = ActivityCategory.category(for: activity.category)
        let chipLabel = activity.title.isEmpty ? cat.name : activity.title
        return VStack(spacing: 0) {
            Spacer()
            chip(icon: cat.icon, text: chipLabel, color: cat.color)
            Text("🍅 FOCUS · ROUND \(roundsCompleted + 1)")
                .font(.system(size: 12, weight: .bold)).tracking(1.5)
                .foregroundStyle(cat.color)
                .padding(.top, 18)

            countdownRing(remaining: roundRemaining, total: Theme.focusRoundSeconds, color: cat.color,
                          subtitle: paused ? "paused" : "break in \(Int(roundRemaining / 60)) min")
                .padding(.top, 12)

            roundDots(color: cat.color).padding(.top, 18)

            Text("\(roundsCompleted) round\(roundsCompleted == 1 ? "" : "s") done today · \(TimeFmt.duration(seconds: roundsCompleted * Int(Theme.focusRoundSeconds))) focused")
                .font(.system(size: 13)).foregroundStyle(Color(hex: "9A9AA2"))
                .padding(.top, 16)

            Spacer()

            HStack(spacing: 12) {
                pillButton(paused ? "Resume" : "Pause", systemImage: paused ? "play.fill" : "pause.fill",
                           bg: Color.white.opacity(0.12), fg: .white, action: togglePause)
                holdToEndButton
            }
            .padding(.bottom, 8)

            Button { dismiss() } label: {
                Text("Minimize").font(.system(size: 13)).foregroundStyle(Color(hex: "6A6A72"))
            }
            .padding(.bottom, 6)

            Text("Pomodoro auto-pauses for a break at 0:00")
                .font(.system(size: 12)).foregroundStyle(Color(hex: "6A6A72"))
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Break

    private var breakView: some View {
        let green = ActivityCategory.getCategoryColor(for: "Sports")
        return VStack(spacing: 0) {
            Spacer()
            chip(icon: "cup.and.saucer.fill", text: "Break", color: green)
            Text("● SHORT BREAK · STRETCH")
                .font(.system(size: 12, weight: .bold)).tracking(1.5)
                .foregroundStyle(green)
                .padding(.top, 18)

            countdownRing(remaining: breakRemaining, total: Theme.breakSeconds, color: green,
                          subtitle: "round \(roundsCompleted + 1) next")
                .padding(.top, 12)

            Text("\(roundsCompleted) of \(roundsCompleted + 1) rounds done · \(TimeFmt.duration(seconds: roundsCompleted * Int(Theme.focusRoundSeconds))) focused 🍅")
                .font(.system(size: 13)).foregroundStyle(Color(hex: "9A9AA2"))
                .padding(.top, 22)

            Spacer()

            HStack(spacing: 12) {
                pillButton("Skip break", systemImage: "play.fill",
                           bg: Color.white.opacity(0.12), fg: .white) { endBreak() }
                pillButton("End session", systemImage: nil,
                           bg: Theme.danger.opacity(0.16), fg: Theme.danger) { endSessionFromBreak() }
            }
            .padding(.bottom, 8)

            Text("Next focus round starts automatically")
                .font(.system(size: 12)).foregroundStyle(Color(hex: "6A6A72"))
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Complete

    private var completeView: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<max(1, roundsCompleted), id: \.self) { _ in
                    Text("🍅").font(.system(size: 26))
                }
            }
            Text("\(roundsCompleted) round\(roundsCompleted == 1 ? "" : "s") complete")
                .font(.system(size: 24, weight: .heavy)).foregroundStyle(.white)
                .padding(.top, 18)

            (Text(TimeFmt.duration(seconds: Int(totalFocused))).font(.system(size: 15, weight: .bold))
             + Text(" focused on").font(.system(size: 15)))
                .foregroundStyle(Color(hex: "C4C4CC"))
                .padding(.top, 6)
            Text(completeSubtitle)
                .font(.system(size: 14)).foregroundStyle(Color(hex: "9A9AA2"))

            HStack(spacing: 7) {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                Text("Logged to timeline & goal progress").font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(ActivityCategory.getCategoryColor(for: "Sports"))
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(ActivityCategory.getCategoryColor(for: "Sports").opacity(0.16))
            .clipShape(Capsule())
            .padding(.top, 22)

            Spacer()

            HStack(spacing: 12) {
                pillButton("Done", systemImage: nil, bg: Color.white.opacity(0.12), fg: .white) {
                    viewModel.stopOngoingActivity(); dismiss()
                }
                pillButton("One more round", systemImage: nil, bg: .white, fg: Theme.ink) {
                    now = Date(); phase = .focus
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }

    private var completeSubtitle: String {
        let cat = ActivityCategory.category(for: activity.category)
        let title = activity.title.isEmpty ? cat.name : activity.title
        if let project = viewModel.project(for: activity), let goal = viewModel.goalName(for: project) {
            return "\(project.name) · \(goal)"
        }
        return "\(title) · \(cat.name)"
    }

    // MARK: Shared chrome

    private func chip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(.white)
                .frame(width: 26, height: 26).background(color).clipShape(Circle())
            Text(text).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private func countdownRing(remaining: TimeInterval, total: TimeInterval, color: Color, subtitle: String) -> some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.10), lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0, min(1, remaining / total)))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.4), value: remaining)
            VStack(spacing: 4) {
                Text(TimeFmt.clock(remaining))
                    .font(.system(size: 46, weight: .light)).monospacedDigit()
                    .foregroundStyle(.white).contentTransition(.numericText())
                Text(subtitle).font(.system(size: 12)).foregroundStyle(Color(hex: "9A9AA2"))
            }
        }
        .frame(width: 210, height: 210)
    }

    private func roundDots(color: Color) -> some View {
        let total = max(4, roundsCompleted + 1)
        return HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < roundsCompleted ? color : (i == roundsCompleted ? color.opacity(0.6) : Color.white.opacity(0.18)))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func pillButton(_ title: String, systemImage: String?, bg: Color, fg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemImage { Image(systemName: systemImage).font(.system(size: 12)) }
                Text(title).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(fg)
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(bg)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var holdToEndButton: some View {
        ZStack {
            Capsule().fill(Theme.danger.opacity(0.16))
            GeometryReader { geo in
                Capsule().fill(Theme.danger.opacity(0.32))
                    .frame(width: geo.size.width * holdProgress)
            }
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 2).fill(Theme.danger).frame(width: 9, height: 9)
                Text("Hold to end").font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Theme.danger)
        }
        .frame(height: 44)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 20)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isHolding { beginHold() } }
                .onEnded { _ in endHold() }
        )
    }

    // MARK: Transitions

    private func advance() {
        guard !paused else { return }
        now = Date()
        switch phase {
        case .focus:
            if roundRemaining <= 0 { enterBreak() }
        case .breakTime:
            if breakRemaining <= 0 { endBreak() }
        case .complete:
            break
        }
    }

    private func enterBreak() {
        roundsCompleted += 1
        breakStartedAt = Date()
        phase = .breakTime
    }

    /// Skip or finish a break: exclude the break time from the logged session, resume focus.
    private func endBreak() {
        if let breakStartedAt {
            viewModel.extendStart(of: activity, by: Date().timeIntervalSince(breakStartedAt))
        }
        breakStartedAt = nil
        now = Date()
        phase = .focus
    }

    private func endSessionFromBreak() {
        if let breakStartedAt {
            viewModel.extendStart(of: activity, by: Date().timeIntervalSince(breakStartedAt))
        }
        breakStartedAt = nil
        now = Date()
        phase = .complete
    }

    private func togglePause() {
        if paused {
            if let started = pauseStartedAt {
                viewModel.extendStart(of: activity, by: Date().timeIntervalSince(started))
            }
            pauseStartedAt = nil
            paused = false
            now = Date()
        } else {
            pauseStartedAt = Date()
            paused = true
        }
    }

    private func beginHold() {
        isHolding = true
        withAnimation(.linear(duration: Theme.holdToStop)) { holdProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + Theme.holdToStop) {
            if isHolding { completeStop() }
        }
    }

    private func endHold() {
        guard isHolding else { return }
        isHolding = false
        withAnimation(.easeOut(duration: 0.22)) { holdProgress = 0 }
    }

    private func completeStop() {
        isHolding = false
        holdProgress = 0
        now = Date()
        phase = .complete
    }
}
