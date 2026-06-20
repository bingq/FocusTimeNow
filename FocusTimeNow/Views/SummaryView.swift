import SwiftUI
import SwiftData
import Charts

struct SummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SummaryViewModel()
    @State private var selectedPeriod: TimePeriod = .daily

    enum TimePeriod: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Summary")
                    .font(.system(size: 30, weight: .heavy)).tracking(-0.6)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 8)

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16).padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 14) {
                        if selectedPeriod == .daily {
                            DailySummary(viewModel: viewModel)
                        } else {
                            WeeklySummary(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.loadData()
        }
    }
}

// MARK: - Daily

private struct DailySummary: View {
    let viewModel: SummaryViewModel

    var body: some View {
        let data = viewModel.dailyChartData
        let total = viewModel.dailyTotalSeconds

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(total > 0 ? TimeFmt.duration(seconds: total) : "0m")
                    .font(.system(size: 25, weight: .heavy)).monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Text("today").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink2)
            }
            if let top = viewModel.topDaily {
                (Text("Most on ") + Text(top.category).fontWeight(.bold).foregroundColor(top.color)
                 + Text(" · \(top.formattedDuration)"))
                    .font(.system(size: 13)).foregroundStyle(Theme.ink2)
            } else {
                Text("No activities logged yet today.")
                    .font(.system(size: 13)).foregroundStyle(Theme.ink2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Donut
        ZStack {
            if data.isEmpty {
                Circle().stroke(Theme.field, lineWidth: 34).frame(width: 200, height: 200)
            } else {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Duration", item.seconds),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color)
                }
                .frame(width: 200, height: 200)
            }
            VStack(spacing: 2) {
                Text(total > 0 ? TimeFmt.duration(seconds: total) : "0m")
                    .font(.system(size: 22, weight: .heavy)).monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Text("tracked today").font(.system(size: 11)).foregroundStyle(Theme.ink2)
            }
        }
        .padding(.vertical, 8)

        // Awareness bar
        awarenessBar(total: total)

        // Breakdown
        VStack(spacing: 0) {
            if data.isEmpty {
                Text("Log a session and your distribution appears here instantly.")
                    .font(.system(size: 13)).foregroundStyle(Theme.ink2)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
            } else {
                ForEach(Array(data.enumerated()), id: \.element.id) { idx, item in
                    HStack(spacing: 10) {
                        Circle().fill(item.color).frame(width: 11, height: 11)
                        Text(item.category).font(.system(size: 14)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text(item.formattedDuration)
                            .font(.system(size: 14, weight: .semibold)).monospacedDigit()
                            .foregroundStyle(Theme.ink)
                        Text("\(Int(item.percentage))%")
                            .font(.system(size: 12)).monospacedDigit()
                            .foregroundStyle(Theme.ink2).frame(width: 38, alignment: .trailing)
                    }
                    .padding(.vertical, 11)
                    if idx < data.count - 1 { Divider().background(Theme.hair) }
                }
            }
        }
        .padding(.horizontal, 14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }

    @ViewBuilder
    private func awarenessBar(total: Int) -> some View {
        let waste = viewModel.dailyWasteSeconds
        let pct = viewModel.dailyWastePercent
        HStack(spacing: 10) {
            Circle().fill(ActivityCategory.getCategoryColor(for: "Waste")).frame(width: 10, height: 10)
            if waste > 0 {
                (Text("\(pct)% of today was gray. ").fontWeight(.bold)
                    .foregroundColor(ActivityCategory.getCategoryColor(for: "Waste"))
                 + Text("\(TimeFmt.duration(seconds: waste)) on Waste — keep an eye on it.")
                    .foregroundColor(Theme.ink2))
                    .font(.system(size: 13))
            } else {
                (Text("No gray time yet today. ").fontWeight(.bold)
                    .foregroundColor(ActivityCategory.getCategoryColor(for: "Sports"))
                 + Text("Every minute is aligned.").foregroundColor(Theme.ink2))
                    .font(.system(size: 13))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(ActivityCategory.getCategoryColor(for: "Waste").tinted(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Weekly

private struct WeeklySummary: View {
    let viewModel: SummaryViewModel
    @State private var selectedDay: Int?

    var body: some View {
        let days = viewModel.weekDays
        let weekTotal = viewModel.weekTotalSeconds

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(weekTotal > 0 ? TimeFmt.duration(seconds: weekTotal) : "0m")
                    .font(.system(size: 25, weight: .heavy)).monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Text("this week").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink2)
            }
            if let top = viewModel.topWeekly {
                (Text("Most time on ") + Text(top.category).fontWeight(.bold).foregroundColor(top.color)
                 + Text(" · \(top.formattedDuration) · daily avg \(TimeFmt.duration(seconds: viewModel.weeklyDailyAverageSeconds))"))
                    .font(.system(size: 13)).foregroundStyle(Theme.ink2)
            } else {
                Text("No activities logged this week yet.")
                    .font(.system(size: 13)).foregroundStyle(Theme.ink2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: 10) {
            WeeklyBarChart(days: days, selectedDay: $selectedDay)

            if let sel = selectedDay, sel < days.count {
                DayBreakdownPopover(day: days[sel])
            }

            // Legend
            let cols = Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(ActivityCategory.defaultCategories) { cat in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2).fill(cat.color).frame(width: 11, height: 11)
                        Text(cat.name).font(.system(size: 12)).foregroundStyle(Theme.ink2)
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))

        Text("Tap any bar to see that day's exact breakdown.")
            .font(.system(size: 12)).foregroundStyle(Theme.ink3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WeeklyBarChart: View {
    let days: [WeekDayDatum]
    @Binding var selectedDay: Int?

    private let chartHeight: CGFloat = 176

    private var topHours: Double {
        let maxDay = days.map(\.hours).max() ?? 0
        let candidate = max(6, (maxDay).rounded(.up))
        // round up to even number for clean /3 gridlines (0,2,4,6 style)
        return candidate.truncatingRemainder(dividingBy: 2) == 0 ? candidate : candidate + 1
    }

    var body: some View {
        let top = topHours
        let gridValues = stride(from: 0.0, through: top, by: top / 3).map { $0 }

        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                // gridlines + Y labels
                ForEach(gridValues, id: \.self) { v in
                    VStack {
                        HStack(spacing: 4) {
                            Text(v == 0 ? "0" : "\(Int(v))h")
                                .font(.system(size: 9.5)).monospacedDigit()
                                .foregroundStyle(Theme.ink3).frame(width: 18, alignment: .trailing)
                            Rectangle().fill(Theme.hair).frame(height: 1)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(height: chartHeight)
                    .offset(y: -CGFloat(v / top) * chartHeight + chartHeight)
                }

                // bars
                HStack(alignment: .bottom, spacing: 9) {
                    Spacer().frame(width: 18) // align with Y labels gutter
                    ForEach(days) { day in
                        barColumn(day: day, top: top)
                    }
                }
            }
            .frame(height: chartHeight + 16)

            // X axis labels
            HStack(spacing: 9) {
                Spacer().frame(width: 18)
                ForEach(days) { day in
                    Text(day.label)
                        .font(.system(size: 11, weight: selectedDay == day.index ? .bold : .regular))
                        .foregroundStyle(selectedDay == day.index ? Theme.ink : Theme.ink3)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func barColumn(day: WeekDayDatum, top: Double) -> some View {
        let isSelected = selectedDay == day.index
        let isDimmed = selectedDay != nil && !isSelected
        let barHeight = CGFloat(day.hours / top) * chartHeight

        return VStack(spacing: 4) {
            Spacer(minLength: 0)
            if day.totalSeconds > 0 {
                Text(String(format: "%.1fh", day.hours))
                    .font(.system(size: 9.5, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(Theme.ink2)
            }
            VStack(spacing: 0) {
                ForEach(day.segments) { seg in
                    Rectangle()
                        .fill(seg.color)
                        .frame(height: barHeight * CGFloat(seg.seconds) / CGFloat(max(1, day.totalSeconds)))
                }
            }
            .frame(height: max(barHeight, day.totalSeconds > 0 ? 3 : 0))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .opacity(isDimmed ? 0.3 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDay = isSelected ? nil : day.index
            }
        }
    }
}

private struct DayBreakdownPopover: View {
    let day: WeekDayDatum

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.fullName).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                Spacer()
                Text(String(format: "%.1fh total", day.hours))
                    .font(.system(size: 12)).monospacedDigit().foregroundStyle(Color(hex: "9A9AA2"))
            }
            ForEach(day.segments.sorted { $0.seconds > $1.seconds }) { seg in
                HStack(spacing: 8) {
                    Circle().fill(seg.color).frame(width: 9, height: 9)
                    Text(seg.category).font(.system(size: 12)).foregroundStyle(.white)
                    Spacer()
                    Text(seg.formattedDuration).font(.system(size: 12, weight: .medium))
                        .monospacedDigit().foregroundStyle(Color(hex: "C7C7CC"))
                }
            }
        }
        .padding(12)
        .background(Color(hex: "1B1B1D"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
