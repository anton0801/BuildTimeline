import Foundation

// MARK: - Project
struct Project: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: String
    var startDate: Date
    var endDate: Date?
    var budget: Double
    var phases: [Phase]
    var expenses: [Expense]
    var progress: Double
    var isCompleted: Bool
    var createdAt: Date

    var totalExpenses: Double { expenses.reduce(0) { $0 + $1.amount } }
    var remainingBudget: Double { budget - totalExpenses }
    var currentPhase: Phase? { phases.first(where: { !$0.isCompleted }) }

    static func == (lhs: Project, rhs: Project) -> Bool { lhs.id == rhs.id }
}

// MARK: - Phase
struct Phase: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var startDate: Date?
    var endDate: Date?
    var tasks: [Task]
    var materials: [Material]
    var photos: [PhotoItem]
    var isCompleted: Bool
    var order: Int

    var completedTasksCount: Int { tasks.filter { $0.isCompleted }.count }
    var progress: Double {
        guard !tasks.isEmpty else { return isCompleted ? 1 : 0 }
        return Double(completedTasksCount) / Double(tasks.count)
    }

    static func == (lhs: Phase, rhs: Phase) -> Bool { lhs.id == rhs.id }
}

// MARK: - Task
struct Task: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var phaseId: UUID
    var deadline: Date?
    var isCompleted: Bool
    var priority: TaskPriority
    var notes: String
    var createdAt: Date

    var isOverdue: Bool {
        guard let d = deadline, !isCompleted else { return false }
        return d < Date()
    }

    static func == (lhs: Task, rhs: Task) -> Bool { lhs.id == rhs.id }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low", medium = "Medium", high = "High"
}

// MARK: - Material
struct Material: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var phaseId: UUID?
    var cost: Double
    var supplierId: UUID?
    var isOrdered: Bool

    static func == (lhs: Material, rhs: Material) -> Bool { lhs.id == rhs.id }
}

// MARK: - Photo
struct PhotoItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var phaseId: UUID?
    var caption: String
    var date: Date
    var imageData: Data?

    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Expense
struct Expense: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var date: Date
    var category: String
    var projectId: UUID
    var notes: String

    static func == (lhs: Expense, rhs: Expense) -> Bool { lhs.id == rhs.id }
}

// MARK: - Supplier
struct Supplier: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var contact: String
    var email: String
    var phone: String
    var address: String
    var notes: String

    static func == (lhs: Supplier, rhs: Supplier) -> Bool { lhs.id == rhs.id }
}

// MARK: - Equipment
struct Equipment: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: String
    var status: EquipmentStatus
    var notes: String

    static func == (lhs: Equipment, rhs: Equipment) -> Bool { lhs.id == rhs.id }
}

enum EquipmentStatus: String, Codable, CaseIterable {
    case available = "Available", inUse = "In Use", maintenance = "Maintenance"
}

// MARK: - Activity
struct ActivityRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var date: Date
    var type: ActivityType
}

enum ActivityType: String, Codable {
    case projectAdded = "Project Added"
    case phaseCompleted = "Phase Completed"
    case taskCompleted = "Task Completed"
    case materialAdded = "Material Added"
    case expenseAdded = "Expense Added"
    case photoAdded = "Photo Added"
    case general = "General"
}

// MARK: - Notification
struct AppNotification: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var message: String
    var date: Date
    var isRead: Bool
    var type: NotificationType
}

enum NotificationType: String, Codable {
    case deadline = "Deadline", reminder = "Reminder", budget = "Budget", general = "General"
}

// MARK: - Project Types
let projectTypes = ["Residential", "Commercial", "Industrial", "Renovation", "Infrastructure", "Other"]

let expenseCategories = ["Materials", "Labor", "Equipment", "Permits", "Design", "Utilities", "Other"]

let materialUnits = ["m³", "kg", "tonnes", "pcs", "m²", "m", "liters", "bags", "boxes", "sheets"]

let defaultPhaseNames = ["Foundation", "Walls", "Roof", "Windows", "Electrical", "Plumbing", "Finishing"]
