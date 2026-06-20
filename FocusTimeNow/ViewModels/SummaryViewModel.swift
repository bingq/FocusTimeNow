import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class SummaryViewModel {
    private var modelContext: ModelContext?
    var dailyActivities: [ActivityEvent] = []
    var weeklyActivities: [ActivityEvent] = []

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
    }

    func loadData() {
        loadDailyActivities()
        loadWeeklyActivities()
    }

    private func loadDailyActivities() {
        guard let modelContext = modelContext else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let predicate = #Predicate<ActivityEvent> { a in
            a.startAt >= today && a.startAt < tomorrow && a.endAt != nil
        }
        let descriptor = FetchDescriptor<ActivityEvent>(predicate: predicate, sortBy: [SortDescriptor(\.startAt)])
        dailyActivities = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func loadWeeklyActivities() {
        guard let modelContext = modelContext else { return }
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        let predicate = #Predicate<ActivityEvent> { a in
            a.startAt >= startOfWeek && a.startAt < endOfWeek && a.endAt != nil
        }
        let descriptor = FetchDescriptor<ActivityEvent>(predicate: predicate, sortBy: [SortDescriptor(\.startAt)])
        weeklyActivities = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Daily

    var dailyChartData: [ChartDataItem] {
        buildChartData(from: dailyActivities)
    }

    var dailyTotalSeconds: Int {
        dailyActivities.compactMap(\.duration).reduce(0, +)
    }

    var topDaily: ChartDataItem? { dailyChartData.first }

    var dailyWasteSeconds: Int {
        dailyActivities.filter { $0.category == "Waste" }.compactMap(\.duration).reduce(0, +)
    }

    var dailyWastePercent: Int {
        guard dailyTotalSeconds > 0 else { return 0 }
        return Int((Double(dailyWasteSeconds) / Double(dailyTotalSeconds) * 100).rounded())
    }

    // MARK: - Weekly

    var weekDays: [WeekDayDatum] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let symbols = ["S", "M", "T", "W", "T", "F", "S"] // mapped by weekday component below
        let fullNames = calendar.weekdaySymbols

        var result: [WeekDayDatum] = []
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let acts = weeklyActivities.filter { $0.startAt >= dayStart && $0.startAt < dayEnd }

            var totals: [String: Int] = [:]
            for a in acts { if let d = a.duration { totals[a.category, default: 0] += d } }

            let segs = ActivityCategory.defaultCategories.compactMap { cat -> WeekSegment? in
                let secs = totals[cat.name] ?? 0
                guard secs > 0 else { return nil }
                return WeekSegment(category: cat.name, color: cat.color, seconds: secs)
            }
            let weekdayIndex = calendar.component(.weekday, from: day) - 1
            result.append(WeekDayDatum(
                index: i,
                label: symbols[weekdayIndex],
                fullName: fullNames[weekdayIndex],
                segments: segs,
                totalSeconds: segs.reduce(0) { $0 + $1.seconds }
            ))
        }
        return result
    }

    var weekTotalSeconds: Int {
        weeklyActivities.compactMap(\.duration).reduce(0, +)
    }

    var weeklyTotalData: [ChartDataItem] {
        buildChartData(from: weeklyActivities)
    }

    var topWeekly: ChartDataItem? { weeklyTotalData.first }

    var weeklyDailyAverageSeconds: Int {
        weekTotalSeconds / 7
    }

    // MARK: - Shared

    private func buildChartData(from activities: [ActivityEvent]) -> [ChartDataItem] {
        var totals: [String: Int] = [:]
        for a in activities { if let d = a.duration { totals[a.category, default: 0] += d } }
        let grand = totals.values.reduce(0, +)
        return totals.compactMap { (category, seconds) in
            guard seconds > 0 else { return nil }
            return ChartDataItem(
                category: category,
                hours: Double(seconds) / 3600,
                seconds: seconds,
                percentage: grand > 0 ? Double(seconds) / Double(grand) * 100 : 0,
                color: ActivityCategory.getCategoryColor(for: category)
            )
        }.sorted { $0.seconds > $1.seconds }
    }
}

// MARK: - Data structures

struct ChartDataItem: Identifiable {
    let category: String
    let hours: Double
    let seconds: Int
    let percentage: Double
    let color: Color
    var id: String { category }
    var formattedDuration: String { TimeFmt.duration(seconds: seconds) }
}

struct WeekSegment: Identifiable {
    let category: String
    let color: Color
    let seconds: Int
    var id: String { category }
    var formattedDuration: String { TimeFmt.duration(seconds: seconds) }
}

struct WeekDayDatum: Identifiable {
    let index: Int
    let label: String
    let fullName: String
    let segments: [WeekSegment]
    let totalSeconds: Int
    var id: Int { index }
    var hours: Double { Double(totalSeconds) / 3600 }
}
