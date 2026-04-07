import SwiftUI

@main
struct BuildTimelineApp: App {
    @StateObject var appState = AppState()
    @StateObject var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(dataStore)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var splashDone = false

    var body: some View {
        Group {
            if !splashDone {
                SplashView(splashDone: $splashDone)
                    .transition(.opacity)
            } else if !appState.isLoggedIn {
                WelcomeView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else {
                MainTabView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: splashDone)
        .animation(.easeInOut(duration: 0.45), value: appState.isLoggedIn)
        .animation(.easeInOut(duration: 0.45), value: appState.hasCompletedOnboarding)
    }
}
