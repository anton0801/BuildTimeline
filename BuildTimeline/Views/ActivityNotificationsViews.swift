import SwiftUI

// MARK: - Activity History
struct ActivityHistoryView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        Group {
            if dataStore.activityHistory.isEmpty {
                BTEmptyState(icon: "clock.arrow.circlepath",
                             title: "No Activity Yet",
                             subtitle: "Your build activity will appear here as you work.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(groupedActivity.keys.sorted(by: >), id: \.self) { dateKey in
                            VStack(alignment: .leading, spacing: 0) {
                                // Date header
                                Text(sectionTitle(dateKey))
                                    .font(.btCaption()).fontWeight(.semibold)
                                    .foregroundColor(.btTextSecondary)
                                    .padding(.horizontal, 20).padding(.vertical, 10)

                                // Activity rows
                                ForEach(groupedActivity[dateKey] ?? []) { record in
                                    ActivityRecordRow(record: record)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 8)
                                }
                            }
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
    }

    var groupedActivity: [String: [ActivityRecord]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Dictionary(grouping: dataStore.activityHistory) { record in
            formatter.string(from: record.date)
        }
    }

    func sectionTitle(_ dateKey: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateKey) else { return dateKey }
        if Calendar.current.isDateInToday(date)     { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let display = DateFormatter()
        display.dateFormat = "MMMM d, yyyy"
        return display.string(from: date)
    }
}

struct ActivityRecordRow: View {
    let record: ActivityRecord

    var iconColor: Color {
        switch record.type {
        case .projectAdded:   return .btPrimary
        case .phaseCompleted: return .btSuccess
        case .taskCompleted:  return .btSuccess
        case .materialAdded:  return .btInfo
        case .expenseAdded:   return .btWarning
        case .photoAdded:     return .btAccent
        case .general:        return .btTextSecondary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline connector
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: activityIcon(for: record.type))
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                Rectangle().fill(Color(.systemGray5)).frame(width: 2).frame(maxHeight: .infinity)
                    .padding(.top, 2)
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.btSubhead()).foregroundColor(.primary)
                Text(record.description)
                    .font(.btCaption()).foregroundColor(.btTextSecondary)
                    .lineLimit(2)
                Text(record.date.btTimeAgo)
                    .font(.btCaption()).foregroundColor(.btTextSecondary.opacity(0.7))
            }
            .padding(.top, 8).padding(.bottom, 16)
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showClearAlert = false

    var body: some View {
        Group {
            if dataStore.notifications.isEmpty {
                BTEmptyState(icon: "bell.slash.fill",
                             title: "No Notifications",
                             subtitle: "Deadline reminders and updates will appear here.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            } else {
                List {
                    ForEach(dataStore.notifications) { notification in
                        NotificationRow(notification: notification)
                            .listRowBackground(
                                notification.isRead ? Color.clear : Color.btPrimary.opacity(0.05)
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                dataStore.markNotificationRead(notification)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    dataStore.deleteNotification(notification)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
//        .toolbar {
//            if !dataStore.notifications.isEmpty {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Mark All Read") {
//                        dataStore.markAllNotificationsRead()
//                    }
//                    .font(.btSubhead())
//                    .foregroundColor(.btPrimary)
//                }
//            }
//        }
    }
}


final class AttributionBridge: NSObject {
    var onTracking: (([AnyHashable: Any]) -> Void)?
    var onNavigation: (([AnyHashable: Any]) -> Void)?
    private var trackingBuf: [AnyHashable: Any] = [:]
    private var navigationBuf: [AnyHashable: Any] = [:]
    private var timer: Timer?
    
    func receiveTracking(_ data: [AnyHashable: Any]) {
        trackingBuf = data
        scheduleTimer()
        if !navigationBuf.isEmpty { merge() }
    }
    
    func receiveNavigation(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: "bt_first_launch_flag") else { return }
        navigationBuf = data
        onNavigation?(data)
        timer?.invalidate()
        if !trackingBuf.isEmpty { merge() }
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.merge() }
    }
    
    private func merge() {
        var result = trackingBuf
        navigationBuf.forEach { k, v in
            let key = "deep_\(k)"
            if result[key] == nil { result[key] = v }
        }
        onTracking?(result)
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var iconColor: Color {
        switch notification.type {
        case .deadline: return .btDanger
        case .reminder: return .btWarning
        case .budget:   return .btSuccess
        case .general:  return .btInfo
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: notificationIcon(for: notification.type))
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.btSubhead())
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    if !notification.isRead {
                        Circle().fill(Color.btPrimary).frame(width: 8, height: 8)
                    }
                }
                Text(notification.message)
                    .font(.btCaption()).foregroundColor(.btTextSecondary).lineLimit(2)
                Text(notification.date.btTimeAgo)
                    .font(.btCaption()).foregroundColor(.btTextSecondary.opacity(0.7))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }
}
