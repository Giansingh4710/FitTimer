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

    @State private var notificationText: NotificationTextData = .init(title: "", body: "")

    @State private var numberOfRandomTimes: String = ""
    @State private var showingRandomTimesAlert = false

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
                                .onTapGesture { incrementCount() }
                                .buttonStyle(.plain)
                        }
                        .padding(.horizontal)

                        // Quick Increment Buttons
                        HStack(spacing: 12) {
                            ForEach([5, 10, 25], id: \.self) { value in
                                Text("+\(value)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.accentColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.accentColor, lineWidth: 1)
                                    ).onTapGesture {
                                        newCount += value
                                    }
                            }
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

                AddNotificationView(
                    numberOfRandomTimes: $numberOfRandomTimes,
                    notificationTimes: $notificationTimes,
                    notificationText: $notificationText
                )
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
        .onAppear {
            newName = activity.name
            newCount = activity.count
            todayCount = activity.todayCount
            notificationTimes = activity.notifications
            newResetDaily = activity.resetDaily
            lastCountedDate = activity.lastCounted
            createdAt = activity.createdAt
            notificationText = activity.notificationText
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
        activity.notifications = notificationTimes
        await lnManager.scheduleNotifications(for: activity)
        activity.name = newName
        activity.resetDaily = newResetDaily
        if newCount != activity.count {
            activity.lastCounted = Date()
            activity.count = newCount
            activity.todayCount = todayCount
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
