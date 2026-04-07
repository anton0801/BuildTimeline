import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Greeting header
                headerCard

                if let project = dataStore.activeProject {
                    // Active project card
                    activeProjectCard(project)

                    // Current phase
                    if let phase = project.currentPhase {
                        currentPhaseCard(phase, project: project)
                    }

                    // Upcoming tasks
                    upcomingTasksSection(project)

                    // Recent photos
                    recentPhotosSection(project)

                    // Budget summary
                    budgetSummaryCard(project)

                } else {
                    // No projects yet
                    BTCard {
                        BTEmptyState(icon: "folder.badge.plus",
                                     title: "No Projects Yet",
                                     subtitle: "Create your first construction project to get started.")
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: NotificationsView()) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.btPrimary)
                        if dataStore.unreadNotificationCount > 0 {
                            Circle().fill(Color.btDanger)
                                .frame(width: 8, height: 8)
                                .offset(x: 3, y: -3)
                        }
                    }
                }
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.4).delay(0.1)) { appeared = true } }
    }

    // MARK: – Header card
    var headerCard: some View {
        BTCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDay)! 👷")
                        .font(.btCaption()).foregroundColor(.btTextSecondary)
                    Text(appState.userName.isEmpty ? "Builder" : appState.userName)
                        .font(.btTitle2()).foregroundColor(.primary)
                    Text(Date().btFormatted)
                        .font(.btCaption()).foregroundColor(.btTextSecondary)
                }
                Spacer()
                ZStack {
                    Circle().fill(LinearGradient.btPrimary).frame(width: 52, height: 52)
                    Image(systemName: "building.crane.fill")
                        .font(.system(size: 22)).foregroundColor(.white)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: – Active Project
    @ViewBuilder
    func activeProjectCard(_ project: Project) -> some View {
        BTCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Active Project").font(.btCaption()).foregroundColor(.btTextSecondary)
                        Text(project.name).font(.btTitle3()).foregroundColor(.primary)
                        Text(project.type).font(.btCaption()).foregroundColor(.btPrimary)
                    }
                    Spacer()
                    Text(project.progress.btPercent())
                        .font(.btTitle2()).fontWeight(.bold).foregroundColor(.btPrimary)
                }

                BTProgressBar(progress: project.progress, height: 10)

                HStack(spacing: 20) {
                    statItem(icon: "rectangle.stack.fill",
                             label: "\(project.phases.count) Phases",
                             color: .btInfo)
                    statItem(icon: "checkmark.square.fill",
                             label: "\(completedTasks(project))/\(totalTasks(project)) Tasks",
                             color: .btSuccess)
                    statItem(icon: "calendar",
                             label: daysRemaining(project),
                             color: .btWarning)
                }

                NavigationLink(destination: ProjectDetailView(project: project)) {
                    Text("View Project →")
                        .font(.btSubhead()).foregroundColor(.btPrimary)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    // MARK: – Current Phase
    @ViewBuilder
    func currentPhaseCard(_ phase: Phase, project: Project) -> some View {
        BTCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle().fill(Color.phaseColor(for: phase.name).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: phaseIcon(for: phase.name))
                            .font(.system(size: 18))
                            .foregroundColor(Color.phaseColor(for: phase.name))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Phase").font(.btCaption()).foregroundColor(.btTextSecondary)
                        Text(phase.name).font(.btHeadline()).foregroundColor(.primary)
                    }
                    Spacer()
                    BTBadge(label: "\(phase.completedTasksCount)/\(phase.tasks.count)",
                            color: .btPrimary)
                }
                BTProgressBar(progress: phase.progress, color: Color.phaseColor(for: phase.name))
                Text(phase.description).font(.btCaption()).foregroundColor(.btTextSecondary)
                    .lineLimit(2)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
    }

    // MARK: – Upcoming Tasks
    @ViewBuilder
    func upcomingTasksSection(_ project: Project) -> some View {
        let tasks = upcomingTasks(project)
        VStack(spacing: 12) {
            BTSectionHeader(title: "Upcoming Tasks") {
                // See All navigates to TasksOverviewView
            }
            if tasks.isEmpty {
                BTCard { Text("No upcoming tasks").font(.btSubhead()).foregroundColor(.btTextSecondary).padding(8) }
            } else {
                ForEach(tasks.prefix(3), id: \.id) { task in
                    BTCard(padding: 12) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(task.priority.color.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: task.isOverdue ? "exclamationmark" : "clock.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(task.isOverdue ? .btDanger : task.priority.color)
                                )
                            VStack(alignment: .leading, spacing: 3) {
                                Text(task.name).font(.btSubhead()).foregroundColor(.primary).lineLimit(1)
                                if let d = task.deadline {
                                    Text(d.btFormatted)
                                        .font(.btCaption())
                                        .foregroundColor(task.isOverdue ? .btDanger : .btTextSecondary)
                                }
                            }
                            Spacer()
                            BTBadge(label: task.priority.rawValue, color: task.priority.color)
                        }
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    // MARK: – Recent Photos
    @ViewBuilder
    func recentPhotosSection(_ project: Project) -> some View {
        let photos = project.phases.flatMap { $0.photos }.sorted { $0.date > $1.date }
        if !photos.isEmpty {
            VStack(spacing: 12) {
                BTSectionHeader(title: "Recent Photos")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photos.prefix(5)) { photo in
                            PhotoThumbnailView(photo: photo)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
        }
    }

    // MARK: – Budget Summary
    @ViewBuilder
    func budgetSummaryCard(_ project: Project) -> some View {
        BTCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Budget Summary").font(.btHeadline()).foregroundColor(.primary)
                HStack(spacing: 0) {
                    budgetItem(label: "Budget", value: project.budget.btCurrency(appState.currencySymbol),
                               color: .btInfo)
                    Divider().frame(height: 40).padding(.horizontal, 12)
                    budgetItem(label: "Spent", value: project.totalExpenses.btCurrency(appState.currencySymbol),
                               color: .btWarning)
                    Divider().frame(height: 40).padding(.horizontal, 12)
                    budgetItem(label: "Remaining",
                               value: project.remainingBudget.btCurrency(appState.currencySymbol),
                               color: project.remainingBudget >= 0 ? .btSuccess : .btDanger)
                }
                let ratio = project.budget > 0 ? project.totalExpenses / project.budget : 0
                BTProgressBar(progress: ratio, color: ratio > 0.9 ? .btDanger : .btWarning)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
    }

    // MARK: – Helpers
    var timeOfDay: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Morning" }
        if h < 17 { return "Afternoon" }
        return "Evening"
    }

    func totalTasks(_ p: Project) -> Int { p.phases.flatMap { $0.tasks }.count }
    func completedTasks(_ p: Project) -> Int { p.phases.flatMap { $0.tasks }.filter { $0.isCompleted }.count }

    func daysRemaining(_ p: Project) -> String {
        guard let end = p.endDate else { return "No end date" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return days >= 0 ? "\(days)d left" : "Overdue"
    }

    func upcomingTasks(_ p: Project) -> [Task] {
        p.phases.flatMap { $0.tasks }
            .filter { !$0.isCompleted }
            .sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
    }

    func statItem(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(color)
            Text(label).font(.btCaption()).foregroundColor(.btTextSecondary)
        }
    }

    func budgetItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.btCaption()).foregroundColor(.btTextSecondary)
            Text(value).font(.btSubhead()).fontWeight(.semibold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PhotoThumbnailView: View {
    let photo: PhotoItem
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)
            if let data = photo.imageData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable().scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "photo.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.btTextSecondary.opacity(0.5))
            }
        }
    }
}
