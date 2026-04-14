import SwiftUI

// MARK: - Task Row (used inside phase)
struct TaskRow: View {
    @EnvironmentObject var dataStore: DataStore
    let task: MainAppTask
    let phase: Phase
    let project: Project
    @State private var showEdit   = false
    @State private var showDelete = false

    var body: some View {
        BTCard(padding: 12) {
            HStack(spacing: 12) {
                // Completion toggle
                Button(action: toggleComplete) {
                    ZStack {
                        Circle()
                            .stroke(task.isCompleted ? Color.btSuccess : Color(.systemGray4), lineWidth: 2)
                            .frame(width: 26, height: 26)
                        if task.isCompleted {
                            Circle().fill(Color.btSuccess).frame(width: 18, height: 18)
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(ScaleButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.btSubhead())
                        .foregroundColor(task.isCompleted ? .btTextSecondary : .primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        BTBadge(label: task.priority.rawValue, color: task.priority.color)
                        if let d = task.deadline {
                            Label(d.btShort, systemImage: "calendar")
                                .font(.btCaption2())
                                .foregroundColor(task.isOverdue ? .btDanger : .btTextSecondary)
                        }
                    }
                }
                Spacer()
                Menu {
                    Button(action: { showEdit = true }) { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive, action: { showDelete = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis").foregroundColor(.btTextSecondary)
                        .padding(8)
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditTaskView(task: task, phase: phase, project: project) }
        .alert("Delete Task", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                dataStore.deleteTask(task, phaseId: phase.id, projectId: project.id)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    func toggleComplete() {
        var updated = task
        updated.isCompleted.toggle()
        dataStore.updateTask(updated, phaseId: phase.id, projectId: project.id)
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    let phase: Phase
    let project: Project

    @State private var name      = ""
    @State private var notes     = ""
    @State private var priority  = TaskPriority.medium
    @State private var hasDeadline = false
    @State private var deadline  = Date().addingTimeInterval(86400 * 7)
    @State private var scheduleNotification = false
    @State private var error     = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.btPrimary).frame(width: 60, height: 60)
                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 24)).foregroundColor(.white)
                        }
                        Text("New Task").font(.btTitle2()).foregroundColor(.primary)
                        Text("Phase: \(phase.name)").font(.btCaption()).foregroundColor(.btTextSecondary)
                    }.padding(.top, 16)

                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Task Name", text: $name, icon: "square.and.pencil")
                        BTTextField(placeholder: "Notes (optional)", text: $notes, icon: "text.alignleft")

                        // Priority picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Priority").font(.btCaption()).foregroundColor(.btTextSecondary)
                            Picker("Priority", selection: $priority) {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Text(p.rawValue).tag(p)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Toggle("Set Deadline", isOn: $hasDeadline)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.systemBackground)).cornerRadius(12).tint(.btPrimary)

                        if hasDeadline {
                            DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Color(.systemBackground)).cornerRadius(12)

                            if appState.notificationsEnabled {
                                Toggle("Schedule Reminder", isOn: $scheduleNotification)
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(Color(.systemBackground)).cornerRadius(12).tint(.btPrimary)
                            }
                        }
                    }

                    if !error.isEmpty {
                        Text(error).font(.btSubhead()).foregroundColor(.btDanger)
                    }

                    BTButton(title: "Add Task", icon: "plus.circle.fill") { save() }
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
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
            error = "Task name is required."; return
        }
        let task = MainAppTask(id: UUID(),
                        name: name.trimmingCharacters(in: .whitespaces),
                        phaseId: phase.id,
                        deadline: hasDeadline ? deadline : nil,
                        isCompleted: false,
                        priority: priority,
                        notes: notes.trimmingCharacters(in: .whitespaces),
                        createdAt: Date())
        dataStore.addTask(task, phaseId: phase.id, projectId: project.id)
        if hasDeadline && scheduleNotification {
            appState.scheduleDeadlineNotification(taskName: task.name, date: deadline)
        }
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Edit Task
struct EditTaskView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss
    let task: MainAppTask
    let phase: Phase
    let project: Project

    @State private var name: String
    @State private var notes: String
    @State private var priority: TaskPriority
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var isCompleted: Bool
    @State private var error = ""

    init(task: MainAppTask, phase: Phase, project: Project) {
        self.task = task; self.phase = phase; self.project = project
        _name        = State(initialValue: task.name)
        _notes       = State(initialValue: task.notes)
        _priority    = State(initialValue: task.priority)
        _hasDeadline = State(initialValue: task.deadline != nil)
        _deadline    = State(initialValue: task.deadline ?? Date().addingTimeInterval(86400 * 7))
        _isCompleted = State(initialValue: task.isCompleted)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    BTTextField(placeholder: "Task Name", text: $name, icon: "square.and.pencil")
                    BTTextField(placeholder: "Notes", text: $notes, icon: "text.alignleft")
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)

                    Toggle("Has Deadline", isOn: $hasDeadline)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color(.systemBackground)).cornerRadius(12).tint(.btPrimary)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.systemBackground)).cornerRadius(12)
                    }
                    Toggle("Mark Completed", isOn: $isCompleted)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color(.systemBackground)).cornerRadius(12).tint(.btSuccess)

                    if !error.isEmpty { Text(error).foregroundColor(.btDanger) }
                    BTButton(title: "Save Changes", icon: "checkmark.circle.fill") { save() }
                }
                .padding(20)
            }
            .navigationTitle("Edit Task")
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
        var updated = task
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.notes = notes.trimmingCharacters(in: .whitespaces)
        updated.priority = priority
        updated.deadline = hasDeadline ? deadline : nil
        updated.isCompleted = isCompleted
        dataStore.updateTask(updated, phaseId: phase.id, projectId: project.id)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Tasks Overview (all tasks across all projects)
struct TasksOverviewView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var filter: TaskFilter = .all
    @State private var searchText = ""

    enum TaskFilter: String, CaseIterable {
        case all = "All", pending = "Pending", completed = "Done", overdue = "Overdue"
    }

    var filteredTasks: [(task: MainAppTask, phase: Phase, project: Project)] {
        var tasks = dataStore.allTasks
        switch filter {
        case .pending:  tasks = tasks.filter { !$0.task.isCompleted }
        case .completed:tasks = tasks.filter { $0.task.isCompleted }
        case .overdue:  tasks = tasks.filter { $0.task.isOverdue }
        case .all:      break
        }
        if !searchText.isEmpty {
            tasks = tasks.filter { $0.task.name.localizedCaseInsensitiveContains(searchText) }
        }
        return tasks.sorted { ($0.task.deadline ?? .distantFuture) < ($1.task.deadline ?? .distantFuture) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search
            BTTextField(placeholder: "Search tasks…", text: $searchText, icon: "magnifyingglass")
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

            // Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TaskFilter.allCases, id: \.self) { f in
                        Button(action: { filter = f }) {
                            Text(f.rawValue).font(.btSubhead())
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(filter == f ? Color.btPrimary : Color(.systemGray6))
                                .foregroundColor(filter == f ? .white : .primary)
                                .cornerRadius(20)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if filteredTasks.isEmpty {
                        BTEmptyState(icon: "checkmark.square",
                                     title: "No Tasks",
                                     subtitle: "No tasks match the current filter.")
                    } else {
                        ForEach(filteredTasks, id: \.task.id) { item in
                            OverviewTaskRow(item: item)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("All Tasks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OverviewTaskRow: View {
    @EnvironmentObject var dataStore: DataStore
    let item: (task: MainAppTask, phase: Phase, project: Project)

    var body: some View {
        BTCard(padding: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    var updated = item.task; updated.isCompleted.toggle()
                    dataStore.updateTask(updated, phaseId: item.phase.id, projectId: item.project.id)
                }) {
                    ZStack {
                        Circle().stroke(item.task.isCompleted ? Color.btSuccess : Color(.systemGray4), lineWidth: 2).frame(width: 26, height: 26)
                        if item.task.isCompleted {
                            Circle().fill(Color.btSuccess).frame(width: 18, height: 18)
                            Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        }
                    }
                }.buttonStyle(ScaleButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.task.name)
                        .font(.btSubhead())
                        .foregroundColor(item.task.isCompleted ? .btTextSecondary : .primary)
                        .strikethrough(item.task.isCompleted).lineLimit(1)
                    HStack(spacing: 6) {
                        Text(item.project.name).font(.btCaption()).foregroundColor(.btPrimary)
                        Text("·").font(.btCaption()).foregroundColor(.btTextSecondary)
                        Text(item.phase.name).font(.btCaption()).foregroundColor(.btTextSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    BTBadge(label: item.task.priority.rawValue, color: item.task.priority.color)
                    if let d = item.task.deadline {
                        Text(d.btShort)
                            .font(.btCaption())
                            .foregroundColor(item.task.isOverdue ? .btDanger : .btTextSecondary)
                    }
                }
            }
        }
    }
}
