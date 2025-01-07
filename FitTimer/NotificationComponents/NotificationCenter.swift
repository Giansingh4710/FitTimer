import SwiftData
import SwiftUI

struct UpcomingNotificationsView: View {
    @EnvironmentObject private var lnManager: LocalNotificationManager
    @State private var showRemoveAllNotificationsAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(
                    title: { Text("Total \(lnManager.pendingRequests.count) Notifications") },
                    icon: { Image(systemName: "bell.fill") }
                )
                .font(.headline)
                .foregroundStyle(.primary)
                
                Spacer()
                
                Text(Date(), style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
            
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
                    Text("All Notifications")
                }
            }
        }
        .alert("Clear All Notifications?", isPresented: $showRemoveAllNotificationsAlert) {
            Button("Clear All", role: .destructive) {
                lnManager.clearRequests()
            }
            Button("Cancel", role: .cancel) {}
        }
        .toolbar {
            if !lnManager.pendingRequests.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showRemoveAllNotificationsAlert = true
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
