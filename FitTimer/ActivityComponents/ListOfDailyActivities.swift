import SwiftUI

struct ListOfDailyActivities: View {
    @Binding var dailyActivities: [DailyActivity]
    @Binding var activityToShow: DailyActivity?
    @Binding var showAddActivityModal: Bool

    @State private var selectedActivity: DailyActivity? = nil

    var body: some View {
        Section {
            ForEach($dailyActivities) { activity in
                ActivityRow(
                    activity: activity,
                    activityToShow: $activityToShow,
                    deleteAction: {
                        if let index = dailyActivities.firstIndex(where: { $0.id == activity.id }) {
                            let activity = dailyActivities[index]
                            NotificationManager.shared.removeNotifications(for: activity)
                            dailyActivities.remove(at: index)
                            saveActivities(dailyActivities)
                        }
                    },
                    saveAction: {
                        saveActivities(dailyActivities)
                    }
                )
            }
            Button(action: {
                showAddActivityModal = true
            }) {
                Label("Add Daily Activity", systemImage: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        } header: {
            HStack {
                Text("Daily Activities")
                    .font(.title2)
                    .bold()
                InfoButton(
                    title: "✨ Daily Activities",
                    message: """
                    Build healthy habits throughout your day!

                    • Track regular activities
                    • Set helpful reminders
                    • Keep count of completions
                    • Perfect for water breaks, stretching, or quick exercises
                    """
                )
            }
        }
    }

    private func getNextNotification(for activity: DailyActivity) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        return activity.notifications.compactMap { components -> Date? in
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            dateComponents.day = calendar.component(.day, from: now)
            dateComponents.month = calendar.component(.month, from: now)
            dateComponents.year = calendar.component(.year, from: now)

            guard let date = calendar.date(from: dateComponents) else { return nil }
            return date > now ? date : calendar.date(byAdding: .day, value: 1, to: date)
        }.min()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ActivityRow: View {
    // @State var activity: DailyActivity
    @Binding var activity: DailyActivity
    @Binding var activityToShow: DailyActivity?
    let deleteAction: () -> Void
    let saveAction: () -> Void

    @State private var showInputAlert = false
    @State private var addToCount = ""

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(activity.name).font(.headline)
                Text("\(activity.notifications.count) reminders").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if let nextTime = activity.formatNextNotification() {
                VStack(alignment: .leading) {
                    Text("Next Reminder:").font(.caption)
                    Text("\(nextTime)").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: { // button will run when whole row tapped. Not Warping here because has styling side effects
                activityToShow = activity
            }) {
                Text("Count: \(activity.count)").font(.subheadline)
            }
        }
        .alert("How many \(activity.name)s did you do?", isPresented: $showInputAlert) {
            TextField("5", text: $addToCount).keyboardType(.numberPad)
            Button("OK", action: {
                activity.count += Int(addToCount) ?? 0
                addToCount = ""
                saveAction()
            })
            Button("Cancel", role: .cancel) {
                addToCount = ""
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                showInputAlert = true
            } label: {
                Label("Increase", systemImage: "plus.circle.fill")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteAction()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
