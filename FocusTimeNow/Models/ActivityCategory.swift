import Foundation
import SwiftUI

// MARK: - Hex Color support

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r, g, b, a: Double
        switch s.count {
        case 8: // RRGGBBAA
            r = Double((rgb & 0xFF000000) >> 24) / 255
            g = Double((rgb & 0x00FF0000) >> 16) / 255
            b = Double((rgb & 0x0000FF00) >> 8) / 255
            a = Double(rgb & 0x000000FF) / 255
        default: // RRGGBB
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Mix this color over white by the given fraction (0...1), e.g. tinted chip backgrounds.
    func tinted(_ fraction: Double = 0.18) -> Color {
        Color.white.blend(with: self, fraction: fraction)
    }

    func blend(with other: Color, fraction: Double) -> Color {
        #if canImport(UIKit)
        let f = max(0, min(1, fraction))
        let c1 = UIColor(self), c2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(.sRGB,
                     red: Double(r1 + (r2 - r1) * f),
                     green: Double(g1 + (g2 - g1) * f),
                     blue: Double(b1 + (b2 - b1) * f),
                     opacity: Double(a1 + (a2 - a1) * f))
        #else
        return self
        #endif
    }
}

// MARK: - Design tokens (warm neutral surfaces; red reserved for Stop/Delete)

enum Theme {
    static let bgApp = Color(hex: "F3F2EF")
    static let card = Color(hex: "FFFFFF")
    static let field = Color(hex: "EEEDEA")
    static let hair = Color(hex: "E7E5E0")
    static let ink = Color(hex: "1B1B1D")
    static let ink2 = Color(hex: "6C6C72")
    static let ink3 = Color(hex: "A2A1A8")
    static let danger = Color(hex: "E5484D")

    // motion / thresholds
    static let holdToStop: TimeInterval = 0.65
    static let longPress: TimeInterval = 0.43
    static let gapThresholdMinutes = 10

    // radii
    static let radius: CGFloat = 18
    static let radiusSm: CGFloat = 13
}

// MARK: - Categories
// Palette concept: aligned time is colorful, Waste is gray.

struct ActivityCategory: Identifiable {
    let name: String
    let color: Color
    let icon: String

    var id: String { name }

    static let defaultCategories = [
        ActivityCategory(name: "Learning", color: Color(hex: "2E6BE6"), icon: "book.fill"),
        ActivityCategory(name: "Sports", color: Color(hex: "1FA567"), icon: "figure.run"),
        ActivityCategory(name: "Leisure", color: Color(hex: "E0962E"), icon: "gamecontroller.fill"),
        ActivityCategory(name: "Work", color: Color(hex: "7A5AF0"), icon: "briefcase.fill"),
        ActivityCategory(name: "Life", color: Color(hex: "DB5A92"), icon: "heart.fill"),
        ActivityCategory(name: "Waste", color: Color(hex: "9AA0AC"), icon: "tv.fill")
    ]

    static func category(for name: String) -> ActivityCategory {
        defaultCategories.first { $0.name == name }
            ?? ActivityCategory(name: name, color: .gray, icon: "questionmark.circle.fill")
    }

    static func getCategoryColor(for name: String) -> Color {
        category(for: name).color
    }

    static func getCategoryIcon(for name: String) -> String {
        category(for: name).icon
    }

    /// Suggested default title when starting a category quickly.
    static func defaultTitle(for name: String) -> String {
        switch name {
        case "Learning": return "Swift study"
        case "Sports": return "Running"
        case "Leisure": return "Reading"
        case "Work": return "Email triage"
        case "Life": return "Family time"
        case "Waste": return "Short Videos"
        default: return name
        }
    }
}
