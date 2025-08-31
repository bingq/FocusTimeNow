import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TimelineViewModel()
    @State private var showEditSheet = false
    @State private var selectedActivity: ActivityEvent?
    @State private var showProjectSelection = false
    @State private var selectedCategory: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let ongoing = viewModel.ongoingActivity {
                    OngoingActivityBanner(activity: ongoing) {
                        viewModel.stopOngoingActivity()
                    }
                }
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.activities, id: \.id) { activity in
                            ActivityRow(activity: activity) {
                                selectedActivity = activity
                                showEditSheet = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                DailySummaryView(viewModel: viewModel)
                
                CategoryButtonsView { category in
                    selectedCategory = category
                    showProjectSelection = true
                }
            }
            .navigationTitle("Timeline")
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .sheet(isPresented: $showEditSheet) {
                if let activity = selectedActivity {
                    EditActivityView(activity: activity) {
                        viewModel.loadTodaysActivities()
                    }
                }
            }
            .sheet(isPresented: $showProjectSelection) {
                ProjectSelectionView(category: selectedCategory) { projectId in
                    viewModel.startActivity(category: selectedCategory, projectId: projectId)
                }
            }
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityEvent
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: ActivityCategory.getCategoryIcon(for: activity.category))
                        .foregroundColor(ActivityCategory.getCategoryColor(for: activity.category))
                        .frame(width: 20)
                    
                    Text(activity.title.isEmpty ? activity.category : activity.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(activity.timeRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(activity.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(ActivityCategory.getCategoryColor(for: activity.category).opacity(0.2))
                        .foregroundColor(ActivityCategory.getCategoryColor(for: activity.category))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text(activity.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
}

struct OngoingActivityBanner: View {
    let activity: ActivityEvent
    let onStop: () -> Void
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Current Activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: ActivityCategory.getCategoryIcon(for: activity.category))
                        .foregroundColor(ActivityCategory.getCategoryColor(for: activity.category))
                    
                    Text(activity.title.isEmpty ? activity.category : activity.title)
                        .font(.headline)
                }
                
                Text(formatElapsedTime())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Stop", action: onStop)
                .buttonStyle(.bordered)
                .foregroundColor(.red)
        }
        .padding()
        .background(ActivityCategory.getCategoryColor(for: activity.category).opacity(0.1))
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(activity.startAt)
        }
    }
    
    private func formatElapsedTime() -> String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct CategoryButtonsView: View {
    let onCategorySelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(Array(ActivityCategory.defaultCategories.prefix(3)), id: \.name) { category in
                    CategoryButton(category: category) {
                        onCategorySelected(category.name)
                    }
                }
            }
            
            HStack(spacing: 12) {
                ForEach(Array(ActivityCategory.defaultCategories.suffix(2)), id: \.name) { category in
                    CategoryButton(category: category) {
                        onCategorySelected(category.name)
                    }
                }
                
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}

struct CategoryButton: View {
    let category: ActivityCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(category.color)
            .cornerRadius(12)
        }
    }
}

struct DailySummaryView: View {
    let viewModel: TimelineViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Summary")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ActivityCategory.defaultCategories, id: \.name) { category in
                        VStack(spacing: 4) {
                            Text(category.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.formattedTotal(for: category.name))
                                .font(.headline)
                                .foregroundColor(category.color)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
}