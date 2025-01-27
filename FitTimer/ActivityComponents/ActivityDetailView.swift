import SwiftUI
import UserNotifications

struct ActivityDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var lnManager: LocalNotificationManager
    @State var activity: Activity

    @State private var newName: String = ""
    @State private var newCount: Int = 0
    @State private var notificationTimes: [DateComponents] = []
    @State private var newResetDaily: Bool = true
    @State private var lastCountedDate: Date = .init()
    @State private var createdAt: Date = .init()

    @State private var notificationText: NotificationTextData = .init(title: "", body: "")

    @State private var showInputAlert = false
    @State private var addToCount = ""

    var body: some View {
        NavigationView {
            List {
                // Name Section
                Section {
                    TextField("Activity Name", text: $newName)
                } header: {
                    HStack {
                        Text("Activity Name")
                        InfoButton(
                            title: "📝 Activity Name",
                            message: "UUID: \(activity.id.uuidString)"
                        )
                    }
                }

                // Counter Section
                Section {
                    VStack(spacing: 12) {
                        // Counter Controls
                        HStack(spacing: 16) {
                            Label("Decrease", systemImage: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.accentColor)
                                .onTapGesture { decrementCount() }
                                .buttonStyle(.plain)

                            TextField("Count", value: $newCount, format: .number)
                                .textFieldStyle(.plain)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .keyboardType(.numbersAndPunctuation)
                                .minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )

                            Label("Increase", systemImage: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.accentColor)
                                .onTapGesture { incrementCount(1) }
                                .buttonStyle(.plain)
                        }
                        .padding(.horizontal)

                        // Quick Increment Buttons
                        HStack(spacing: 12) {
                            ForEach([5, 10, 25], id: \.self) { value in
                                SmallPlusText(text: "+\(value)", action: { incrementCount(value) })
                            }
                            SmallPlusText(text: "+", action: { showInputAlert = true })
                        }
                        .padding(.horizontal)
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
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
                    HStack {
                        Text("Current Streak")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(activity.calculateStreak()))
                    }.font(.subheadline)
                    HStack {
                        Text("Today's Count")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(activity.todayCount))
                    }.font(.subheadline)
                } header: {
                    Text("Counter")
                }

                // Settings Section
                Section {
                    Toggle("Reset Count Daily", isOn: $newResetDaily)
                    Button("") {
                        for history in activity.history {
                           print("Date: \(history.date), Count: \(history.count)") 
                        }
                    }
                } header: {
                    Text("Settings")
                }

                // Activity History Section
                Section {
                    if activity.history.count > 0 {
                        DisclosureGroup("Activity History: \(activity.history.count)") {
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

                AddNotificationView(
                    notificationTimes: $notificationTimes,
                    notificationText: $notificationText
                )
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // ToolbarItem(placement: .cancellationAction) {
                //     Button("Cancel") {
                //         dismiss()
                //     }
                // }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
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
            notificationText = activity.notificationText
        }
        .alert("How many '\(activity.name)'s did you do?", isPresented: $showInputAlert) {
            TextField("5", text: $addToCount).keyboardType(.numbersAndPunctuation)
            Button("Add") {
                print("before incrementBy function for \(activity.name)") // Debug
                guard let incrementBy = Int(addToCount) else {
                    print("Invalid input: \(addToCount)")
                    addToCount = ""
                    return
                }
                incrementCount(incrementBy)
                addToCount = ""
            }
            Button("Cancel", role: .cancel, action: { addToCount = "" })
        }
    }

    private func incrementCount(_ value: Int = 1) {
        newCount += value
    }

    private func decrementCount() {
        newCount -= 1
    }

    private func saveChanges() async {
        activity.notifications = notificationTimes
        await lnManager.scheduleNotifications(for: activity)
        activity.name = newName
        activity.resetDaily = newResetDaily
        if newCount != activity.count {
            if activity.isNewDay() { activity.updateIfNewDay() }
            activity.lastCounted = Date()
            activity.todayCount += (newCount - activity.count)
            activity.count = newCount
        }
        activity.notificationText = notificationText
        dismiss()
    }

    private func formatedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SmallPlusText: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
            .onTapGesture {
                action()
            }
    }
}
