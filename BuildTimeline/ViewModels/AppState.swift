import SwiftUI
import UserNotifications
import Combine

// MARK: - AppState (auth + settings)
class AppState: ObservableObject {
    @AppStorage("isLoggedIn")             var isLoggedIn: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("themeMode")             var themeMode: String = "system"   // "system","light","dark"
    @AppStorage("userName")              var userName: String = ""
    @AppStorage("userEmail")             var userEmail: String = ""
    @AppStorage("units")                 var units: String = "Metric"        // "Metric","Imperial"
    @AppStorage("currency")             var currency: String = "USD"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("weekStartsMonday")      var weekStartsMonday: Bool = true
    @AppStorage("defaultPhase")         var defaultPhase: String = "Foundation"

    var currencySymbol: String {
        switch currency {
        case "EUR": return "€"
        case "GBP": return "£"
        case "RUB": return "₽"
        default:    return "$"
        }
    }

    var colorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    // MARK: - Auth
    func login(email: String, password: String) -> Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        userEmail = email
        if userName.isEmpty { userName = email.components(separatedBy: "@").first?.capitalized ?? "Builder" }
        isLoggedIn = true
        return true
    }

    func signUp(name: String, email: String, password: String) -> Bool {
        guard !name.isEmpty, email.contains("@"), password.count >= 6 else { return false }
        userName = name
        userEmail = email
        isLoggedIn = true
        return true
    }

    func logout() {
        isLoggedIn = false
        hasCompletedOnboarding = false
    }

    func deleteAccount() {
        isLoggedIn = false
        hasCompletedOnboarding = false
        userName = ""
        userEmail = ""
        themeMode = "system"
        notificationsEnabled = false
    }

    // MARK: - Notifications
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                completion(granted)
            }
        }
    }

    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleDeadlineNotification(taskName: String, date: Date) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Deadline Approaching"
        content.body = "Task '\(taskName)' is due soon."
        content.sound = .default

        var comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date)
        comps.hour = 9; comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
