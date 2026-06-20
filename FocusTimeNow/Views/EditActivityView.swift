import SwiftUI

// MARK: - Sheet routing

enum SheetMode: Identifiable {
    case start(category: String)
    case gap(start: Date, end: Date)
    case edit(activity: ActivityEvent)

    var id: String {
        switch self {
        case .start(let c): return "start-\(c)"
        case .gap(let s, let e): return "gap-\(s.timeIntervalSince1970)-\(e.timeIntervalSince1970)"
        case .edit(let a): return "edit-\(a.id.uuidString)"
        }
    }
}

// MARK: - Shared sheet primitives

private struct GrabHandle: View {
    var body: some View {
        Capsule()
            .fill(Theme.hair)
            .frame(width: 38, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 6)
    }
}

private struct SheetButton: View {
    enum Kind { case primary, plain, resume, danger, ghost }
    let kind: Kind
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(kind == .primary || kind == .resume ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch kind {
        case .primary, .resume: return .white
        case .danger: return Theme.danger
        case .plain: return Theme.ink
        case .ghost: return Theme.ink2
        }
    }
    private var background: Color {
        switch kind {
        case .primary: return ActivityCategory.getCategoryColor(for: "Learning")
        case .resume: return ActivityCategory.getCategoryColor(for: "Sports")
        case .plain: return Theme.card
        case .danger: return Theme.card
        case .ghost: return .clear
        }
    }
}

// MARK: - Container that renders the right sheet for a SheetMode

struct ActivitySheet: View {
    let mode: SheetMode
    let viewModel: TimelineViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            GrabHandle()
            Group {
                switch mode {
                case .start(let category):
                    StartOptionsSheet(category: category) { back in
                        viewModel.startActivity(category: category, backMinutes: back, openTimer: back == 0)
                        dismiss()
                    }
                case .gap(let start, let end):
                    GapFillSheet(start: start, end: end) { category in
                        viewModel.logGap(category: category, start: start, end: end)
                        dismiss()
                    }
                case .edit(let activity):
                    EditActivitySheet(activity: activity, viewModel: viewModel) { dismiss() }
                }
            }
            SheetButton(kind: .ghost, title: "Cancel") { dismiss() }
            .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.bgApp)
        .presentationDetents([.height(detentHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    private var detentHeight: CGFloat {
        switch mode {
        case .start: return 330
        case .gap: return 360
        case .edit: return 360
        }
    }
}

// MARK: - Start options (long-press a chip)

private struct StartOptionsSheet: View {
    let category: String
    let onPick: (_ backMinutes: Int) -> Void

    var body: some View {
        let cat = ActivityCategory.category(for: category)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(cat.color).frame(width: 12, height: 12)
                Text(cat.name).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
            }
            Text("When did this start?")
                .font(.system(size: 13)).foregroundStyle(Theme.ink2)
                .padding(.bottom, 4)

            SheetButton(kind: .primary, title: "Start now") { onPick(0) }
            SheetButton(kind: .plain, title: "Started 10 minutes ago", systemImage: "clock") { onPick(10) }
            SheetButton(kind: .plain, title: "Started 30 minutes ago", systemImage: "clock") { onPick(30) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Gap fill (tap a dashed gap row)

private struct GapFillSheet: View {
    let start: Date
    let end: Date
    let onPick: (_ category: String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fill \(TimeFmt.duration(end.timeIntervalSince(start))) gap")
                .font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
            Text("\(TimeFmt.clock12(start)) – \(TimeFmt.clock12(end)) · what were you doing?")
                .font(.system(size: 13)).foregroundStyle(Theme.ink2)
                .padding(.bottom, 4)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ActivityCategory.defaultCategories) { cat in
                    Button { onPick(cat.name) } label: {
                        VStack(spacing: 6) {
                            Image(systemName: cat.icon).font(.system(size: 20))
                            Text(cat.name).font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(cat.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(cat.color.tinted(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Edit (tap a log row)

private struct EditActivitySheet: View {
    @Bindable var activity: ActivityEvent
    let viewModel: TimelineViewModel
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(activity.title.isEmpty ? activity.category : activity.title)
                .font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
            Text("\(activity.timeRange) · \(activity.formattedDuration)")
                .font(.system(size: 13)).foregroundStyle(Theme.ink2)

            Text("RECATEGORIZE")
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(Theme.ink3)
                .padding(.top, 2)

            HStack(spacing: 8) {
                ForEach(ActivityCategory.defaultCategories) { cat in
                    Button {
                        viewModel.recategorize(activity, to: cat.name)
                    } label: {
                        Image(systemName: cat.icon)
                            .font(.system(size: 17))
                            .foregroundStyle(cat.color)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(cat.color.tinted(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(cat.color, lineWidth: activity.category == cat.name ? 2 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            SheetButton(kind: .resume, title: "Do this again now", systemImage: "arrow.clockwise") {
                viewModel.startActivity(category: activity.category, openTimer: true)
                dismiss()
            }
            SheetButton(kind: .danger, title: "Delete activity") {
                viewModel.deleteActivity(activity)
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
