import SwiftUI
import SwiftData

// MARK: - Today (home)

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TimelineViewModel()
    @State private var sheetMode: SheetMode?
    @State private var showCoach = false

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bgApp.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 12) {
                        TodayRail(viewModel: viewModel)

                        if showCoach {
                            GestureCoachCard {
                                viewModel.coachDismissed = true
                                withAnimation { showCoach = false }
                            }
                        }

                        if let ongoing = viewModel.ongoingActivity {
                            OngoingCard(activity: ongoing,
                                        onOpen: { viewModel.shouldShowFullScreenTimer = true },
                                        onStop: { viewModel.stopOngoingActivity() })
                        }

                        ActivityListSection(viewModel: viewModel,
                                            onEdit: { sheetMode = .edit(activity: $0) },
                                            onGap: { start, end in sheetMode = .gap(start: start, end: end) })
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }

                StartBar(running: viewModel.ongoingActivity != nil,
                         onTap: { viewModel.startActivity(category: $0) },
                         onHold: { sheetMode = .start(category: $0) })
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
        .fullScreenCover(isPresented: $viewModel.shouldShowFullScreenTimer) {
            if let ongoing = viewModel.ongoingActivity {
                FullScreenTimerView(activity: ongoing, viewModel: viewModel)
            }
        }
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
    let onOpen: () -> Void
    let onStop: () -> Void
    @State private var elapsed: TimeInterval = 0
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let cat = ActivityCategory.category(for: activity.category)
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
            .padding(14)
            .background(cat.color.tinted(0.14))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        }
        .buttonStyle(.plain)
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
                        SwipeRow(activity: a,
                                 onTap: { onEdit(a) },
                                 onRepeat: { viewModel.startActivity(category: a.category) },
                                 onDelete: { viewModel.deleteActivity(a) })
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
    let onTap: () -> Void
    let onRepeat: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @GestureState private var drag: CGFloat = 0

    private let maxReveal: CGFloat = 96
    private let threshold: CGFloat = 52

    var body: some View {
        let cat = ActivityCategory.category(for: activity.category)
        let dx = max(-maxReveal, min(maxReveal, offset + drag))

        ZStack {
            // Underlying actions
            HStack {
                Label("Repeat", systemImage: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ActivityCategory.getCategoryColor(for: "Sports"))
                Spacer()
                Label("Delete", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.danger)
            }
            .padding(.horizontal, 18)

            // Foreground row
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 5).fill(cat.color)
                    .frame(width: 9, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title.isEmpty ? cat.name : activity.title)
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                    Text("\(activity.timeRange) · \(cat.name)")
                        .font(.system(size: 12)).foregroundStyle(Theme.ink2)
                }
                Spacer()
                Text(activity.formattedDuration)
                    .font(.system(size: 14, weight: .bold)).monospacedDigit()
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .offset(x: dx)
            .gesture(
                DragGesture(minimumDistance: 8)
                    .updating($drag) { value, state, _ in state = value.translation.width }
                    .onEnded { value in
                        let final = offset + value.translation.width
                        if final < -threshold { offset = -maxReveal }
                        else if final > threshold { offset = maxReveal }
                        else { offset = 0 }
                    }
            )
            .onTapGesture {
                if offset > threshold { withAnimation { offset = 0 }; onRepeat() }
                else if offset < -threshold { onDelete() }
                else { onTap() }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dx)
    }
}

// MARK: - Start bar (3x2 chip grid)

private struct StartBar: View {
    let running: Bool
    let onTap: (String) -> Void
    let onHold: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if running {
                    (Text("Tap to ") + Text("switch instantly").foregroundColor(ActivityCategory.getCategoryColor(for: "Learning")) + Text(" →"))
                } else {
                    Text("Start something →")
                }
            }
            .font(.system(size: 11, weight: .bold)).tracking(0.6)
            .foregroundStyle(Theme.ink3)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ActivityCategory.defaultCategories) { cat in
                    CategoryChip(cat: cat,
                                 onTap: { onTap(cat.name) },
                                 onHold: { onHold(cat.name) })
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.bgApp)
    }
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
                .background(cat.color.tinted(0.18))
                .clipShape(Circle())
            Text(cat.name)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.hair, lineWidth: 1)
        )
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

// MARK: - Full-screen Timer with hold-to-stop

struct FullScreenTimerView: View {
    @Bindable var activity: ActivityEvent
    let viewModel: TimelineViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var elapsed: TimeInterval = 0
    @State private var paused = false
    @State private var pauseStartedAt: Date?
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let cat = ActivityCategory.category(for: activity.category)
        ZStack {
            Color(hex: "0C0C0F").ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: cat.icon).font(.system(size: 13)).foregroundStyle(.white)
                        .frame(width: 26, height: 26).background(cat.color).clipShape(Circle())
                    Text(cat.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                }

                Text(activity.title.isEmpty ? cat.name : activity.title)
                    .font(.system(size: 15)).foregroundStyle(Color(hex: "9A9AA2"))

                Text(TimeFmt.clock(elapsed))
                    .font(.system(size: 72, weight: .ultraLight, design: .default))
                    .monospacedDigit().tracking(1)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(paused ? "PAUSED" : " ")
                    .font(.system(size: 12, weight: .semibold)).tracking(1.5)
                    .foregroundStyle(Color(hex: "9A9AA2"))

                Spacer()

                holdRing

                HStack(spacing: 12) {
                    Button(action: togglePause) {
                        Label(paused ? "Resume" : "Pause",
                              systemImage: paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18).padding(.vertical, 11)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Button { dismiss() } label: {
                        Text("Minimize")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "9A9AA2"))
                            .padding(.horizontal, 18).padding(.vertical, 11)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)

                Text("Tap to pause · press & hold the ring to stop")
                    .font(.system(size: 12)).foregroundStyle(Color(hex: "6A6A72"))
                    .padding(.bottom, 24)
            }
            .padding()
        }
        .statusBarHidden()
        .onAppear { recomputeElapsed() }
        .onReceive(tick) { _ in if !paused { recomputeElapsed() } }
    }

    private var holdRing: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 7)
            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(Theme.danger, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 5).fill(Theme.danger).frame(width: 26, height: 26)
                Text("HOLD TO STOP")
                    .font(.system(size: 10, weight: .bold)).tracking(1.5)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 150, height: 150)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isHolding { beginHold() } }
                .onEnded { _ in endHold() }
        )
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
        viewModel.stopOngoingActivity()
        dismiss()
    }

    private func togglePause() {
        if paused {
            if let started = pauseStartedAt {
                viewModel.extendStart(of: activity, by: Date().timeIntervalSince(started))
            }
            pauseStartedAt = nil
            paused = false
            recomputeElapsed()
        } else {
            pauseStartedAt = Date()
            paused = true
        }
    }

    private func recomputeElapsed() {
        elapsed = Date().timeIntervalSince(activity.startAt)
    }
}
