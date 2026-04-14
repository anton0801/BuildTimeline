import SwiftUI

// MARK: - Suppliers View
struct SuppliersView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAdd    = false
    @State private var searchText = ""

    var filtered: [Supplier] {
        searchText.isEmpty ? dataStore.suppliers
        : dataStore.suppliers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.contact.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if dataStore.suppliers.isEmpty {
                BTEmptyState(icon: "person.2.fill",
                             title: "No Suppliers",
                             subtitle: "Add suppliers to track contacts and vendors.",
                             actionTitle: "Add Supplier") { showAdd = true }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        BTTextField(placeholder: "Search suppliers…", text: $searchText,
                                    icon: "magnifyingglass")
                        .padding(.horizontal, 16).padding(.top, 8)

                        ForEach(filtered) { supplier in
                            SupplierCard(supplier: supplier)
                                .padding(.horizontal, 16)
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 4)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        .navigationTitle("Suppliers")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.btPrimary).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddSupplierView() }
    }
}

struct BuildTimelineWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "bt_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}


struct SupplierCard: View {
    @EnvironmentObject var dataStore: DataStore
    let supplier: Supplier
    @State private var showEdit   = false
    @State private var showDelete = false
    @State private var expanded   = false

    var body: some View {
        BTCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(LinearGradient.btGold).frame(width: 44, height: 44)
                        Text(String(supplier.name.prefix(1)))
                            .font(.btHeadline()).fontWeight(.bold).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(supplier.name).font(.btHeadline()).foregroundColor(.primary)
                        if !supplier.contact.isEmpty {
                            Text(supplier.contact).font(.btCaption()).foregroundColor(.btTextSecondary)
                        }
                    }
                    Spacer()
                    Menu {
                        Button(action: { showEdit = true }) { Label("Edit", systemImage: "pencil") }
                        if !supplier.phone.isEmpty {
                            Button(action: { openPhone(supplier.phone) }) { Label("Call", systemImage: "phone.fill") }
                        }
                        if !supplier.email.isEmpty {
                            Button(action: { openEmail(supplier.email) }) { Label("Email", systemImage: "envelope.fill") }
                        }
                        Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis.circle").foregroundColor(.btTextSecondary)
                    }
                }

                if expanded {
                    Divider()
                    VStack(spacing: 8) {
                        if !supplier.phone.isEmpty {
                            infoRow(icon: "phone.fill", text: supplier.phone)
                        }
                        if !supplier.email.isEmpty {
                            infoRow(icon: "envelope.fill", text: supplier.email)
                        }
                        if !supplier.address.isEmpty {
                            infoRow(icon: "mappin.circle.fill", text: supplier.address)
                        }
                        if !supplier.notes.isEmpty {
                            infoRow(icon: "text.alignleft", text: supplier.notes)
                        }
                    }
                }

                Button(action: { withAnimation(.spring(response: 0.3)) { expanded.toggle() } }) {
                    HStack(spacing: 4) {
                        Text(expanded ? "Show Less" : "Show Details")
                            .font(.btCaption()).foregroundColor(.btPrimary)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10)).foregroundColor(.btPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditSupplierView(supplier: supplier) }
        .alert("Delete Supplier", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { dataStore.deleteSupplier(supplier) }
            Button("Cancel", role: .cancel) {}
        }
    }

    func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.btPrimary).font(.system(size: 13)).frame(width: 20)
            Text(text).font(.btCaption()).foregroundColor(.primary).lineLimit(1)
            Spacer()
        }
    }

    func openPhone(_ phone: String) {
        if let url = URL(string: "tel://\(phone.filter { "0123456789+".contains($0) })") {
            UIApplication.shared.open(url)
        }
    }
    func openEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") { UIApplication.shared.open(url) }
    }
}

// MARK: - Add Supplier
struct AddSupplierView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss
    @State private var name    = ""
    @State private var contact = ""
    @State private var email   = ""
    @State private var phone   = ""
    @State private var address = ""
    @State private var notes   = ""
    @State private var error   = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(LinearGradient.btGold).frame(width: 60, height: 60)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 24)).foregroundColor(.white)
                        }
                        Text("New Supplier").font(.btTitle2()).foregroundColor(.primary)
                    }.padding(.top, 16)

                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Company Name *", text: $name, icon: "building.2.fill")
                        BTTextField(placeholder: "Contact Person", text: $contact, icon: "person.fill")
                        BTTextField(placeholder: "Email", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                        BTTextField(placeholder: "Phone", text: $phone, icon: "phone.fill", keyboardType: .phonePad)
                        BTTextField(placeholder: "Address", text: $address, icon: "mappin.circle.fill")
                        BTTextField(placeholder: "Notes", text: $notes, icon: "text.alignleft")
                    }

                    if !error.isEmpty { Text(error).foregroundColor(.btDanger).font(.btSubhead()) }
                    BTButton(title: "Add Supplier", icon: "plus.circle.fill") { save() }
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
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { error = "Company name required."; return }
        let supplier = Supplier(id: UUID(), name: name.trimmingCharacters(in: .whitespaces),
                                contact: contact, email: email, phone: phone,
                                address: address, notes: notes)
        dataStore.addSupplier(supplier)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Edit Supplier
struct EditSupplierView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss
    let supplier: Supplier
    @State private var name: String; @State private var contact: String
    @State private var email: String; @State private var phone: String
    @State private var address: String; @State private var notes: String
    @State private var error = ""

    init(supplier: Supplier) {
        self.supplier = supplier
        _name = State(initialValue: supplier.name); _contact = State(initialValue: supplier.contact)
        _email = State(initialValue: supplier.email); _phone = State(initialValue: supplier.phone)
        _address = State(initialValue: supplier.address); _notes = State(initialValue: supplier.notes)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    BTTextField(placeholder: "Company Name", text: $name, icon: "building.2.fill")
                    BTTextField(placeholder: "Contact", text: $contact, icon: "person.fill")
                    BTTextField(placeholder: "Email", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                    BTTextField(placeholder: "Phone", text: $phone, icon: "phone.fill", keyboardType: .phonePad)
                    BTTextField(placeholder: "Address", text: $address, icon: "mappin.circle.fill")
                    BTTextField(placeholder: "Notes", text: $notes, icon: "text.alignleft")
                    if !error.isEmpty { Text(error).foregroundColor(.btDanger) }
                    BTButton(title: "Save Changes", icon: "checkmark.circle.fill") { save() }
                }
                .padding(20)
            }
            .navigationTitle("Edit Supplier")
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
        var updated = supplier
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.contact = contact; updated.email = email; updated.phone = phone
        updated.address = address; updated.notes = notes
        dataStore.updateSupplier(updated)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Equipment View
struct EquipmentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAdd = false
    @State private var filter: EquipmentStatus? = nil

    var filtered: [Equipment] {
        guard let f = filter else { return dataStore.equipment }
        return dataStore.equipment.filter { $0.status == f }
    }

    var body: some View {
        Group {
            if dataStore.equipment.isEmpty {
                BTEmptyState(icon: "wrench.and.screwdriver",
                             title: "No Equipment",
                             subtitle: "Track tools and machinery used on site.",
                             actionTitle: "Add Equipment") { showAdd = true }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Status filter
                        HStack(spacing: 8) {
                            Button(action: { filter = nil }) {
                                Text("All").font(.btSubhead())
                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                    .background(filter == nil ? Color.btPrimary : Color(.systemGray6))
                                    .foregroundColor(filter == nil ? .white : .primary)
                                    .cornerRadius(20)
                            }.buttonStyle(ScaleButtonStyle())

                            ForEach(EquipmentStatus.allCases, id: \.self) { status in
                                Button(action: { filter = status }) {
                                    Text(status.rawValue).font(.btSubhead())
                                        .padding(.horizontal, 14).padding(.vertical, 7)
                                        .background(filter == status ? status.color : Color(.systemGray6))
                                        .foregroundColor(filter == status ? .white : .primary)
                                        .cornerRadius(20)
                                }.buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 8)

                        ForEach(filtered) { equipment in
                            EquipmentCard(equipment: equipment)
                                .padding(.horizontal, 16)
                        }
                        Spacer(minLength: 20)
                    }
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.btPrimary).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddEquipmentView() }
    }
}

struct EquipmentCard: View {
    @EnvironmentObject var dataStore: DataStore
    let equipment: Equipment
    @State private var showDelete = false

    var body: some View {
        BTCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(equipment.status.color.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 18)).foregroundColor(equipment.status.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(equipment.name).font(.btSubhead()).foregroundColor(.primary)
                    Text(equipment.type).font(.btCaption()).foregroundColor(.btTextSecondary)
                    if !equipment.notes.isEmpty {
                        Text(equipment.notes).font(.btCaption()).foregroundColor(.btTextSecondary).lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    BTBadge(label: equipment.status.rawValue, color: equipment.status.color)
                    Menu {
                        ForEach(EquipmentStatus.allCases, id: \.self) { status in
                            Button(action: {
                                var updated = equipment; updated.status = status
                                dataStore.updateEquipment(updated)
                            }) {
                                Label(status.rawValue, systemImage:
                                    status == .available ? "checkmark.circle" :
                                    status == .inUse ? "hammer" : "wrench")
                            }
                        }
                        Divider()
                        Button(role: .destructive, action: { showDelete = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis").foregroundColor(.btTextSecondary).padding(4)
                    }
                }
            }
        }
        .alert("Delete Equipment", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { dataStore.deleteEquipment(equipment) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Add Equipment
struct AddEquipmentView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss
    @State private var name   = ""
    @State private var type   = ""
    @State private var status = EquipmentStatus.available
    @State private var notes  = ""
    @State private var error  = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.btSecondary).frame(width: 60, height: 60)
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 24)).foregroundColor(.white)
                        }
                        Text("New Equipment").font(.btTitle2()).foregroundColor(.primary)
                    }.padding(.top, 16)

                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Equipment Name *", text: $name, icon: "wrench.fill")
                        BTTextField(placeholder: "Type (e.g. Heavy Machinery)", text: $type, icon: "tag.fill")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Status").font(.btCaption()).foregroundColor(.btTextSecondary)
                            Picker("Status", selection: $status) {
                                ForEach(EquipmentStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                        BTTextField(placeholder: "Notes", text: $notes, icon: "text.alignleft")
                    }

                    if !error.isEmpty { Text(error).foregroundColor(.btDanger).font(.btSubhead()) }
                    BTButton(title: "Add Equipment", icon: "plus.circle.fill") { save() }
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
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { error = "Name required."; return }
        let eq = Equipment(id: UUID(), name: name.trimmingCharacters(in: .whitespaces),
                           type: type, status: status, notes: notes)
        dataStore.addEquipment(eq)
        dismiss.wrappedValue.dismiss()
    }
}
