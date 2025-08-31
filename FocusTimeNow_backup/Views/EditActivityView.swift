import SwiftUI
import SwiftData

struct EditActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let activity: ActivityEvent
    let onSave: () -> Void
    
    @State private var title: String = ""
    @State private var selectedCategory: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var note: String = ""
    @State private var selectedProjectId: UUID? = nil
    @State private var showDeleteAlert = false
    
    @Query private var allProjects: [Project]
    
    private var projectsForCategory: [Project] {
        allProjects.filter { $0.category == selectedCategory && $0.isActive }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Activity Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ActivityCategory.defaultCategories, id: \.name) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.name)
                            }
                            .tag(category.name)
                        }
                    }
                    
                    Picker("Project", selection: $selectedProjectId) {
                        Text("No Project")
                            .tag(nil as UUID?)
                        
                        ForEach(projectsForCategory, id: \.id) { project in
                            Text(project.name)
                                .tag(project.id as UUID?)
                        }
                    }
                }
                
                Section("Timing") {
                    DatePicker("Start Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    
                    if !activity.isOngoing {
                        DatePicker("End Time", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    } else {
                        HStack {
                            Text("End Time")
                            Spacer()
                            Text("Ongoing")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !activity.isOngoing {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(formattedDuration)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Delete Activity") {
                        showDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveActivity()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                setupInitialValues()
            }
            .alert("Delete Activity", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteActivity()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this activity? This action cannot be undone.")
            }
        }
    }
    
    private func setupInitialValues() {
        title = activity.title
        selectedCategory = activity.category
        startDate = activity.startAt
        endDate = activity.endAt ?? Date()
        note = activity.note ?? ""
        selectedProjectId = activity.projectId
    }
    
    private func saveActivity() {
        activity.title = title
        activity.category = selectedCategory
        activity.startAt = startDate
        
        if !activity.isOngoing {
            activity.endAt = endDate
            activity.duration = activity.calculateDuration()
        }
        
        activity.note = note.isEmpty ? nil : note
        activity.projectId = selectedProjectId
        
        do {
            try modelContext.save()
            onSave()
            dismiss()
        } catch {
            print("Failed to save activity: \(error)")
        }
    }
    
    private func deleteActivity() {
        modelContext.delete(activity)
        
        do {
            try modelContext.save()
            onSave()
            dismiss()
        } catch {
            print("Failed to delete activity: \(error)")
        }
    }
    
    private var formattedDuration: String {
        let duration = Int(endDate.timeIntervalSince(startDate))
        let minutes = duration / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}