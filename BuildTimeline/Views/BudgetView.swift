import SwiftUI

// MARK: - Budget View
struct BudgetView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @State var project: Project
    @State private var showAddExpense = false

    var currentProject: Project {
        dataStore.projects.first(where: { $0.id == project.id }) ?? project
    }

    var body: some View {
        let proj = currentProject
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Summary cards
                    HStack(spacing: 12) {
                        budgetCard(title: "Budget",
                                   value: proj.budget.btCurrency(appState.currencySymbol),
                                   icon: "dollarsign.circle.fill", color: .btInfo)
                        budgetCard(title: "Spent",
                                   value: proj.totalExpenses.btCurrency(appState.currencySymbol),
                                   icon: "arrow.up.circle.fill", color: .btWarning)
                    }
                    HStack(spacing: 12) {
                        budgetCard(title: "Remaining",
                                   value: proj.remainingBudget.btCurrency(appState.currencySymbol),
                                   icon: "checkmark.circle.fill",
                                   color: proj.remainingBudget >= 0 ? .btSuccess : .btDanger)
                        let ratio = proj.budget > 0 ? proj.totalExpenses / proj.budget : 0
                        budgetCard(title: "Used",
                                   value: ratio.btPercent(),
                                   icon: "chart.pie.fill",
                                   color: ratio > 0.9 ? .btDanger : .btPrimary)
                    }

                    // Spend progress
                    BTCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Budget Usage").font(.btHeadline()).foregroundColor(.primary)
                            let ratio = proj.budget > 0 ? proj.totalExpenses / proj.budget : 0
                            BTProgressBar(progress: ratio, height: 12,
                                          color: ratio > 0.9 ? .btDanger : ratio > 0.7 ? .btWarning : .btSuccess)
                            HStack {
                                Text(proj.totalExpenses.btCurrency(appState.currencySymbol))
                                    .font(.btCaption()).foregroundColor(.btTextSecondary)
                                Spacer()
                                Text(proj.budget.btCurrency(appState.currencySymbol))
                                    .font(.btCaption()).foregroundColor(.btTextSecondary)
                            }
                        }
                    }

                    // By category
                    if !proj.expenses.isEmpty {
                        categoryBreakdown(proj.expenses)
                    }

                    // Expense list
                    VStack(spacing: 10) {
                        BTSectionHeader(title: "Expenses") {
                            showAddExpense = true
                        }
                        .padding(.bottom, 2)

                        if proj.expenses.isEmpty {
                            BTCard {
                                BTEmptyState(icon: "dollarsign.circle",
                                             title: "No Expenses",
                                             subtitle: "Tap + to log your first expense.",
                                             actionTitle: "Add Expense") { showAddExpense = true }
                            }
                        } else {
                            ForEach(proj.expenses.sorted { $0.date > $1.date }) { expense in
                                ExpenseRow(expense: expense, project: proj,
                                           currencySymbol: appState.currencySymbol)
                            }
                        }
                    }
                    Spacer(minLength: 20)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }.foregroundColor(.btPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddExpense = true }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.btPrimary).font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) { AddExpenseView(project: proj) }
        }
    }

    func budgetCard(title: String, value: String, icon: String, color: Color) -> some View {
        BTCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 20))
                Text(value).font(.btHeadline()).foregroundColor(.primary)
                Text(title).font(.btCaption()).foregroundColor(.btTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    func categoryBreakdown(_ expenses: [Expense]) -> some View {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        let sorted = grouped.sorted { $0.value.reduce(0, { $0 + $1.amount }) > $1.value.reduce(0, { $0 + $1.amount }) }

        BTCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("By Category").font(.btHeadline()).foregroundColor(.primary)
                ForEach(sorted.prefix(5), id: \.key) { cat, items in
                    let total = items.reduce(0) { $0 + $1.amount }
                    let ratio = project.budget > 0 ? total / project.budget : 0
                    HStack {
                        Text(cat).font(.btSubhead()).foregroundColor(.primary)
                        Spacer()
                        Text(total.btCurrency(appState.currencySymbol))
                            .font(.btSubhead()).fontWeight(.semibold).foregroundColor(.btPrimary)
                    }
                    BTProgressBar(progress: min(ratio, 1), height: 5, color: .btPrimary)
                }
            }
        }
    }
}

// MARK: - Expense Row
struct ExpenseRow: View {
    @EnvironmentObject var dataStore: DataStore
    let expense: Expense
    let project: Project
    let currencySymbol: String
    @State private var showDelete = false

    var body: some View {
        BTCard(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.btPrimary.opacity(0.12)).frame(width: 40, height: 40)
                    Image(systemName: categoryIcon(expense.category))
                        .font(.system(size: 16)).foregroundColor(.btPrimary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(expense.title).font(.btSubhead()).foregroundColor(.primary).lineLimit(1)
                    HStack(spacing: 6) {
                        BTBadge(label: expense.category, color: .btPrimary)
                        Text(expense.date.btFormatted).font(.btCaption()).foregroundColor(.btTextSecondary)
                    }
                    if !expense.notes.isEmpty {
                        Text(expense.notes).font(.btCaption()).foregroundColor(.btTextSecondary).lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expense.amount.btCurrency(currencySymbol))
                        .font(.btSubhead()).fontWeight(.bold).foregroundColor(.primary)
                    Button(action: { showDelete = true }) {
                        Image(systemName: "trash").font(.system(size: 12))
                            .foregroundColor(.btDanger.opacity(0.7))
                    }
                }
            }
        }
        .alert("Delete Expense", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                dataStore.deleteExpense(expense, projectId: project.id)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    func categoryIcon(_ cat: String) -> String {
        switch cat {
        case "Materials":  return "shippingbox.fill"
        case "Labor":      return "person.2.fill"
        case "Equipment":  return "wrench.and.screwdriver.fill"
        case "Permits":    return "doc.fill"
        case "Design":     return "pencil.and.ruler.fill"
        case "Utilities":  return "bolt.fill"
        default:           return "dollarsign.circle.fill"
        }
    }
}

// MARK: - Add Expense
struct AddExpenseView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    let project: Project

    @State private var title    = ""
    @State private var amount   = ""
    @State private var category = "Materials"
    @State private var date     = Date()
    @State private var notes    = ""
    @State private var error    = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.btPrimary).frame(width: 60, height: 60)
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 24)).foregroundColor(.white)
                        }
                        Text("New Expense").font(.btTitle2()).foregroundColor(.primary)
                    }.padding(.top, 16)

                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Expense Title", text: $title,
                                    icon: "tag.fill")
                        BTTextField(placeholder: "Amount", text: $amount,
                                    icon: "dollarsign.circle.fill", keyboardType: .decimalPad)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category").font(.btCaption()).foregroundColor(.btTextSecondary)
                            Picker("Category", selection: $category) {
                                ForEach(expenseCategories, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(Color(.systemBackground)).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
                        }

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.systemBackground)).cornerRadius(12)

                        BTTextField(placeholder: "Notes (optional)", text: $notes,
                                    icon: "text.alignleft")
                    }

                    if !error.isEmpty {
                        Text(error).font(.btSubhead()).foregroundColor(.btDanger)
                    }

                    BTButton(title: "Add Expense", icon: "plus.circle.fill") { save() }
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
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Title is required."; return
        }
        guard let amt = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            error = "Enter a valid amount."; return
        }
        let expense = Expense(id: UUID(),
                              title: title.trimmingCharacters(in: .whitespaces),
                              amount: amt, date: date,
                              category: category, projectId: project.id,
                              notes: notes.trimmingCharacters(in: .whitespaces))
        dataStore.addExpense(expense, projectId: project.id)
        dismiss.wrappedValue.dismiss()
    }
}
