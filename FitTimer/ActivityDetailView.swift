import SwiftUI
import UserNotifications

struct ActivityDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var activity: DailyActivity
    var onSave: (DailyActivity) -> Void
    @State private var notificationTimes: [DateComponents] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Activity Name", text: $activity.name)
                        .font(.body)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 8)
                } header: {
                    Text("Activity Details")
                        .font(.headline)
                }

                Section {
                    HStack {
                        Text("Daily Count")
                            .font(.body)
                        Spacer()
                        HStack(spacing: 20) {
                            Button(action: {
                                if activity.count > 0 {
                                    activity.count -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 44, height: 44) // Apple's minimum touch target size
                            }
                            
                            Text("\(activity.count)")
                                .font(.headline)
                            
                            Button(action: {
                                activity.count += 1
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    ForEach(notificationTimes.indices, id: \.self) { index in
                        HStack {
                            DatePicker(
                                "Notification \(index + 1)",
                                selection: Binding(
                                    get: {
                                        Calendar.current.date(from: notificationTimes[index]) ?? Date()
                                    },
                                    set: { newDate in
                                        notificationTimes[index] = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                        }
                    }
                    .onDelete(perform: deleteNotificationTime)

                    Button(action: {
                        let newComponents = Calendar.current.dateComponents([.hour, .minute], from: Date())
                        notificationTimes.append(newComponents)
                    }) {
                        Label("Add Notification Time", systemImage: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Daily Notifications")
                        .font(.headline)
                } footer: {
                    Text("Notifications will repeat daily at these times")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        activity.count = 0
                    } label: {
                        Text("Reset Count")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
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
                // Initialize notification times from activity
                notificationTimes = activity.notifications
            }
        }
    }

    private func deleteNotificationTime(at offsets: IndexSet) {
        notificationTimes.remove(atOffsets: offsets)
    }

    private func saveChanges() {
        activity.notifications = notificationTimes
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
            let content = UNMutableNotificationContent()
            content.title = "Time for \(activity.name)!"
            content.body = "Track your progress by adding to your daily count."
            content.sound = .default
            content.badge = 1
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
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
