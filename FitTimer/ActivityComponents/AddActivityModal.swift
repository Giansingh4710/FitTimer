import SwiftData
import SwiftUI
import UserNotifications

struct AddActivityModal: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var lnManager: LocalNotificationManager
    @Environment(\.dismiss) var dismiss
    @State private var activityName: String = ""
    @FocusState private var isNumberInputFocused: Bool

    @State var numberOfRandomTimes: String = ""
    @State var notificationTimes: [DateComponents] = []
    @State var notificationText: NotificationTextData = .init(title: "", body: "")

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
                    notificationTimes: $notificationTimes,
                    notificationText: $notificationText
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
        .onAppear {
            notificationTimes.append(Calendar.current.dateComponents([.hour, .minute], from: Date()))
        }
    }

    private func deleteNotificationTime(at offsets: IndexSet) {
        notificationTimes.remove(atOffsets: offsets)
    }

    private func saveActivity() async {
        let newActivity = Activity(name: activityName, count: 0, notifications: notificationTimes, resetDaily: resetDaily)
        modelContext.insert(newActivity)

        await lnManager.scheduleNotifications(for: newActivity)
        dismiss()
    }
}
