import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var selectedProjectId: UUID? = nil

    var project: Project? {
        if let id = selectedProjectId { return dataStore.projects.first { $0.id == id } }
        return dataStore.activeProject
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Project selector
                if !dataStore.projects.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(dataStore.projects) { proj in
                                Button(action: { selectedProjectId = proj.id }) {
                                    Text(proj.name).font(.btSubhead())
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(project?.id == proj.id ? Color.btPrimary : Color(.systemGray6))
                                        .foregroundColor(project?.id == proj.id ? .white : .primary)
                                        .cornerRadius(16)
                                }.buttonStyle(ScaleButtonStyle())
                            }
                        }.padding(.horizontal, 16)
                    }
                }

                if let proj = project {
                    // Overall KPIs
                    kpiSection(proj)

                    // Phase progress breakdown
                    phaseProgressSection(proj)

                    // Task statistics
                    taskStatsSection(proj)

                    // Budget analysis
                    budgetAnalysisSection(proj)

                    // Materials overview
                    materialsSection(proj)
                } else {
                    BTCard {
                        BTEmptyState(icon: "chart.bar.fill",
                                     title: "No Data",
                                     subtitle: "Create a project to see analytics.")
                    }.padding(.horizontal, 16)
                }
                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: – KPI Cards
    @ViewBuilder
    func kpiSection(_ proj: Project) -> some View {
        VStack(spacing: 10) {
            BTSectionHeader(title: "Project Overview").padding(.horizontal, 16)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                kpiCard(title: "Overall Progress", value: proj.progress.btPercent(),
                        icon: "chart.bar.fill", color: .btPrimary)
                kpiCard(title: "Phases", value: "\(proj.phases.filter { $0.isCompleted }.count)/\(proj.phases.count)",
                        icon: "rectangle.stack.fill", color: .btInfo)
                kpiCard(title: "Tasks Done", value: "\(completedTasks(proj))/\(totalTasks(proj))",
                        icon: "checkmark.square.fill", color: .btSuccess)
                kpiCard(title: "Budget Used", value: proj.budget > 0 ?
                        "\(Int(proj.totalExpenses / proj.budget * 100))%" : "N/A",
                        icon: "dollarsign.circle.fill",
                        color: proj.totalExpenses > proj.budget ? .btDanger : .btWarning)
            }
            .padding(.horizontal, 16)
        }
    }

    func kpiCard(title: String, value: String, icon: String, color: Color) -> some View {
        BTCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 22))
                Text(value).font(.btTitle3()).fontWeight(.bold).foregroundColor(.primary)
                Text(title).font(.btCaption()).foregroundColor(.btTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: – Phase Progress
    @ViewBuilder
    func phaseProgressSection(_ proj: Project) -> some View {
        VStack(spacing: 10) {
            BTSectionHeader(title: "Phase Progress").padding(.horizontal, 16)
            BTCard {
                VStack(spacing: 14) {
                    ForEach(proj.phases.sorted { $0.order < $1.order }) { phase in
                        VStack(spacing: 6) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: phaseIcon(for: phase.name))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.phaseColor(for: phase.name))
                                    Text(phase.name).font(.btSubhead()).foregroundColor(.primary)
                                }
                                Spacer()
                                if phase.isCompleted {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.btSuccess)
                                        .font(.system(size: 14))
                                }
                                Text(phase.progress.btPercent())
                                    .font(.btSubhead()).fontWeight(.semibold)
                                    .foregroundColor(Color.phaseColor(for: phase.name))
                            }
                            BTProgressBar(progress: phase.progress, height: 8,
                                          color: Color.phaseColor(for: phase.name))
                            HStack {
                                Text("\(phase.completedTasksCount)/\(phase.tasks.count) tasks")
                                    .font(.btCaption()).foregroundColor(.btTextSecondary)
                                Spacer()
                                Text("\(phase.materials.filter { $0.isOrdered }.count)/\(phase.materials.count) materials ordered")
                                    .font(.btCaption()).foregroundColor(.btTextSecondary)
                            }
                        }
                    }
                }
            }.padding(.horizontal, 16)
        }
    }

    // MARK: – Task Stats
    @ViewBuilder
    func taskStatsSection(_ proj: Project) -> some View {
        let allTasks = proj.phases.flatMap { $0.tasks }
        let completed = allTasks.filter { $0.isCompleted }.count
        let overdue = allTasks.filter { $0.isOverdue }.count
        let highPri = allTasks.filter { $0.priority == .high && !$0.isCompleted }.count

        VStack(spacing: 10) {
            BTSectionHeader(title: "Task Analytics").padding(.horizontal, 16)
            BTCard {
                VStack(spacing: 14) {
                    taskStatRow(label: "Total Tasks", value: "\(allTasks.count)",
                                color: .btInfo, pct: 1.0)
                    taskStatRow(label: "Completed",
                                value: "\(completed)",
                                color: .btSuccess,
                                pct: allTasks.isEmpty ? 0 : Double(completed)/Double(allTasks.count))
                    taskStatRow(label: "Overdue",
                                value: "\(overdue)",
                                color: .btDanger,
                                pct: allTasks.isEmpty ? 0 : Double(overdue)/Double(allTasks.count))
                    taskStatRow(label: "High Priority",
                                value: "\(highPri)",
                                color: .btWarning,
                                pct: allTasks.isEmpty ? 0 : Double(highPri)/Double(allTasks.count))
                }
            }.padding(.horizontal, 16)
        }
    }

    func taskStatRow(label: String, value: String, color: Color, pct: Double) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label).font(.btSubhead()).foregroundColor(.primary)
                Spacer()
                Text(value).font(.btSubhead()).fontWeight(.bold).foregroundColor(color)
            }
            BTProgressBar(progress: pct, height: 6, color: color)
        }
    }

    // MARK: – Budget Analysis
    @ViewBuilder
    func budgetAnalysisSection(_ proj: Project) -> some View {
        VStack(spacing: 10) {
            BTSectionHeader(title: "Budget Analysis").padding(.horizontal, 16)
            BTCard {
                VStack(spacing: 14) {
                    // Bar chart by category
                    let grouped = Dictionary(grouping: proj.expenses, by: { $0.category })
                    let sorted = grouped.sorted { a, b in
                        a.value.reduce(0) { $0 + $1.amount } > b.value.reduce(0) { $0 + $1.amount }
                    }
                    let maxAmt = sorted.first?.value.reduce(0) { $0 + $1.amount } ?? 1

                    ForEach(sorted.prefix(6), id: \.key) { cat, items in
                        let total = items.reduce(0) { $0 + $1.amount }
                        HStack(spacing: 8) {
                            Text(cat).font(.btCaption()).foregroundColor(.primary)
                                .frame(width: 80, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5)).frame(height: 18)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(LinearGradient.btPrimary)
                                        .frame(
                                            width: geo.size.width * CGFloat(total / maxAmt),
                                            height: 18
                                        )
                                }
                            }.frame(height: 18)
                            Text(total.btCurrency(appState.currencySymbol))
                                .font(.btCaption()).fontWeight(.semibold)
                                .foregroundColor(.btPrimary)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }

                    if proj.expenses.isEmpty {
                        Text("No expenses recorded yet.")
                            .font(.btSubhead()).foregroundColor(.btTextSecondary)
                    }
                }
            }.padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    func materialsSection(_ proj: Project) -> some View {
        let allMats = proj.phases.flatMap { $0.materials }
        
        let ordered = allMats.filter { $0.isOrdered }.count
        let totalCost = allMats.reduce(0) { $0 + $1.cost }
        
        VStack(spacing: 10) {
            BTSectionHeader(title: "Materials Overview").padding(.horizontal, 16)
            BTCard {
                VStack(spacing: 12) {
                    HStack {
                        statItem2(label: "Total Items", value: "\(allMats.count)", color: .btInfo)
                        Divider().frame(height: 40)
                        statItem2(label: "Ordered", value: "\(ordered)", color: .btSuccess)
                        Divider().frame(height: 40)
                        statItem2(label: "Pending", value: "\(allMats.count - ordered)", color: .btWarning)
                    }
                    Divider()
                    HStack {
                        Text("Total Material Cost")
                            .font(.btSubhead()).foregroundColor(.btTextSecondary)
                        Spacer()
                        Text(totalCost.btCurrency(appState.currencySymbol))
                            .font(.btHeadline()).foregroundColor(.btPrimary)
                    }
                    let orderRatio = allMats.isEmpty ? 0.0 : Double(ordered) / Double(allMats.count)
                    BTProgressBar(progress: orderRatio, color: .btSuccess)
                    Text("\(Int(orderRatio * 100))% materials ordered")
                        .font(.btCaption()).foregroundColor(.btTextSecondary)
                }
            }.padding(.horizontal, 16)
        }
    }

    func statItem2(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.btTitle3()).fontWeight(.bold).foregroundColor(color)
            Text(label).font(.btCaption()).foregroundColor(.btTextSecondary)
        }.frame(maxWidth: .infinity)
    }

    func totalTasks(_ p: Project) -> Int { p.phases.flatMap { $0.tasks }.count }
    func completedTasks(_ p: Project) -> Int { p.phases.flatMap { $0.tasks }.filter { $0.isCompleted }.count }
}
