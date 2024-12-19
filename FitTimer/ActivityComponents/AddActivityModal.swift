import SwiftData
import SwiftUI
import UserNotifications

struct AddActivityModal: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var lnManager: LocalNotificationManager
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
                        Task {
                            await saveActivity()
                        }
                    }
                    .disabled(activityName.isEmpty)
                }
            }
        }
        .alert(isPresented: $showingNotificationPermissionAlert) {
            Alert(
                title: Text("Turn On Notifications"),
                message: Text("Notification Permissions Required to Get Reminders. If you click OK, you will basically have a counter and won't get any reminders"),
                primaryButton: .default(
                    Text("Ok"),
                    action: {
                        let newActivity = Activity(name: activityName, count: 0, notifications: [], resetDaily: resetDaily)
                        modelContext.insert(newActivity)
                        dismiss()
                    }
                ),
                secondaryButton: .cancel(
                    Text("Cancel"),
                    action: {
                        // dismiss()
                    }
                )
            )
        }
        .alert("Invalid Input", isPresented: $showingRandomTimesAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter a number between 1 and 100")
        }
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

    private func saveActivity() async {
        if lnManager.isGranted == false {
            showingNotificationPermissionAlert = true
            return
        }

        let notificationComponents = notificationTimes.map { date in
            Calendar.current.dateComponents([.hour, .minute], from: date)
        }

        let newActivity = Activity(name: activityName, count: 0, notifications: notificationComponents, resetDaily: resetDaily)
        modelContext.insert(newActivity)

        await lnManager.scheduleNotificationsForActivity(activity: newActivity)
        dismiss()
    }
}
