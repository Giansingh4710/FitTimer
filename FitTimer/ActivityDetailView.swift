import SwiftUI
import UserNotifications

struct ActivityDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var activity: DailyActivity
    var onSave: (DailyActivity) -> Void
    @State private var notificationTimes: [Date] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Details")) {
                    TextField("Activity Name", text: $activity.name)
                    HStack {
                        Text("Count: \(activity.count)")
                        Spacer()
                        Button(action: {
                            activity.count += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        Button(action: {
                            if activity.count > 0 {
                                activity.count -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
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

                Section {
                    Button("Reset Count", role: .destructive) {
                        activity.count = 0
                    }
                }
            }
            .navigationTitle("Edit Activity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                // Convert DateComponents to Date for editing
                notificationTimes = activity.notifications.compactMap { components in
                    var dateComponents = DateComponents()
                    dateComponents.hour = components.hour
                    dateComponents.minute = components.minute
                    return Calendar.current.date(from: dateComponents) ?? Date()
                }
            }
        }
    }

    private func deleteNotificationTime(at offsets: IndexSet) {
        notificationTimes.remove(atOffsets: offsets)
    }

    private func saveChanges() {
        activity.notifications = notificationTimes.map { date in
            Calendar.current.dateComponents([.hour, .minute], from: date)
        }
        
        scheduleNotifications(for: activity)
        onSave(activity)
        dismiss()
    }

    private func scheduleNotifications(for activity: DailyActivity) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications
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