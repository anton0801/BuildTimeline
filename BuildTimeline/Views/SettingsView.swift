import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showDeleteAlert = false
    @State private var showLogoutAlert = false
    @State private var showProfile     = false
    @State private var showSuppliers   = false
    @State private var showEquipment   = false
    @State private var showActivity    = false
    @State private var showTasks       = false
    @State private var showReports     = false
    @State private var notifGranted    = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Profile card
                profileHeaderCard

                // Quick navigation
                BTCard {
                    VStack(spacing: 0) {
                        navRow(icon: "checkmark.square.fill", label: "All Tasks",
                               color: .btSuccess) { showTasks = true }
                        Divider().padding(.leading, 52)
                        navRow(icon: "chart.bar.fill", label: "Reports",
                               color: .btPrimary) { showReports = true }
                        Divider().padding(.leading, 52)
                        navRow(icon: "person.2.fill", label: "Suppliers",
                               color: .btInfo) { showSuppliers = true }
                        Divider().padding(.leading, 52)
                        navRow(icon: "wrench.and.screwdriver.fill", label: "Equipment",
                               color: .btSecondary) { showEquipment = true }
                        Divider().padding(.leading, 52)
                        navRow(icon: "clock.arrow.circlepath", label: "Activity History",
                               color: .btWarning) { showActivity = true }
                    }
                }

                // Appearance
                BTCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Appearance").font(.btHeadline()).foregroundColor(.primary)

                        // Theme
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Theme").font(.btCaption()).foregroundColor(.btTextSecondary)
                            Picker("Theme", selection: $appState.themeMode) {
                                Label("System", systemImage: "circle.lefthalf.filled").tag("system")
                                Label("Light", systemImage: "sun.max.fill").tag("light")
                                Label("Dark", systemImage: "moon.fill").tag("dark")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }

                // Regional
                BTCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Regional").font(.btHeadline()).foregroundColor(.primary)

                        settingsPicker(label: "Units", selection: $appState.units,
                                       options: ["Metric", "Imperial"])
                        Divider()
                        settingsPicker(label: "Currency", selection: $appState.currency,
                                       options: ["USD", "EUR", "GBP", "RUB"])
                        Divider()
                        settingsToggle(label: "Week starts Monday",
                                       isOn: $appState.weekStartsMonday)
                    }
                }

                // Notifications
                BTCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Notifications").font(.btHeadline()).foregroundColor(.primary)

                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Push Notifications").font(.btSubhead()).foregroundColor(.primary)
                                Text("Get reminders for task deadlines")
                                    .font(.btCaption()).foregroundColor(.btTextSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $appState.notificationsEnabled)
                                .labelsHidden()
                                .tint(.btPrimary)
                                .onChange(of: appState.notificationsEnabled) { enabled in
                                    if enabled {
                                        appState.requestNotificationPermission { granted in
                                            if !granted { appState.notificationsEnabled = false }
                                        }
                                    } else {
                                        appState.cancelAllNotifications()
                                    }
                                }
                        }
                    }
                }

                // About
                BTCard {
                    VStack(spacing: 0) {
                        infoRow(label: "Version", value: "1.0.0")
                        Divider().padding(.leading, 16)
                        infoRow(label: "Build", value: "2025.1")
                        Divider().padding(.leading, 16)
                        infoRow(label: "Min iOS", value: "14.0")
                    }
                }

                // Account actions
                VStack(spacing: 12) {
                    BTButton(title: "Log Out", icon: "rectangle.portrait.and.arrow.right",
                             style: .outline) { showLogoutAlert = true }
                    BTButton(title: "Delete Account", icon: "trash.fill",
                             style: .danger) { showDeleteAlert = true }
                }
                .padding(.bottom, 8)

                Text("Build Timeline · All data stored locally on device.")
                    .font(.btCaption()).foregroundColor(.btTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showProfile = true }) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 22)).foregroundColor(.btPrimary)
                }
            }
        }
        .sheet(isPresented: $showProfile)   { ProfileView() }
        .sheet(isPresented: $showSuppliers) { NavigationView { SuppliersView() } }
        .sheet(isPresented: $showEquipment) { NavigationView { EquipmentView() } }
        .sheet(isPresented: $showActivity)  { NavigationView { ActivityHistoryView() } }
        .sheet(isPresented: $showTasks)     { NavigationView { TasksOverviewView() } }
        .sheet(isPresented: $showReports)   { NavigationView { ReportsView() } }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) { appState.logout() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You will be returned to the login screen.") }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                dataStore.projects = []
                dataStore.suppliers = []
                dataStore.equipment = []
                dataStore.activityHistory = []
                dataStore.notifications = []
                dataStore.saveAll()
                appState.deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("All your projects, data, and settings will be permanently deleted.") }
        .onAppear { appState.checkNotificationStatus() }
    }

    // MARK: – Profile Header
    var profileHeaderCard: some View {
        BTCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(LinearGradient.btPrimary).frame(width: 56, height: 56)
                    Text(String(appState.userName.prefix(1).uppercased()))
                        .font(.btTitle3()).fontWeight(.bold).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.userName.isEmpty ? "Builder" : appState.userName)
                        .font(.btHeadline()).foregroundColor(.primary)
                    Text(appState.userEmail).font(.btCaption()).foregroundColor(.btTextSecondary)
                    Label("\(dataStore.projects.count) projects · \(dataStore.allTasks.count) tasks",
                          systemImage: "building.2.fill")
                        .font(.btCaption()).foregroundColor(.btTextSecondary)
                }
                Spacer()
                Button(action: { showProfile = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22)).foregroundColor(.btPrimary)
                }
            }
        }
    }

    // MARK: – Helper components
    func navRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(color).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(.white)
                }
                Text(label).font(.btSubhead()).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.btTextSecondary)
            }
            .padding(.vertical, 10).padding(.horizontal, 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    func settingsPicker(label: String, selection: Binding<String>, options: [String]) -> some View {
        HStack {
            Text(label).font(.btSubhead()).foregroundColor(.primary)
            Spacer()
            Picker(label, selection: selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .foregroundColor(.btPrimary)
        }
    }

    func settingsToggle(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(label, isOn: isOn)
            .font(.btSubhead()).tint(.btPrimary)
    }

    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.btSubhead()).foregroundColor(.primary)
            Spacer()
            Text(value).font(.btSubhead()).foregroundColor(.btTextSecondary)
        }
        .padding(.horizontal, 4).padding(.vertical, 8)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @State private var name  = ""
    @State private var email = ""
    @State private var saved = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(LinearGradient.btPrimary).frame(width: 100, height: 100)
                                .shadow(color: Color.btPrimary.opacity(0.35), radius: 16, x: 0, y: 8)
                            Text(String(name.prefix(1).uppercased()))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Text("Your Profile").font(.btTitle2()).foregroundColor(.primary)
                    }.padding(.top, 24)

                    VStack(spacing: 14) {
                        BTTextField(placeholder: "Full Name", text: $name, icon: "person.fill")
                        BTTextField(placeholder: "Email", text: $email, icon: "envelope.fill",
                                    keyboardType: .emailAddress)
                    }
                    .padding(.horizontal, 20)

                    if saved {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.btSuccess)
                            Text("Profile saved!").font(.btSubhead()).foregroundColor(.btSuccess)
                        }
                        .padding(12).background(Color.btSuccess.opacity(0.1)).cornerRadius(10)
                        .padding(.horizontal, 20)
                        .transition(.scale.combined(with: .opacity))
                    }

                    BTButton(title: "Save Profile", icon: "checkmark.circle.fill") { save() }
                        .padding(.horizontal, 20).padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }.foregroundColor(.btPrimary)
                }
            }
        }
        .onAppear {
            name  = appState.userName
            email = appState.userEmail
        }
    }

    private func save() {
        appState.userName  = name.trimmingCharacters(in: .whitespaces)
        appState.userEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }
}
