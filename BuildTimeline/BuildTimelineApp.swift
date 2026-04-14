import SwiftUI

@main
struct BuildTimelineApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

struct RootView: View {
    @StateObject var appState = AppState()
    @StateObject var dataStore = DataStore()

    var body: some View {
        Group {
             if !appState.isLoggedIn {
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
        .animation(.easeInOut(duration: 0.45), value: appState.isLoggedIn)
        .animation(.easeInOut(duration: 0.45), value: appState.hasCompletedOnboarding)
        .environmentObject(appState)
        .environmentObject(dataStore)
        .preferredColorScheme(appState.colorScheme)
    }
}
