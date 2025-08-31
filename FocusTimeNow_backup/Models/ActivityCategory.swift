import Foundation
import SwiftUI

struct ActivityCategory {
    let name: String
    let color: Color
    let icon: String
    
    static let defaultCategories = [
        ActivityCategory(name: "Learning", color: .blue, icon: "book.fill"),
        ActivityCategory(name: "Sports", color: .green, icon: "figure.run"),
        ActivityCategory(name: "Leisure", color: .orange, icon: "gamecontroller.fill"),
        ActivityCategory(name: "Work", color: .purple, icon: "briefcase.fill"),
        ActivityCategory(name: "Waste", color: .red, icon: "tv.fill")
    ]
    
    static func getCategoryColor(for name: String) -> Color {
        return defaultCategories.first { $0.name == name }?.color ?? .gray
    }
    
    static func getCategoryIcon(for name: String) -> String {
        return defaultCategories.first { $0.name == name }?.icon ?? "questionmark.circle.fill"
    }
}