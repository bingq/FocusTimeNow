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
        
        let predicate = #Predicate<ActivityEvent> { activity in
            activity.startAt >= today && activity.startAt < tomorrow && activity.endAt != nil
        }
        
        let descriptor = FetchDescriptor<ActivityEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt)]
        )
        
        do {
            dailyActivities = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch daily activities: \(error)")
        }
    }
    
    private func loadWeeklyActivities() {
        guard let modelContext = modelContext else { return }
        
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        let predicate = #Predicate<ActivityEvent> { activity in
            activity.startAt >= startOfWeek && activity.startAt < endOfWeek && activity.endAt != nil
        }
        
        let descriptor = FetchDescriptor<ActivityEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt)]
        )
        
        do {
            weeklyActivities = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch weekly activities: \(error)")
        }
    }
    
    // Daily Chart Data
    var dailyChartData: [ChartDataItem] {
        let totals = calculateTotals(for: dailyActivities)
        let grandTotal = totals.values.reduce(0, +)
        
        return totals.compactMap { (category, seconds) in
            guard seconds > 0 else { return nil }
            let hours = Double(seconds) / 3600.0
            let percentage = grandTotal > 0 ? (Double(seconds) / Double(grandTotal)) * 100 : 0
            
            return ChartDataItem(
                category: category,
                hours: hours,
                seconds: seconds,
                percentage: percentage,
                color: ActivityCategory.getCategoryColor(for: category)
            )
        }.sorted { $0.hours > $1.hours }
    }
    
    // Weekly Chart Data  
    var weeklyChartData: [WeeklyChartDataItem] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        var weekData: [WeeklyChartDataItem] = []
        
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayActivities = weeklyActivities.filter {
                $0.startAt >= dayStart && $0.startAt < dayEnd
            }
            
            let dayTotals = calculateTotals(for: dayActivities)
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
            
            let categoryHours = ActivityCategory.defaultCategories.map { category in
                CategoryHours(
                    category: category.name,
                    hours: Double(dayTotals[category.name] ?? 0) / 3600.0,
                    color: category.color
                )
            }
            
            weekData.append(WeeklyChartDataItem(day: dayName, categoryHours: categoryHours))
        }
        
        return weekData
    }
    
    // Weekly totals for breakdown
    var weeklyTotalData: [ChartDataItem] {
        let totals = calculateTotals(for: weeklyActivities)
        let grandTotal = totals.values.reduce(0, +)
        
        return totals.compactMap { (category, seconds) in
            guard seconds > 0 else { return nil }
            let hours = Double(seconds) / 3600.0
            let percentage = grandTotal > 0 ? (Double(seconds) / Double(grandTotal)) * 100 : 0
            
            return ChartDataItem(
                category: category,
                hours: hours,
                seconds: seconds,
                percentage: percentage,
                color: ActivityCategory.getCategoryColor(for: category)
            )
        }.sorted { $0.hours > $1.hours }
    }
    
    private func calculateTotals(for activities: [ActivityEvent]) -> [String: Int] {
        var totals: [String: Int] = [:]
        
        for activity in activities {
            if let duration = activity.duration {
                totals[activity.category, default: 0] += duration
            }
        }
        
        return totals
    }
}

// Data structures for charts
struct ChartDataItem {
    let category: String
    let hours: Double
    let seconds: Int
    let percentage: Double
    let color: Color
    
    var formattedDuration: String {
        let minutes = seconds / 60
        let hrs = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hrs > 0 {
            return "\(hrs)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct WeeklyChartDataItem {
    let day: String
    let categoryHours: [CategoryHours]
}

struct CategoryHours {
    let category: String
    let hours: Double
    let color: Color
}