import SwiftUI

struct ContentView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("Today")
                }

            SummaryView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Summary")
                }
        }
        .tint(ActivityCategory.getCategoryColor(for: "Learning"))
    }
}
