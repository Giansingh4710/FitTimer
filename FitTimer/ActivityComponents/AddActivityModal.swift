import SwiftData
import SwiftUI
import UserNotifications

struct AddActivityModal: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var lnManager: LocalNotificationManager
    @Environment(\.dismiss) var dismiss
    @State private var activityName: String = "bob"
    @State private var showingNotificationPermissionAlert = false
    @FocusState private var isNumberInputFocused: Bool

    @State var numberOfRandomTimes: String = ""
    @State var notificationTimes: [DateComponents] = []

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

                AddNotificationView(
                    numberOfRandomTimes: $numberOfRandomTimes,
                    notificationTimes: $notificationTimes
                )
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
        .onAppear {
            notificationTimes.append(Calendar.current.dateComponents([.hour, .minute], from: Date()))
        }
    }

    private func deleteNotificationTime(at offsets: IndexSet) {
        notificationTimes.remove(atOffsets: offsets)
    }

    private func saveActivity() async {
        if lnManager.isGranted == false {
            showingNotificationPermissionAlert = true
            return
        }

        let newActivity = Activity(name: activityName, count: 0, notifications: notificationTimes, resetDaily: resetDaily)
        modelContext.insert(newActivity)

        await lnManager.scheduleNotificationsForActivity(activity: newActivity)
        dismiss()
    }
}
