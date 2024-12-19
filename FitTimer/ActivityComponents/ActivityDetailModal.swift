import SwiftUI
import UserNotifications

struct ActivityDetailModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var lnManager: LocalNotificationManager
    @State var activity: Activity

    @State private var newName: String = ""
    @State private var newCount: Int = 0
    @State private var todayCount: Int = 0
    @State private var notificationTimes: [DateComponents] = []
    @State private var newResetDaily: Bool = true
    @State private var lastCountedDate: Date = .init()
    @State private var createdAt: Date = .init()

    @State private var showingNotificationPermissionAlert = false

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
                        Task {
                            await saveChanges()
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showingNotificationPermissionAlert) {
            Alert(
                title: Text("Turn On Notifications"),
                message: Text("Can't send notifications without permission. If you click OK, you will basically have a counter and won't get any reminders"),
                primaryButton: .default(
                    Text("Ok"),
                    action: {
                        activity.notifications = []
                    }
                ),
                secondaryButton: .cancel(
                    Text("Cancel"),
                    action: {}
                )
            )
        }
        .onAppear {
            newName = activity.name
            newCount = activity.count
            todayCount = activity.todayCount
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
        newCount -= 1
        todayCount -= 1
    }

    private func saveChanges() async {
        if notificationTimes.count > 0 {
            if lnManager.isGranted == false {
                showingNotificationPermissionAlert = true
                return
            }
        }

        activity.notifications = notificationTimes
        await lnManager.scheduleNotificationsForActivity(activity: activity)
        activity.name = newName
        activity.resetDaily = newResetDaily
        if newCount != activity.count {
            activity.lastCounted = Date()
            activity.count = newCount
            activity.todayCount = todayCount
        }
        dismiss()
    }

    private func formatedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
