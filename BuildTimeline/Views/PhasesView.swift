import SwiftUI

// MARK: - Add Phase
struct AddPhaseView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss
    let project: Project

    @State private var name        = ""
    @State private var description = ""
    @State private var startDate   = Date()
    @State private var endDate     = Date().addingTimeInterval(86400 * 21)
    @State private var hasStart    = true
    @State private var hasEnd      = true
    @State private var selectedPreset = ""
    @State private var error       = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(LinearGradient.btPrimary).frame(width: 64, height: 64)
                            Image(systemName: "rectangle.stack.badge.plus")
                                .font(.system(size: 26)).foregroundColor(.white)
                        }
                        Text("New Phase").font(.btTitle2()).foregroundColor(.primary)
                    }.padding(.top, 16)

                    // Quick preset chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Presets").font(.btCaption()).foregroundColor(.btTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(defaultPhaseNames, id: \.self) { preset in
                                    Button(action: {
                                        selectedPreset = preset
                                        name = preset
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: phaseIcon(for: preset))
                                                .font(.system(size: 11))
                                            Text(preset).font(.btCaption2()).fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, 10).padding(.vertical, 7)
                                        .background(name == preset ? Color.btPrimary : Color(.systemGray6))
                                        .foregroundColor(name == preset ? .white : .primary)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                    }

                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Phase Name", text: $name,
                                    icon: "hammer.fill")
                        BTTextField(placeholder: "Description (optional)", text: $description,
                                    icon: "text.alignleft")

                        Toggle("Has Start Date", isOn: $hasStart)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.systemBackground)).cornerRadius(12).tint(.btPrimary)

                        if hasStart {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Color(.systemBackground)).cornerRadius(12)
                        }

                        Toggle("Has End Date", isOn: $hasEnd)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.systemBackground)).cornerRadius(12).tint(.btPrimary)

                        if hasEnd {
                            DatePicker("End Date", selection: $endDate,
                                       in: hasStart ? startDate... : Date()...,
                                       displayedComponents: .date)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Color(.systemBackground)).cornerRadius(12)
                        }
                    }

                    if !error.isEmpty {
                        Text(error).font(.btSubhead()).foregroundColor(.btDanger)
                    }

                    BTButton(title: "Add Phase", icon: "plus.circle.fill") { save() }
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
            error = "Phase name is required."; return
        }
        let phase = Phase(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            startDate: hasStart ? startDate : nil,
            endDate: hasEnd ? endDate : nil,
            tasks: [], materials: [], photos: [],
            isCompleted: false,
            order: project.phases.count
        )
        dataStore.addPhase(phase, to: project.id)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Phase Detail
struct PhaseDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    let phase: Phase
    let project: Project

    @State private var selectedTab     = 0
    @State private var showAddTask     = false
    @State private var showAddMaterial = false
    @State private var showAddPhoto    = false
    @State private var showDeleteAlert = false

    var currentProject: Project {
        dataStore.projects.first(where: { $0.id == project.id }) ?? project
    }
    var currentPhase: Phase {
        currentProject.phases.first(where: { $0.id == phase.id }) ?? phase
    }

    var body: some View {
        let ph = currentPhase
        VStack(spacing: 0) {
            // Phase header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle().fill(Color.phaseColor(for: ph.name).opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: phaseIcon(for: ph.name))
                            .font(.system(size: 20))
                            .foregroundColor(Color.phaseColor(for: ph.name))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(ph.name).font(.btTitle3()).foregroundColor(.primary)
                        if !ph.description.isEmpty {
                            Text(ph.description).font(.btCaption()).foregroundColor(.btTextSecondary)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { ph.isCompleted },
                        set: { val in
                            var updated = ph
                            updated.isCompleted = val
                            dataStore.updatePhase(updated, in: project.id)
                        }
                    ))
                    .labelsHidden().tint(.btSuccess)
                }
                BTProgressBar(progress: ph.progress, color: Color.phaseColor(for: ph.name))
                HStack {
                    if let s = ph.startDate { Label(s.btShort, systemImage: "calendar").font(.btCaption()).foregroundColor(.btTextSecondary) }
                    Spacer()
                    if let e = ph.endDate { Label(e.btShort, systemImage: "flag.fill").font(.btCaption()).foregroundColor(.btTextSecondary) }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("Tasks").tag(0)
                Text("Materials").tag(1)
                Text("Photos").tag(2)
                Text("Schedule").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(.systemGroupedBackground))

            // Tab content
            ScrollView(showsIndicators: false) {
                Group {
                    switch selectedTab {
                    case 0: TasksTabView(phase: ph, project: currentProject)
                    case 1: MaterialsTabView(phase: ph, project: currentProject)
                    case 2: PhotosTabView(phase: ph, project: currentProject)
                    default: PhaseScheduleTab(phase: ph)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .navigationTitle(ph.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showAddTask = true }) { Label("Add Task", systemImage: "plus.square.fill") }
                    Button(action: { showAddMaterial = true }) { Label("Add Material", systemImage: "shippingbox.fill") }
                    Button(action: { showAddPhoto = true }) { Label("Add Photo", systemImage: "camera.fill") }
                    Divider()
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete Phase", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundColor(.btPrimary)
                }
            }
        }
        .sheet(isPresented: $showAddTask)     { AddTaskView(phase: ph, project: currentProject) }
        .sheet(isPresented: $showAddMaterial) { AddMaterialView(phase: ph, project: currentProject) }
        .sheet(isPresented: $showAddPhoto)    { AddPhotoView(phase: ph, project: currentProject) }
        .alert("Delete Phase", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                dataStore.deletePhase(ph, from: project.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("All tasks, materials, and photos in this phase will be deleted.") }
    }
}

// MARK: – Tasks Tab inside Phase
struct TasksTabView: View {
    @EnvironmentObject var dataStore: DataStore
    let phase: Phase
    let project: Project
    @State private var showAdd = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tasks").font(.btTitle3()).foregroundColor(.primary)
                Spacer()
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.btPrimary).font(.system(size: 20))
                }
            }
            if phase.tasks.isEmpty {
                BTEmptyState(icon: "checkmark.square", title: "No Tasks",
                             subtitle: "Add tasks to track work for this phase.",
                             actionTitle: "Add Task") { showAdd = true }
            } else {
                ForEach(phase.tasks) { task in
                    TaskRow(task: task, phase: phase, project: project)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddTaskView(phase: phase, project: project) }
    }
}

// MARK: – Materials Tab inside Phase
struct MaterialsTabView: View {
    @EnvironmentObject var dataStore: DataStore
    let phase: Phase
    let project: Project
    @State private var showAdd = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Materials").font(.btTitle3()).foregroundColor(.primary)
                Spacer()
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.btPrimary).font(.system(size: 20))
                }
            }
            if phase.materials.isEmpty {
                BTEmptyState(icon: "shippingbox", title: "No Materials",
                             subtitle: "Track the materials needed for this phase.",
                             actionTitle: "Add Material") { showAdd = true }
            } else {
                ForEach(phase.materials) { material in
                    MaterialRow(material: material, phase: phase, project: project)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddMaterialView(phase: phase, project: project) }
    }
}

// MARK: – Photos Tab inside Phase
struct PhotosTabView: View {
    @EnvironmentObject var dataStore: DataStore
    let phase: Phase
    let project: Project
    @State private var showAdd = false

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Photos (\(phase.photos.count))").font(.btTitle3()).foregroundColor(.primary)
                Spacer()
                Button(action: { showAdd = true }) {
                    Image(systemName: "camera.fill").foregroundColor(.btPrimary).font(.system(size: 18))
                }
            }
            if phase.photos.isEmpty {
                BTEmptyState(icon: "photo.on.rectangle", title: "No Photos",
                             subtitle: "Document your build progress with photos.",
                             actionTitle: "Add Photo") { showAdd = true }
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(phase.photos) { photo in
                        PhotoGridItem(photo: photo, phase: phase, project: project)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddPhotoView(phase: phase, project: project) }
    }
}

struct PhotoGridItem: View {
    @EnvironmentObject var dataStore: DataStore
    let photo: PhotoItem
    let phase: Phase
    let project: Project
    @State private var showDelete = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let data = photo.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Color(.systemGray5)
                    Image(systemName: "photo.fill")
                        .font(.system(size: 28)).foregroundColor(.btTextSecondary.opacity(0.4))
                }
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if !photo.caption.isEmpty {
                Text(photo.caption)
                    .font(.btCaption2()).foregroundColor(.white)
                    .padding(5)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)
                    .padding(4)
            }
        }
        .contextMenu {
            Button(role: .destructive) { showDelete = true } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Photo", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                dataStore.deletePhoto(photo, phaseId: phase.id, projectId: project.id)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: – Phase Schedule Tab
struct PhaseScheduleTab: View {
    let phase: Phase
    var body: some View {
        BTCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Schedule").font(.btTitle3()).foregroundColor(.primary)
                Divider()

                if let s = phase.startDate {
                    scheduleRow(icon: "calendar", label: "Start Date", value: s.btFormatted, color: .btInfo)
                }
                if let e = phase.endDate {
                    scheduleRow(icon: "flag.fill", label: "End Date", value: e.btFormatted, color: .btWarning)
                }
                if let s = phase.startDate, let e = phase.endDate {
                    let days = Calendar.current.dateComponents([.day], from: s, to: e).day ?? 0
                    scheduleRow(icon: "clock.fill", label: "Duration", value: "\(days) days", color: .btPrimary)
                }
                scheduleRow(icon: "checkmark.square.fill",
                            label: "Tasks Progress",
                            value: "\(phase.completedTasksCount) / \(phase.tasks.count) done",
                            color: .btSuccess)
            }
        }
    }

    func scheduleRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 16)).frame(width: 24)
            Text(label).font(.btSubhead()).foregroundColor(.btTextSecondary)
            Spacer()
            Text(value).font(.btSubhead()).foregroundColor(.primary).fontWeight(.medium)
        }
    }
}
