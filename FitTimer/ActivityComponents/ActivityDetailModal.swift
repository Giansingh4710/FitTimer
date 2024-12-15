import SwiftUI
import UserNotifications

struct ActivityDetailModal: View {
    @Environment(\.dismiss) var dismiss
    @State var activity: DailyActivity
    @Binding var dailyActivities: [DailyActivity]

    @State private var notificationTimes: [DateComponents] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Activity Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity Details")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        TextField("Activity Name", text: $activity.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal)

                    // Counter Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Count")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        HStack {
                            Spacer()
                            Button(action: {
                                if activity.count > 0 {
                                    activity.count -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(.accentColor)
                            }
                            .frame(width: 44, height: 44)
                            .buttonStyle(BorderlessButtonStyle())

                            Text("\(activity.count)")
                                .font(.title2.bold())
                                .frame(minWidth: 40)

                            Button(action: {
                                incrementCount()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(.accentColor)
                            }
                            .frame(width: 44, height: 44)
                            .buttonStyle(BorderlessButtonStyle())
                            Spacer()
                        }
                    }
                    .padding(.horizontal)

                    // Notifications Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Notifications")
                            .font(.headline)
                            .foregroundColor(.secondary)

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

                                Spacer()

                                Button(action: {
                                    notificationTimes.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        Button(action: {
                            let newComponents = Calendar.current.dateComponents([.hour, .minute], from: Date())
                            notificationTimes.append(newComponents)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Notification Time")
                            }
                        }
                        .padding(.top, 8)

                        Text("Notifications will repeat daily at these times")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)

                    // Reset Button
                    Button(role: .destructive) {
                        activity.count = 0
                    } label: {
                        Text("Reset Count")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
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
        }
        .onAppear {
            // Initialize notification times from activity
            notificationTimes = activity.notifications
        }
    }

    private func deleteNotificationTime(at offsets: IndexSet) {
        notificationTimes.remove(atOffsets: offsets)
    }

    private func saveChanges() {
        activity.notifications = notificationTimes
        scheduleNotifications(for: activity)
        updateActivity(activity, &dailyActivities)
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

    private func incrementCount() {
        if let index = dailyActivities.firstIndex(where: { $0.id == activity.id }) {
            dailyActivities[index].count += 1
            // Update the activity count and save
            updateActivity(dailyActivities[index], &dailyActivities)
            // Log all activities to history
            HistoryManager.shared.logActivityCounts(dailyActivities)
        }
    }
}
