import SwiftUI

struct NotificationCenterView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Picker("Notification Type", selection: $selectedTab) {
                Text("Upcoming").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedTab == 0 {
                UpcomingNotificationsView(notifications: notificationManager.pendingNotifications)
            } else {
                DeliveredNotificationsView(notifications: notificationManager.deliveredNotifications)
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            notificationManager.refreshNotificationLists()
        }
    }
}

struct UpcomingNotificationsView: View {
    let notifications: [NotificationManager.NotificationItem]
    
    var body: some View {
        if notifications.isEmpty {
            EmptyStateView(
                title: "No Upcoming Notifications",
                systemImage: "bell.slash",
                description: "Add notifications to your activities to see them here"
            )
        } else {
            List(notifications) { notification in
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.activityName)
                        .font(.headline)
                    Text(notification.scheduledDate.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DeliveredNotificationsView: View {
    let notifications: [NotificationManager.NotificationItem]
    
    var body: some View {
        if notifications.isEmpty {
            EmptyStateView(
                title: "No Notification History",
                systemImage: "clock.arrow.circlepath",
                description: "Past notifications will appear here"
            )
        } else {
            List(notifications) { notification in
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.activityName)
                        .font(.headline)
                    Text(notification.scheduledDate.formatted())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
} 