import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class TimelineViewModel {
    private var modelContext: ModelContext?
    var activities: [ActivityEvent] = []
    var ongoingActivity: ActivityEvent?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadTodaysActivities()
    }
    
    func loadTodaysActivities() {
        guard let modelContext = modelContext else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<ActivityEvent> { activity in
            activity.startAt >= today && activity.startAt < tomorrow
        }
        
        let descriptor = FetchDescriptor<ActivityEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )
        
        do {
            activities = try modelContext.fetch(descriptor)
            ongoingActivity = activities.first { $0.isOngoing }
        } catch {
            print("Failed to fetch activities: \(error)")
        }
    }
    
    func startActivity(category: String, title: String = "") {
        guard let modelContext = modelContext else { return }
        
        stopOngoingActivity()
        
        let newActivity = ActivityEvent(
            title: title.isEmpty ? category : title,
            category: category
        )
        
        modelContext.insert(newActivity)
        
        do {
            try modelContext.save()
            loadTodaysActivities()
        } catch {
            print("Failed to save activity: \(error)")
        }
    }
    
    func stopOngoingActivity() {
        guard let ongoing = ongoingActivity else { return }
        ongoing.stop()
        
        do {
            try modelContext?.save()
            loadTodaysActivities()
        } catch {
            print("Failed to stop activity: \(error)")
        }
    }
    
    func deleteActivity(_ activity: ActivityEvent) {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(activity)
        
        do {
            try modelContext.save()
            loadTodaysActivities()
        } catch {
            print("Failed to delete activity: \(error)")
        }
    }
    
    var dailyTotals: [String: Int] {
        var totals: [String: Int] = [:]
        
        for activity in activities {
            if let duration = activity.duration {
                totals[activity.category, default: 0] += duration
            }
        }
        
        return totals
    }
    
    func formattedTotal(for category: String) -> String {
        let seconds = dailyTotals[category] ?? 0
        let minutes = seconds / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}