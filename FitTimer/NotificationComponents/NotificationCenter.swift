import SwiftData
import SwiftUI

struct UpcomingNotificationsView: View {
    @EnvironmentObject private var lnManager: LocalNotificationManager

    var body: some View {
        List {
            Section {
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
                    ForEach(lnManager.pendingRequests, id: \.identifier) { request in
                        NotificationBar(request: request)
                    }
                }
            } header: {
                Text("Notifications")
            }
        }
        .toolbar {
            if !lnManager.pendingRequests.isEmpty {
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
