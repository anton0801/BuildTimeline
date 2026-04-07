import SwiftUI

// MARK: - Projects List
struct ProjectsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var searchText = ""

    var filtered: [Project] {
        searchText.isEmpty ? dataStore.projects
        : dataStore.projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if dataStore.projects.isEmpty {
                BTEmptyState(icon: "folder.badge.plus",
                             title: "No Projects",
                             subtitle: "Tap + to start your first construction project.",
                             actionTitle: "New Project") { showAdd = true }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Simple search
                        BTTextField(placeholder: "Search projects…", text: $searchText, icon: "magnifyingglass")
                            .padding(.horizontal, 16).padding(.top, 8)

                        ForEach(filtered) { project in
                            NavigationLink(destination: ProjectDetailView(project: project)) {
                                ProjectCard(project: project)
                                    .padding(.horizontal, 16)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        Spacer(minLength: 20)
                    }
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.btPrimary)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddProjectView() }
    }
}

struct ProjectCard: View {
    let project: Project
    var body: some View {
        BTCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name).font(.btHeadline()).foregroundColor(.primary)
                        Text(project.type).font(.btCaption()).foregroundColor(.btPrimary)
                    }
                    Spacer()
                    if project.isCompleted {
                        BTBadge(label: "Completed", color: .btSuccess)
                    } else {
                        BTBadge(label: "Active", color: .btInfo)
                    }
                }

                BTProgressBar(progress: project.progress, height: 8)

                HStack {
                    Label(project.progress.btPercent(), systemImage: "chart.bar.fill")
                        .font(.btCaption()).foregroundColor(.btTextSecondary)
                    Spacer()
                    Label(project.budget.btCurrency(), systemImage: "dollarsign.circle.fill")
                        .font(.btCaption()).foregroundColor(.btTextSecondary)
                    Spacer()
                    Label(project.startDate.btShort, systemImage: "calendar")
                        .font(.btCaption()).foregroundColor(.btTextSecondary)
                }
            }
        }
    }
}

// MARK: - Add Project
struct AddProjectView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss

    @State private var name      = ""
    @State private var type      = "Residential"
    @State private var startDate = Date()
    @State private var endDate   = Date().addingTimeInterval(86400 * 90)
    @State private var budget    = ""
    @State private var addDefaultPhases = true
    @State private var error     = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(LinearGradient.btPrimary).frame(width: 64, height: 64)
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 26)).foregroundColor(.white)
                        }
                        Text("New Project").font(.btTitle2()).foregroundColor(.primary)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Project Name", text: $name, icon: "building.2.fill")

                        // Type picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Project Type").font(.btCaption()).foregroundColor(.btTextSecondary)
                            Picker("Type", selection: $type) {
                                ForEach(projectTypes, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
                        }

                        BTTextField(placeholder: "Total Budget (e.g. 150000)", text: $budget,
                                    icon: "dollarsign.circle.fill", keyboardType: .decimalPad)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Start Date").font(.btCaption()).foregroundColor(.btTextSecondary)
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Target End Date").font(.btCaption()).foregroundColor(.btTextSecondary)
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                .labelsHidden()
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
                        }

                        Toggle(isOn: $addDefaultPhases) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add Default Phases").font(.btSubhead())
                                Text("Foundation, Walls, Roof, Electrical, Plumbing, Finishing")
                                    .font(.btCaption()).foregroundColor(.btTextSecondary)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .tint(.btPrimary)
                    }
                    .padding(.horizontal, 20)

                    if !error.isEmpty {
                        Text(error).font(.btSubhead()).foregroundColor(.btDanger)
                            .padding(.horizontal, 20)
                    }

                    BTButton(title: "Create Project", icon: "checkmark.circle.fill") { save() }
                        .padding(.horizontal, 20).padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.btPrimary)
                }
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter a project name."; return
        }
        let budgetVal = Double(budget.replacingOccurrences(of: ",", with: ".")) ?? 0

        var phases: [Phase] = []
        if addDefaultPhases {
            phases = defaultPhaseNames.enumerated().map { i, pName in
                Phase(id: UUID(), name: pName, description: "",
                      startDate: nil, endDate: nil,
                      tasks: [], materials: [], photos: [],
                      isCompleted: false, order: i)
            }
        }

        let project = Project(
            id: UUID(), name: name.trimmingCharacters(in: .whitespaces),
            type: type, startDate: startDate, endDate: endDate,
            budget: budgetVal, phases: phases, expenses: [],
            progress: 0, isCompleted: false, createdAt: Date()
        )
        dataStore.addProject(project)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Project Detail
struct ProjectDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State var project: Project
    @State private var showAddPhase = false
    @State private var showBudget   = false
    @State private var showEdit     = false
    @State private var showDeleteAlert = false

    var currentProject: Project {
        dataStore.projects.first(where: { $0.id == project.id }) ?? project
    }

    var body: some View {
        let proj = currentProject
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Hero card
                BTCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(proj.name).font(.btTitle2()).foregroundColor(.primary)
                                Label(proj.type, systemImage: "tag.fill")
                                    .font(.btCaption()).foregroundColor(.btPrimary)
                            }
                            Spacer()
                            if proj.isCompleted {
                                BTBadge(label: "Complete", color: .btSuccess)
                            } else {
                                BTBadge(label: "Active", color: .btInfo)
                            }
                        }

                        BTProgressBar(progress: proj.progress, height: 10)
                        Text("\(Int(proj.progress * 100))% Complete").font(.btCaption()).foregroundColor(.btTextSecondary)

                        Divider()

                        HStack {
                            dateInfo(label: "Start", date: proj.startDate)
                            Spacer()
                            if let end = proj.endDate {
                                dateInfo(label: "Target End", date: end)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Quick actions
                HStack(spacing: 12) {
                    quickAction(icon: "dollarsign.circle.fill", label: "Budget", color: .btSuccess) {
                        showBudget = true
                    }
                    quickAction(icon: "hammer.fill", label: "Phases", color: .btPrimary) {
                        showAddPhase = true
                    }
                }
                .padding(.horizontal, 16)

                // Phases list
                VStack(spacing: 12) {
                    HStack {
                        BTSectionHeader(title: "Build Phases")
                        Spacer()
                        Button(action: { showAddPhase = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.btPrimary).font(.system(size: 20))
                        }
                    }
                    .padding(.horizontal, 16)

                    if proj.phases.isEmpty {
                        BTCard {
                            BTEmptyState(icon: "rectangle.stack.fill",
                                         title: "No Phases",
                                         subtitle: "Add construction phases to organize your work.")
                        }
                        .padding(.horizontal, 16)
                    } else {
                        ForEach(proj.phases.sorted { $0.order < $1.order }) { phase in
                            NavigationLink(destination: PhaseDetailView(phase: phase, project: proj)) {
                                PhaseRowCard(phase: phase)
                                    .padding(.horizontal, 16)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(proj.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showEdit = true }) {
                        Label("Edit Project", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill").foregroundColor(.btPrimary)
                }
            }
        }
        .sheet(isPresented: $showAddPhase) { AddPhaseView(project: proj) }
        .sheet(isPresented: $showBudget)   { BudgetView(project: proj) }
        .sheet(isPresented: $showEdit)     { EditProjectView(project: proj) }
        .alert("Delete Project", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                dataStore.deleteProject(proj)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete '\(proj.name)' and all its data.")
        }
    }

    func dateInfo(label: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.btCaption()).foregroundColor(.btTextSecondary)
            Text(date.btFormatted).font(.btSubhead()).foregroundColor(.primary)
        }
    }

    func quickAction(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
                Text(label).font(.btSubhead()).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11)).foregroundColor(.btTextSecondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PhaseRowCard: View {
    let phase: Phase
    var body: some View {
        BTCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.phaseColor(for: phase.name).opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: phaseIcon(for: phase.name))
                        .font(.system(size: 18))
                        .foregroundColor(Color.phaseColor(for: phase.name))
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(phase.name).font(.btHeadline()).foregroundColor(.primary)
                        Spacer()
                        if phase.isCompleted {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.btSuccess)
                        }
                    }
                    BTProgressBar(progress: phase.progress, height: 5,
                                  color: Color.phaseColor(for: phase.name))
                    HStack {
                        Text("\(phase.completedTasksCount)/\(phase.tasks.count) tasks")
                            .font(.btCaption()).foregroundColor(.btTextSecondary)
                        Spacer()
                        if let end = phase.endDate {
                            Text(end.btShort).font(.btCaption()).foregroundColor(.btTextSecondary)
                        }
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)).foregroundColor(.btTextSecondary)
            }
        }
    }
}

// MARK: - Edit Project
struct EditProjectView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss
    let project: Project

    @State private var name: String
    @State private var type: String
    @State private var budget: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isCompleted: Bool
    @State private var error = ""

    init(project: Project) {
        self.project = project
        _name        = State(initialValue: project.name)
        _type        = State(initialValue: project.type)
        _budget      = State(initialValue: String(project.budget))
        _startDate   = State(initialValue: project.startDate)
        _endDate     = State(initialValue: project.endDate ?? Date().addingTimeInterval(86400 * 90))
        _isCompleted = State(initialValue: project.isCompleted)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    BTTextField(placeholder: "Project Name", text: $name, icon: "building.2.fill")
                    Picker("Type", selection: $type) {
                        ForEach(projectTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color(.systemBackground)).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))

                    BTTextField(placeholder: "Budget", text: $budget,
                                icon: "dollarsign.circle.fill", keyboardType: .decimalPad)

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Color(.systemBackground)).cornerRadius(12)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Color(.systemBackground)).cornerRadius(12)

                    Toggle("Mark as Completed", isOn: $isCompleted)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Color(.systemBackground)).cornerRadius(12).tint(.btPrimary)

                    if !error.isEmpty { Text(error).foregroundColor(.btDanger) }

                    BTButton(title: "Save Changes", icon: "checkmark.circle.fill") { save() }
                }
                .padding(20)
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.btPrimary)
                }
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { error = "Name required."; return }
        var updated = project
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.type = type
        updated.budget = Double(budget) ?? project.budget
        updated.startDate = startDate
        updated.endDate = endDate
        updated.isCompleted = isCompleted
        dataStore.updateProject(updated)
        dismiss.wrappedValue.dismiss()
    }
}
