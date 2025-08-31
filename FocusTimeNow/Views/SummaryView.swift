import SwiftUI
import SwiftData
import Charts

struct SummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SummaryViewModel()
    @State private var selectedPeriod: TimePeriod = .daily
    
    enum TimePeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedPeriod == .daily {
                        DailyChartView(viewModel: viewModel)
                    } else {
                        WeeklyChartView(viewModel: viewModel)
                    }
                    
                    // Detailed breakdown
                    CategoryBreakdownView(viewModel: viewModel, period: selectedPeriod)
                }
                .padding(.bottom)
            }
            .navigationTitle("Summary")
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}

struct DailyChartView: View {
    let viewModel: SummaryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Time Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            if !viewModel.dailyChartData.isEmpty {
                Chart(viewModel.dailyChartData, id: \.category) { item in
                    SectorMark(
                        angle: .value("Duration", item.hours),
                        innerRadius: .ratio(0.4),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .opacity(0.8)
                }
                .frame(height: 250)
                .padding(.horizontal)
                
                // Legend
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(viewModel.dailyChartData, id: \.category) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            Text(item.category)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(item.formattedDuration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                Text("No activities recorded today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct WeeklyChartView: View {
    let viewModel: SummaryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Pattern")
                .font(.headline)
                .padding(.horizontal)
            
            if !viewModel.weeklyChartData.isEmpty {
                Chart {
                    ForEach(viewModel.weeklyChartData, id: \.day) { dayData in
                        ForEach(dayData.categoryHours, id: \.category) { categoryData in
                            BarMark(
                                x: .value("Day", dayData.day),
                                y: .value("Hours", categoryData.hours)
                            )
                            .foregroundStyle(categoryData.color)
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
                
                // Legend
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(ActivityCategory.defaultCategories, id: \.name) { category in
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(category.color)
                                .frame(width: 12, height: 12)
                                .cornerRadius(2)
                            
                            Text(category.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                Text("No activities recorded this week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CategoryBreakdownView: View {
    let viewModel: SummaryViewModel
    let period: SummaryView.TimePeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(period.rawValue) Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            let data = period == .daily ? viewModel.dailyChartData : viewModel.weeklyTotalData
            
            ForEach(data, id: \.category) { item in
                HStack {
                    Image(systemName: ActivityCategory.getCategoryIcon(for: item.category))
                        .foregroundColor(item.color)
                        .frame(width: 24)
                    
                    Text(item.category)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.formattedDuration)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(Int(item.percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}