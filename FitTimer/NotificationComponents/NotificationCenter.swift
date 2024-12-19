import SwiftData
import SwiftUI

struct NotificationCenterView: View {
    @State private var selectedTab = 0
    @Query private var activities: [Activity]
    @Query private var workoutPlans: [WorkoutPlan]

    var body: some View {
        VStack {
            Picker("Notification Type", selection: $selectedTab) {
                Text("Upcoming").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                UpcomingNotificationsView()
            } else {
                // DeliveredNotificationsView(notifications: notificationManager.deliveredNotifications)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct UpcomingNotificationsView: View {
    @EnvironmentObject private var lnManager: LocalNotificationManager

    var body: some View {
        if lnManager.isGranted == false {
            Button("Enable Notifications") {
                lnManager.openSettings()
            }
        } else if lnManager.pendingRequests.isEmpty {
            EmptyStateView(
                title: "No Upcoming Notifications",
                systemImage: "bell.slash",
                description: "Add notifications to your activities to see them here"
            )
        } else {
            List {
                ForEach(lnManager.pendingRequests, id: \.identifier) { request in
                    NotificationBar(request: request)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        lnManager.clearRequests()
                    } label: {
                        Image(systemName: "clear.fill")
                            .imageScale(.large)
                    }
                }
            }
        }
    }
}

struct NotificationBar: View {
    let request: UNNotificationRequest
    @EnvironmentObject private var lnManager: LocalNotificationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(request.content.title)
                    .font(.headline)
                Spacer()
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextDate = trigger.nextTriggerDate()
                {
                    Text(nextDate, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            Text(request.content.body)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Label {
                Text(request.identifier)
                    .font(.caption2)
            } icon: {
                Image(systemName: "number")
                    .imageScale(.small)
            }
            .foregroundColor(.secondary)
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                Label {
                    Text(trigger.repeats ? "Repeating Daily" : "One-time")
                        .font(.caption2)
                } icon: {
                    Image(systemName: trigger.repeats ? "repeat" : "1.circle")
                        .imageScale(.small)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .swipeActions {
            Button("Delete", role: .destructive) {
                let notificationIdentifier = request.identifier
                let uuid = notificationIdentifier.components(separatedBy: "_").first ?? ""
                lnManager.removeRequest(withIdentifier: notificationIdentifier)
            }
        }
    }
}
