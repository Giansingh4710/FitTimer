import SwiftUI
import UserNotifications

struct ActivityDetailModal: View {
    @Environment(\.dismiss) var dismiss
    @State var activity: DailyActivity

    @State private var newName: String = ""
    @State private var newCount: Int = 0
    @State private var todayCount: Int = 0
    @State private var notificationTimes: [DateComponents] = []
    @State private var newResetDaily: Bool = true
    @State private var lastCountedDate: Date = .init()
    @State private var createdAt: Date = .init()

    var body: some View {
        NavigationView {
            List {
                // Name Section
                Section {
                    TextField("Activity Name", text: $newName)
                } header: {
                    Text("Activity Details")
                }

                // Counter Section
                Section {
                    HStack(spacing: 20) {
                        Label("Decrease", systemImage: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .frame(width: 60, height: 44)
                            .onTapGesture {
                                decrementCount()
                            }

                        Text("\(newCount)")
                            .font(.system(size: 48, weight: .bold))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)

                        Button(action: incrementCount) {
                            Label("Increase", systemImage: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        .frame(width: 60, height: 44)
                    }
                    .labelStyle(.iconOnly)

                    HStack {
                        Text("Created: ")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatedDate(createdAt))
                    }.font(.subheadline)
                    HStack {
                        Text("Last counted")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatedDate(lastCountedDate))
                    }.font(.subheadline)
                } header: {
                    Text("Counter")
                }

                // Settings Section
                Section {
                    Toggle("Reset Count Daily", isOn: $newResetDaily)
                } header: {
                    Text("Settings")
                }

                // Activity History Section
                Section {
                    if activity.history.count > 0 {
                        DisclosureGroup("Activity History") {
                            ForEach(activity.history, id: \.date) { entry in
                                HStack {
                                    Text(entry.date, style: .date)
                                    Spacer()
                                    Text("Count: \(entry.count)")
                                        .bold()
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }

                // Notifications Section
                Section {
                    ForEach(notificationTimes.indices, id: \.self) { index in
                        HStack {
                            DatePicker(
                                "Time",
                                selection: Binding(
                                    get: { Calendar.current.date(from: notificationTimes[index]) ?? Date() },
                                    set: { newDate in
                                        notificationTimes[index] = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )

                            Button(action: { notificationTimes.remove(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    Button(action: {
                        notificationTimes.append(Calendar.current.dateComponents([.hour, .minute], from: Date()))
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Notification Time")
                        }
                    }
                } header: {
                    Text("Daily Notifications")
                }

                // Reset Button Section
                Section {
                    Button(role: .destructive) {
                        newCount = 0
                    } label: {
                        Text("Reset Count")
                            .frame(maxWidth: .infinity)
                    }
                }
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
            newName = activity.name
            newCount = activity.count
            notificationTimes = activity.notifications
            newResetDaily = activity.resetDaily
            lastCountedDate = activity.lastCounted
            createdAt = activity.createdAt
        }
    }

    private func incrementCount() {
        newCount += 1
        todayCount += 1
    }

    private func decrementCount() {
        if newCount > 0 {
            newCount -= 1
            todayCount -= 1
        }
    }

    private func deleteNotificationTime(at offsets: IndexSet) {
        notificationTimes.remove(atOffsets: offsets)
    }

    private func saveChanges() {
        activity.name = newName
        activity.notifications = notificationTimes
        activity.resetDaily = newResetDaily
        if newCount != activity.count {
            activity.lastCounted = Date()
            activity.count = newCount
            activity.todayCount = todayCount
        }
        scheduleNotifications(for: activity)
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

    private func formatedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
