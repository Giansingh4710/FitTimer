import SwiftData
import SwiftUI

struct ListOfActivities: View {
    @Binding var activityToShow: Activity?
    @Binding var showAddActivityModal: Bool

    // @Query(sort: \Activity.createdAt, order: .reverse) private var activities: [Activity]
    @Query(sort: \Activity.createdAt) private var activities: [Activity]
    @State private var selectedActivity: Activity? = nil
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var lnManager: LocalNotificationManager

    var body: some View {
        Section {
            ForEach(activities) { activity in
                ActivityRow(
                    activity: activity,
                    selectActivity: { activityToShow = activity },
                    deleteAction: {
                        Task {
                            await lnManager.removeNotifications(for: activity)
                            modelContext.delete(activity)
                        }
                    }
                )
            }
            Button(action: {
                showAddActivityModal = true
            }) {
                Label("Add Activity", systemImage: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        } header: {
            HStack {
                Text(activities.count == 1 ? "1 Activity" : "\(activities.count) Activities")
                    .font(.title2)
                    .bold()
                InfoButton(
                    title: "✨ Activities",
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
        .onAppear {
            for activity in activities {
                activity.updateIfNewDay()
                Task {
                    await lnManager.scheduleNotifications(for: activity)
                }
            }
        }
    }
}

struct ActivityRow: View {
    @State var activity: Activity
    let selectActivity: () -> Void
    let deleteAction: () -> Void

    @State private var showInputAlert = false
    @State private var addToCount = ""

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(activity.name).font(.headline)
                Text("\(activity.notifications.count) reminders").font(.caption).foregroundColor(.secondary)
                // Text("Reset Count: \(activity.resetDaily ? "Daily" : "Never")").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if let nextTime = activity.formatNextNotification() {
                VStack(alignment: .leading) {
                    Text("Next Reminder:").font(.caption)
                    Text("\(nextTime)").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()

            Button(action: selectActivity) {
                // button will run when whole row tapped. Not Warping here because has styling side effects
                Text("Count: \(activity.count)").font(.subheadline)
            }
        }
        .alert("How many \(activity.name)s did you do?", isPresented: $showInputAlert) {
            TextField("5", text: $addToCount).keyboardType(.numbersAndPunctuation)
            Button("OK", action: incrementCount)
            Button("Cancel", role: .cancel, action: { addToCount = "" })
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

    private func incrementCount() {
        activity.count += Int(addToCount) ?? 0
        activity.todayCount += Int(addToCount) ?? 0
        activity.lastCounted = Date()
        addToCount = ""
    }
}
