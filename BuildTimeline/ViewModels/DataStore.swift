import SwiftUI
import Combine

// MARK: - DataStore
class DataStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var suppliers: [Supplier] = []
    @Published var equipment: [Equipment] = []
    @Published var activityHistory: [ActivityRecord] = []
    @Published var notifications: [AppNotification] = []

    private let pKey = "bt_projects"
    private let sKey = "bt_suppliers"
    private let eKey = "bt_equipment"
    private let aKey = "bt_activity"
    private let nKey = "bt_notifications"

    init() {
        loadAll()
        if projects.isEmpty { loadSampleData() }
    }

    // MARK: – Persistence
    func loadAll() {
        projects      = load(pKey) ?? []
        suppliers     = load(sKey) ?? []
        equipment     = load(eKey) ?? []
        activityHistory = load(aKey) ?? []
        notifications = load(nKey) ?? []
    }

    private func load<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let val = try? JSONDecoder().decode(T.self, from: data) else { return nil }
        return val
    }

    private func save<T: Encodable>(_ val: T, _ key: String) {
        if let data = try? JSONEncoder().encode(val) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func saveAll() {
        save(projects, pKey); save(suppliers, sKey); save(equipment, eKey)
        save(activityHistory, aKey); save(notifications, nKey)
    }

    // MARK: – Projects
    func addProject(_ p: Project) {
        projects.append(p)
        log("Project Added", "Started project: \(p.name)", .projectAdded)
        saveAll()
    }

    func updateProject(_ p: Project) {
        guard let i = projects.firstIndex(where: { $0.id == p.id }) else { return }
        projects[i] = p; saveAll()
    }

    func deleteProject(_ p: Project) {
        projects.removeAll { $0.id == p.id }; saveAll()
    }

    // MARK: – Phases
    func addPhase(_ ph: Phase, to projectId: UUID) {
        guard let i = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[i].phases.append(ph); saveAll()
    }

    func updatePhase(_ ph: Phase, in projectId: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectId }),
              let hi = projects[pi].phases.firstIndex(where: { $0.id == ph.id }) else { return }
        projects[pi].phases[hi] = ph
        if ph.isCompleted { log("Phase Completed", "Completed phase: \(ph.name)", .phaseCompleted) }
        recalcProgress(projectId); saveAll()
    }

    func deletePhase(_ ph: Phase, from projectId: UUID) {
        guard let i = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[i].phases.removeAll { $0.id == ph.id }; saveAll()
    }

    // MARK: – Tasks
    func addTask(_ t: Task, phaseId: UUID, projectId: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectId }),
              let hi = projects[pi].phases.firstIndex(where: { $0.id == phaseId }) else { return }
        projects[pi].phases[hi].tasks.append(t); saveAll()
    }

    func updateTask(_ t: Task, phaseId: UUID, projectId: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectId }),
              let hi = projects[pi].phases.firstIndex(where: { $0.id == phaseId }),
              let ti = projects[pi].phases[hi].tasks.firstIndex(where: { $0.id == t.id }) else { return }
        projects[pi].phases[hi].tasks[ti] = t
        if t.isCompleted { log("Task Completed", "Completed: \(t.name)", .taskCompleted) }
        recalcProgress(projectId); saveAll()
    }

    func deleteTask(_ t: Task, phaseId: UUID, projectId: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectId }),
              let hi = projects[pi].phases.firstIndex(where: { $0.id == phaseId }) else { return }
        projects[pi].phases[hi].tasks.removeAll { $0.id == t.id }
        recalcProgress(projectId); saveAll()
    }

    // MARK: – Materials
    func addMaterial(_ m: Material, phaseId: UUID, projectId: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectId }),
              let hi = projects[pi].phases.firstIndex(where: { $0.id == phaseId }) else { return }
        projects[pi].phases[hi].materials.append(m)
        log("Material Added", "Added \(m.name)", .materialAdded); saveAll()
    }

    func updateMaterial(_ m: Material, phaseId: UUID, projectId: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectId }),
              let hi = projects[pi].phases.firstIndex(where: { $0.id == phaseId }),
              let mi = projects[pi].phases[hi].materials.firstIndex(where: { $0.id == m.id }) else { return }
        projects[pi].phases[hi].materials[mi] = m; saveAll()
    }

    func deleteMaterial(_ m: Material, phaseId: UUID, projectId: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectId }),
              let hi = projects[pi].phases.firstIndex(where: { $0.id == phaseId }) else { return }
        projects[pi].phases[hi].materials.removeAll { $0.id == m.id }; saveAll()
    }

    // MARK: – Photos
    func addPhoto(_ ph: PhotoItem, phaseId: UUID, projectId: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectId }),
              let hi = projects[pi].phases.firstIndex(where: { $0.id == phaseId }) else { return }
        projects[pi].phases[hi].photos.append(ph)
        log("Photo Added", "Photo added to \(projects[pi].phases[hi].name)", .photoAdded); saveAll()
    }

    func deletePhoto(_ ph: PhotoItem, phaseId: UUID, projectId: UUID) {
        guard let pi = projects.firstIndex(where: { $0.id == projectId }),
              let hi = projects[pi].phases.firstIndex(where: { $0.id == phaseId }) else { return }
        projects[pi].phases[hi].photos.removeAll { $0.id == ph.id }; saveAll()
    }

    // MARK: – Expenses
    func addExpense(_ e: Expense, projectId: UUID) {
        guard let i = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[i].expenses.append(e)
        log("Expense Added", "\(e.title): \(e.amount.btCurrency())", .expenseAdded); saveAll()
    }

    func deleteExpense(_ e: Expense, projectId: UUID) {
        guard let i = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[i].expenses.removeAll { $0.id == e.id }; saveAll()
    }

    // MARK: – Suppliers
    func addSupplier(_ s: Supplier)    { suppliers.append(s); saveAll() }
    func updateSupplier(_ s: Supplier) {
        guard let i = suppliers.firstIndex(where: { $0.id == s.id }) else { return }
        suppliers[i] = s; saveAll()
    }
    func deleteSupplier(_ s: Supplier) { suppliers.removeAll { $0.id == s.id }; saveAll() }

    // MARK: – Equipment
    func addEquipment(_ e: Equipment)    { equipment.append(e); saveAll() }
    func updateEquipment(_ e: Equipment) {
        guard let i = equipment.firstIndex(where: { $0.id == e.id }) else { return }
        equipment[i] = e; saveAll()
    }
    func deleteEquipment(_ e: Equipment) { equipment.removeAll { $0.id == e.id }; saveAll() }

    // MARK: – Notifications
    func addNotification(_ n: AppNotification) {
        notifications.insert(n, at: 0)
        if notifications.count > 50 { notifications = Array(notifications.prefix(50)) }
        save(notifications, nKey)
    }
    func markNotificationRead(_ n: AppNotification) {
        guard let i = notifications.firstIndex(where: { $0.id == n.id }) else { return }
        notifications[i].isRead = true; save(notifications, nKey)
    }
    func deleteNotification(_ n: AppNotification) {
        notifications.removeAll { $0.id == n.id }; save(notifications, nKey)
    }
    func markAllNotificationsRead() {
        for i in notifications.indices { notifications[i].isRead = true }
        save(notifications, nKey)
    }

    // MARK: – Helpers
    func recalcProgress(_ projectId: UUID) {
        guard let i = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let all = projects[i].phases.flatMap { $0.tasks }
        if all.isEmpty { projects[i].progress = 0; return }
        projects[i].progress = Double(all.filter { $0.isCompleted }.count) / Double(all.count)
    }

    func log(_ title: String, _ desc: String, _ type: ActivityType) {
        let r = ActivityRecord(title: title, description: desc, date: Date(), type: type)
        activityHistory.insert(r, at: 0)
        if activityHistory.count > 200 { activityHistory = Array(activityHistory.prefix(200)) }
        save(activityHistory, aKey)
    }

    var activeProject: Project? { projects.first(where: { !$0.isCompleted }) ?? projects.first }

    var unreadNotificationCount: Int { notifications.filter { !$0.isRead }.count }

    var allTasks: [(task: Task, phase: Phase, project: Project)] {
        projects.flatMap { proj in
            proj.phases.flatMap { ph in
                ph.tasks.map { (task: $0, phase: ph, project: proj) }
            }
        }
    }

    var allPhotos: [(photo: PhotoItem, phase: Phase, project: Project)] {
        projects.flatMap { proj in
            proj.phases.flatMap { ph in
                ph.photos.map { (photo: $0, phase: ph, project: proj) }
            }
        }
    }

    // MARK: – Sample Data
    private func loadSampleData() {
        let suppId = UUID()
        suppliers = [
            Supplier(id: suppId, name: "BuildMart Supply", contact: "Mike Johnson",
                     email: "mike@buildmart.com", phone: "+1 555-0100",
                     address: "123 Main St, Chicago", notes: "Primary supplier")
        ]
        equipment = [
            Equipment(id: UUID(), name: "Tower Crane", type: "Heavy Equipment", status: .available, notes: "Site crane, operational"),
            Equipment(id: UUID(), name: "Concrete Mixer", type: "Mixing Equipment", status: .inUse, notes: "Daily rental"),
            Equipment(id: UUID(), name: "Bulldozer", type: "Earthmoving", status: .maintenance, notes: "Due for service")
        ]

        let projId = UUID()
        let foundId = UUID()
        let wallsId = UUID()
        let roofId  = UUID()

        let tasks1: [Task] = [
            Task(id: UUID(), name: "Land survey", phaseId: foundId,
                 deadline: Date().addingTimeInterval(-86400*4), isCompleted: true,
                 priority: .high, notes: "Complete before digging", createdAt: Date().addingTimeInterval(-86400*14)),
            Task(id: UUID(), name: "Excavation", phaseId: foundId,
                 deadline: Date().addingTimeInterval(-86400*2), isCompleted: true,
                 priority: .high, notes: "", createdAt: Date().addingTimeInterval(-86400*12)),
            Task(id: UUID(), name: "Pour concrete foundation", phaseId: foundId,
                 deadline: Date().addingTimeInterval(86400*3), isCompleted: false,
                 priority: .high, notes: "Use C30 grade concrete", createdAt: Date().addingTimeInterval(-86400*7)),
        ]
        let tasks2: [Task] = [
            Task(id: UUID(), name: "Build exterior walls", phaseId: wallsId,
                 deadline: Date().addingTimeInterval(86400*20), isCompleted: false,
                 priority: .high, notes: "", createdAt: Date()),
            Task(id: UUID(), name: "Install window frames", phaseId: wallsId,
                 deadline: Date().addingTimeInterval(86400*28), isCompleted: false,
                 priority: .medium, notes: "", createdAt: Date()),
        ]

        let mats1: [Material] = [
            Material(id: UUID(), name: "Concrete C30", quantity: 50, unit: "m³",
                     phaseId: foundId, cost: 5000, supplierId: suppId, isOrdered: true),
            Material(id: UUID(), name: "Rebar 12mm", quantity: 200, unit: "kg",
                     phaseId: foundId, cost: 1200, supplierId: suppId, isOrdered: true),
        ]
        let mats2: [Material] = [
            Material(id: UUID(), name: "Bricks", quantity: 5000, unit: "pcs",
                     phaseId: wallsId, cost: 3000, supplierId: suppId, isOrdered: false),
            Material(id: UUID(), name: "Mortar", quantity: 30, unit: "bags",
                     phaseId: wallsId, cost: 450, supplierId: suppId, isOrdered: false),
        ]

        let expenses: [Expense] = [
            Expense(id: UUID(), title: "Concrete purchase", amount: 5000,
                    date: Date().addingTimeInterval(-86400*5), category: "Materials",
                    projectId: projId, notes: "First batch delivered"),
            Expense(id: UUID(), title: "Crane rental", amount: 1500,
                    date: Date().addingTimeInterval(-86400*3), category: "Equipment",
                    projectId: projId, notes: "Monthly rental"),
            Expense(id: UUID(), title: "Building permit", amount: 850,
                    date: Date().addingTimeInterval(-86400*10), category: "Permits",
                    projectId: projId, notes: "City building permit"),
        ]

        let phases: [Phase] = [
            Phase(id: foundId, name: "Foundation", description: "Laying the building foundation",
                  startDate: Date().addingTimeInterval(-86400*14),
                  endDate: Date().addingTimeInterval(86400*7),
                  tasks: tasks1, materials: mats1, photos: [], isCompleted: false, order: 0),
            Phase(id: wallsId, name: "Walls", description: "Structural walls construction",
                  startDate: Date().addingTimeInterval(86400*8),
                  endDate: Date().addingTimeInterval(86400*35),
                  tasks: tasks2, materials: mats2, photos: [], isCompleted: false, order: 1),
            Phase(id: roofId, name: "Roof", description: "Roof structure and waterproofing",
                  startDate: Date().addingTimeInterval(86400*36),
                  endDate: Date().addingTimeInterval(86400*55),
                  tasks: [], materials: [], photos: [], isCompleted: false, order: 2),
            Phase(id: UUID(), name: "Electrical", description: "Electrical installation",
                  startDate: Date().addingTimeInterval(86400*56),
                  endDate: Date().addingTimeInterval(86400*75),
                  tasks: [], materials: [], photos: [], isCompleted: false, order: 3),
            Phase(id: UUID(), name: "Finishing", description: "Interior and exterior finishing",
                  startDate: Date().addingTimeInterval(86400*76),
                  endDate: Date().addingTimeInterval(86400*120),
                  tasks: [], materials: [], photos: [], isCompleted: false, order: 4),
        ]

        let proj = Project(id: projId, name: "Home Construction", type: "Residential",
                           startDate: Date().addingTimeInterval(-86400*14),
                           endDate: Date().addingTimeInterval(86400*120),
                           budget: 150000, phases: phases, expenses: expenses,
                           progress: 0.22, isCompleted: false,
                           createdAt: Date().addingTimeInterval(-86400*14))
        projects.append(proj)

        activityHistory = [
            ActivityRecord(title: "Task Completed", description: "Completed: Excavation",
                           date: Date().addingTimeInterval(-86400*2), type: .taskCompleted),
            ActivityRecord(title: "Task Completed", description: "Completed: Land survey",
                           date: Date().addingTimeInterval(-86400*4), type: .taskCompleted),
            ActivityRecord(title: "Material Added", description: "Added Concrete C30",
                           date: Date().addingTimeInterval(-86400*7), type: .materialAdded),
            ActivityRecord(title: "Project Added", description: "Started: Home Construction",
                           date: Date().addingTimeInterval(-86400*14), type: .projectAdded),
        ]

        notifications = [
            AppNotification(id: UUID(),
                            title: "Deadline in 3 days",
                            message: "Task 'Pour concrete foundation' is due soon.",
                            date: Date().addingTimeInterval(-3600),
                            isRead: false, type: .deadline),
            AppNotification(id: UUID(),
                            title: "Materials needed",
                            message: "Bricks for Walls phase not yet ordered.",
                            date: Date().addingTimeInterval(-86400),
                            isRead: false, type: .reminder),
        ]

        saveAll()
    }
}
