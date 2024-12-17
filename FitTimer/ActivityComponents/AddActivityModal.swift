import SwiftData
import SwiftUI
import UserNotifications

struct AddActivityModal: View {
    @Environment(\.modelContext) var modelContext

    @Environment(\.dismiss) var dismiss
    @State private var activityName: String = "bob"
    @State private var notificationTimes: [Date] = [Date()]
    @State private var showingNotificationPermissionAlert = false
    @State private var numberOfRandomTimes: String = ""
    @State private var showingRandomTimesAlert = false
    @FocusState private var isNumberInputFocused: Bool

    @State private var resetDaily: Bool = true

    var body: some View {
        NavigationView {
            Form {

                Section(header: Text("Activity Details")) {
                    TextField("Activity Name", text: $activityName)
                }

                Section(header: Text("Have the Counter Reset to 0 Every Day?")) {
                    Toggle("Reset Count Daily", isOn: $resetDaily)
                }

                Section(header: Text("Notification Times")) {
                    HStack {
                        TextField("Enter number (max 100)", text: $numberOfRandomTimes)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isNumberInputFocused)
                            .submitLabel(.done)
                        Button(action: {
                            generateRandomTimes()
                        }) {
                            Label("Generate", systemImage: "dice.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 5)
                    Text("Tap generate or press return to create random times")
                        .font(.caption)
                        .foregroundColor(.secondary)

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
                    .disabled(activityName.isEmpty)
                }
            }
        }
        .alert(isPresented: $showingNotificationPermissionAlert) {
            Alert(
                title: Text("Notification Permission Required to Get Reminders"),
                message: Text("if you click OK, you will basically have a counter and won't get any reminders"),
                primaryButton: .default(
                    Text("Ok"),
                    action: {
                        let newActivity = DailyActivity(name: activityName, count: 0, notifications: [], resetDaily: resetDaily)
                        modelContext.insert(newActivity)
                        dismiss()
                    }
                ),
                secondaryButton: .destructive(
                    Text("Cancel"),
                    action: {
                        dismiss()
                    }
                )
            )
        }
        .alert("Invalid Input", isPresented: $showingRandomTimesAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter a number between 1 and 100")
        }
        // .alert("Notification Permission Required", isPresented: $showingNotificationPermissionAlert) {
        //     Button("Open Settings", role: .none) {
        //         if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        //             UIApplication.shared.open(settingsURL)
        //         }
        //     }
        //     Button("Cancel", role: .cancel) {}
        // } message: {
        //     Text("Please enable notifications in Settings to receive activity reminders.")
        // }
    }

    private func deleteNotificationTime(at offsets: IndexSet) {
        notificationTimes.remove(atOffsets: offsets)
    }

    private func generateRandomTimes() {
        guard let count = Int(numberOfRandomTimes), count > 0, count <= 100 else {
            showingRandomTimesAlert = true
            return
        }

        isNumberInputFocused = false

        // Clear existing times
        notificationTimes.removeAll()

        // Generate random times between 8 AM and 10 PM
        let calendar = Calendar.current
        var date = Date()
        date = calendar.startOfDay(for: date)

        // Set base date to 8 AM
        date = calendar.date(byAdding: .hour, value: 8, to: date) ?? date

        // Calculate seconds between 8 AM and 10 PM (14 hours)
        let secondsInRange = 14 * 60 * 60

        // Generate unique random times
        var usedMinutes = Set<Int>()

        while notificationTimes.count < count {
            let randomSeconds = Int.random(in: 0 ..< secondsInRange)
            let totalMinutes = randomSeconds / 60

            if !usedMinutes.contains(totalMinutes) {
                usedMinutes.insert(totalMinutes)

                if let newTime = calendar.date(byAdding: .second, value: randomSeconds, to: date) {
                    notificationTimes.append(newTime)
                }
            }
        }

        // Sort times chronologically
        notificationTimes.sort()

        // Clear the input field
        // numberOfRandomTimes = ""
    }

    private func saveActivity() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    let notificationComponents = notificationTimes.map { date in
                        Calendar.current.dateComponents([.hour, .minute], from: date)
                    }

                    let newActivity = DailyActivity(name: activityName, count: 0, notifications: notificationComponents, resetDaily: resetDaily)
                    print(newActivity)
                    modelContext.insert(newActivity)

                    scheduleNotifications(for: newActivity)
                }
                dismiss()
            } else {
                showingNotificationPermissionAlert = true
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
