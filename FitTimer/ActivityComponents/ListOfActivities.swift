import SwiftData
import SwiftUI

struct ListOfActivities: View {
    @Binding var showAddActivityModal: Bool

    @State private var showInputAlert = false
    @State private var addToCount = ""

    @State private var swipedRightOnActivity: Activity?

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
                    swipedRight: { activity in
                        swipedRightOnActivity = activity
                        showInputAlert = true
                    },
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

        .alert("How many did you do? (doesn't work sometimes)", isPresented: $showInputAlert) {
            if let activity = swipedRightOnActivity {
                TextField("5", text: $addToCount).keyboardType(.numbersAndPunctuation)
                Button("Add") {
                    print("before increment function for \(activity.name)") // Debug
                    incrementCount(for: activity)
                }
                Button("Cancel", role: .cancel, action: { addToCount = "" })
            } else {
                Text("Something went wrong. Activity not found").foregroundColor(.red)
                Button("Cancel", role: .cancel, action: { addToCount = "" })
            }
        }
    }

    private func incrementCount(for activity: Activity) {
        print("Incrementing count for \(activity.name)")
        guard let incrementBy = Int(addToCount) else {
            print("Invalid input: \(addToCount)")
            return
        }

        print("Adding \(incrementBy) to \(activity.name) from input \(addToCount)")

        if activity.isNewDay() {
            activity.updateIfNewDay()
        }

        activity.count += incrementBy
        activity.todayCount += incrementBy
        activity.lastCounted = Date()

        addToCount = ""
    }
}

struct ActivityRow: View {
    let activity: Activity
    let swipedRight: (Activity) -> Void
    let deleteAction: () -> Void

    var body: some View {
        NavigationLink(destination: ActivityDetailView(activity: activity)) {
            HStack {
                VStack(alignment: .leading) {
                    Text(activity.name).font(.headline)
                    Text("\(activity.notifications.count) reminders").font(.caption).foregroundColor(.secondary)
                    Text("\(activity.todayCount) today").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if let nextTime = activity.formatNextNotification() {
                    VStack(alignment: .leading) {
                        Text("Next Reminder:").font(.caption)
                        Text("\(nextTime)").font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text("Count: \(activity.count)").font(.subheadline)
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                swipedRight(activity)
            } label: {
                Label("Increase", systemImage: "plus.circle.fill")
            }
            .tint(.blue)
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
