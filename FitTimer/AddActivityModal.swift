import SwiftUI
import UserNotifications

struct AddActivityModal: View {
    @Environment(\.dismiss) var dismiss
    @Binding var dailyActivities: [DailyActivity]
    @State private var activityName: String = ""
    @State private var notificationTimes: [Date] = [Date()]
    @State private var showingNotificationPermissionAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Details")) {
                    TextField("Activity Name", text: $activityName)
                }

                Section(header: Text("Notification Times")) {
                    ForEach(notificationTimes.indices, id: \.self) { index in
                        DatePicker("Time \(index + 1)", selection: $notificationTimes[index], displayedComponents: .hourAndMinute)
                    }
                    .onDelete(perform: deleteNotificationTime)

                    Button(action: {
                        notificationTimes.append(Date())
                    }) {
                        Label("Add Notification Time", systemImage: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }

                Section(footer: Text("Notifications will repeat daily at these times")) {
                    EmptyView()
                }
            }
            .navigationTitle("New Activity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActivity()
                    }
                    .disabled(activityName.isEmpty || notificationTimes.isEmpty)
                }
            }
        }
        .alert("Notification Permission Required", isPresented: $showingNotificationPermissionAlert) {
            Button("Open Settings", role: .none) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to receive activity reminders.")
        }
    }

    private func deleteNotificationTime(at offsets: IndexSet) {
        notificationTimes.remove(atOffsets: offsets)
    }

    private func saveActivity() {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    let notificationComponents = notificationTimes.map { date in
                        Calendar.current.dateComponents([.hour, .minute], from: date)
                    }
                    
                    let newActivity = DailyActivity(name: activityName, count: 0, notifications: notificationComponents)
                    dailyActivities.append(newActivity)
                    scheduleNotifications(for: newActivity)
                    dismiss()
                }
            } else {
                DispatchQueue.main.async {
                    showingNotificationPermissionAlert = true
                }
            }
        }
    }

    private func scheduleNotifications(for activity: DailyActivity) {
        let center = UNUserNotificationCenter.current()
        
        // Remove any existing notifications for this activity
        center.removePendingNotificationRequests(withIdentifiers: 
            activity.notifications.map { "\(activity.id)_\($0.hour ?? 0)_\($0.minute ?? 0)" }
        )
        
        // Schedule new notifications
        for components in activity.notifications {
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            
            let content = UNMutableNotificationContent()
            content.title = "Time for \(activity.name)!"
            content.body = "Track your progress by adding to your daily count."
            content.sound = .default
            content.badge = 1
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(activity.id)_\(components.hour ?? 0)_\(components.minute ?? 0)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
}

// Helper extension to format time
extension Date {
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
} 