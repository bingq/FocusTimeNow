import SwiftUI
import SwiftData

struct ProjectSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: String
    let onProjectSelected: (UUID?) -> Void
    
    @Query private var allProjects: [Project]
    @State private var showingNewProjectSheet = false
    
    private var projectsForCategory: [Project] {
        allProjects.filter { $0.category == category && $0.isActive }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        onProjectSelected(nil)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.gray)
                            Text("No Project")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                if !projectsForCategory.isEmpty {
                    Section("Active Projects") {
                        ForEach(projectsForCategory, id: \.id) { project in
                            Button {
                                onProjectSelected(project.id)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(ActivityCategory.getCategoryColor(for: category))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(project.name)
                                            .foregroundColor(.primary)
                                        
                                        if let description = project.description {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let targetHours = project.targetHours {
                                        Text("\(Int(targetHours))h target")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        showingNewProjectSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Create New Project")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectView(category: category) { newProject in
                    onProjectSelected(newProject.id)
                    dismiss()
                }
            }
        }
    }
}

struct NewProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: String
    let onProjectCreated: (Project) -> Void
    
    @State private var projectName = ""
    @State private var projectDescription = ""
    @State private var targetHours: Double = 10
    @State private var hasTarget = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $projectName)
                    TextField("Description (optional)", text: $projectDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Goal") {
                    Toggle("Set Target Hours", isOn: $hasTarget)
                    
                    if hasTarget {
                        HStack {
                            Text("Target Hours")
                            Spacer()
                            TextField("Hours", value: $targetHours, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createProject()
                    }
                    .fontWeight(.semibold)
                    .disabled(projectName.isEmpty)
                }
            }
        }
    }
    
    private func createProject() {
        let project = Project(
            name: projectName,
            category: category,
            description: projectDescription.isEmpty ? nil : projectDescription,
            targetHours: hasTarget ? targetHours : nil
        )
        
        modelContext.insert(project)
        
        do {
            try modelContext.save()
            onProjectCreated(project)
        } catch {
            print("Failed to create project: \(error)")
        }
    }
}