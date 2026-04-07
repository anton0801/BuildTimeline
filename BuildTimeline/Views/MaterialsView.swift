import SwiftUI

// MARK: - Material Row (used inside phase)
struct MaterialRow: View {
    @EnvironmentObject var dataStore: DataStore
    let material: Material
    let phase: Phase
    let project: Project
    @State private var showEdit   = false
    @State private var showDelete = false

    var body: some View {
        BTCard(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(material.isOrdered ? Color.btSuccess.opacity(0.15) : Color.btWarning.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: material.isOrdered ? "shippingbox.fill" : "shippingbox")
                        .font(.system(size: 16))
                        .foregroundColor(material.isOrdered ? .btSuccess : .btWarning)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(material.name)
                        .font(.btSubhead()).foregroundColor(.primary).lineLimit(1)
                    HStack(spacing: 8) {
                        Text("\(formatQty(material.quantity)) \(material.unit)")
                            .font(.btCaption()).foregroundColor(.btTextSecondary)
                        if material.cost > 0 {
                            Text("· \(material.cost.btCurrency())")
                                .font(.btCaption()).foregroundColor(.btTextSecondary)
                        }
                    }
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    BTBadge(label: material.isOrdered ? "Ordered" : "Pending",
                            color: material.isOrdered ? .btSuccess : .btWarning)
                    Menu {
                        Button(action: { showEdit = true }) { Label("Edit", systemImage: "pencil") }
                        Button(action: {
                            var updated = material; updated.isOrdered.toggle()
                            dataStore.updateMaterial(updated, phaseId: phase.id, projectId: project.id)
                        }) {
                            Label(material.isOrdered ? "Mark Pending" : "Mark Ordered",
                                  systemImage: material.isOrdered ? "arrow.uturn.backward" : "checkmark.circle")
                        }
                        Button(role: .destructive, action: { showDelete = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis").foregroundColor(.btTextSecondary).padding(4)
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditMaterialView(material: material, phase: phase, project: project) }
        .alert("Delete Material", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                dataStore.deleteMaterial(material, phaseId: phase.id, projectId: project.id)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    func formatQty(_ qty: Double) -> String {
        qty == qty.rounded() ? String(Int(qty)) : String(format: "%.1f", qty)
    }
}

// MARK: - Add Material
struct AddMaterialView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss
    let phase: Phase
    let project: Project

    @State private var name       = ""
    @State private var quantity   = ""
    @State private var unit       = "pcs"
    @State private var cost       = ""
    @State private var isOrdered  = false
    @State private var selectedSupplier: UUID? = nil
    @State private var error      = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.btPrimary).frame(width: 60, height: 60)
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 24)).foregroundColor(.white)
                        }
                        Text("Add Material").font(.btTitle2()).foregroundColor(.primary)
                        Text("Phase: \(phase.name)").font(.btCaption()).foregroundColor(.btTextSecondary)
                    }.padding(.top, 16)

                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Material Name", text: $name, icon: "cube.fill")
                        BTTextField(placeholder: "Quantity (e.g. 50)", text: $quantity,
                                    icon: "number.circle.fill", keyboardType: .decimalPad)

                        // Unit picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Unit").font(.btCaption()).foregroundColor(.btTextSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(materialUnits, id: \.self) { u in
                                        Button(action: { unit = u }) {
                                            Text(u).font(.btCaption2()).fontWeight(.semibold)
                                                .padding(.horizontal, 10).padding(.vertical, 7)
                                                .background(unit == u ? Color.btPrimary : Color(.systemGray6))
                                                .foregroundColor(unit == u ? .white : .primary)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                            }
                        }

                        BTTextField(placeholder: "Cost (optional)", text: $cost,
                                    icon: "dollarsign.circle.fill", keyboardType: .decimalPad)

                        // Supplier picker
                        if !dataStore.suppliers.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Supplier (optional)").font(.btCaption()).foregroundColor(.btTextSecondary)
                                Picker("Supplier", selection: $selectedSupplier) {
                                    Text("None").tag(nil as UUID?)
                                    ForEach(dataStore.suppliers) { s in
                                        Text(s.name).tag(s.id as UUID?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(Color(.systemBackground)).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
                            }
                        }

                        Toggle("Already Ordered", isOn: $isOrdered)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.systemBackground)).cornerRadius(12).tint(.btSuccess)
                    }

                    if !error.isEmpty {
                        Text(error).font(.btSubhead()).foregroundColor(.btDanger)
                    }

                    BTButton(title: "Add Material", icon: "plus.circle.fill") { save() }
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
            error = "Material name is required."; return
        }
        let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) ?? 1
        let costVal = Double(cost.replacingOccurrences(of: ",", with: ".")) ?? 0

        let material = Material(
            id: UUID(), name: name.trimmingCharacters(in: .whitespaces),
            quantity: qty, unit: unit,
            phaseId: phase.id, cost: costVal,
            supplierId: selectedSupplier, isOrdered: isOrdered
        )
        dataStore.addMaterial(material, phaseId: phase.id, projectId: project.id)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Edit Material
struct EditMaterialView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss
    let material: Material
    let phase: Phase
    let project: Project

    @State private var name: String
    @State private var quantity: String
    @State private var unit: String
    @State private var cost: String
    @State private var isOrdered: Bool
    @State private var selectedSupplier: UUID?
    @State private var error = ""

    init(material: Material, phase: Phase, project: Project) {
        self.material = material; self.phase = phase; self.project = project
        _name            = State(initialValue: material.name)
        _quantity        = State(initialValue: String(material.quantity))
        _unit            = State(initialValue: material.unit)
        _cost            = State(initialValue: material.cost > 0 ? String(material.cost) : "")
        _isOrdered       = State(initialValue: material.isOrdered)
        _selectedSupplier = State(initialValue: material.supplierId)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    BTTextField(placeholder: "Material Name", text: $name, icon: "cube.fill")
                    BTTextField(placeholder: "Quantity", text: $quantity,
                                icon: "number.circle.fill", keyboardType: .decimalPad)

                    // Unit chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(materialUnits, id: \.self) { u in
                                Button(action: { unit = u }) {
                                    Text(u).font(.btCaption2()).fontWeight(.semibold)
                                        .padding(.horizontal, 10).padding(.vertical, 7)
                                        .background(unit == u ? Color.btPrimary : Color(.systemGray6))
                                        .foregroundColor(unit == u ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    BTTextField(placeholder: "Cost", text: $cost,
                                icon: "dollarsign.circle.fill", keyboardType: .decimalPad)

                    if !dataStore.suppliers.isEmpty {
                        Picker("Supplier", selection: $selectedSupplier) {
                            Text("None").tag(nil as UUID?)
                            ForEach(dataStore.suppliers) { s in Text(s.name).tag(s.id as UUID?) }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Color(.systemBackground)).cornerRadius(12)
                    }

                    Toggle("Ordered", isOn: $isOrdered)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color(.systemBackground)).cornerRadius(12).tint(.btSuccess)

                    if !error.isEmpty { Text(error).foregroundColor(.btDanger) }
                    BTButton(title: "Save Changes", icon: "checkmark.circle.fill") { save() }
                }
                .padding(20)
            }
            .navigationTitle("Edit Material")
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
        var updated = material
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.quantity = Double(quantity) ?? material.quantity
        updated.unit = unit
        updated.cost = Double(cost) ?? material.cost
        updated.isOrdered = isOrdered
        updated.supplierId = selectedSupplier
        dataStore.updateMaterial(updated, phaseId: phase.id, projectId: project.id)
        dismiss.wrappedValue.dismiss()
    }
}
