import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            NavigationView { DashboardView() }
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            // Projects
            NavigationView { ProjectsView() }
                .tabItem {
                    Label("Projects", systemImage: selectedTab == 1 ? "folder.fill" : "folder")
                }
                .tag(1)

            // Timeline
            NavigationView { TimelineView() }
                .tabItem {
                    Label("Timeline", systemImage: selectedTab == 2 ? "chart.bar.xaxis" : "chart.bar")
                }
                .tag(2)

            // Photos
            NavigationView { PhotosView() }
                .tabItem {
                    Label("Photos", systemImage: selectedTab == 3 ? "photo.fill.on.rectangle.fill" : "photo.on.rectangle")
                }
                .tag(3)

            // Settings / More
            NavigationView { SettingsView() }
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 4 ? "gearshape.2.fill" : "gearshape.2")
                }
                .tag(4)
        }
        .accentColor(.btPrimary)
    }
}
