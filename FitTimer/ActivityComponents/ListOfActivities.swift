import SwiftData
import SwiftUI

struct ListOfActivities: View {
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

// struct ActivityRow: View {
//     let activity: Activity // before was @State let activity and that was potential issue for incrementCount not working at random times
//     let deleteAction: () -> Void
//
//     @State private var showInputAlert = false
//     @State private var addToCount = ""
//
//     var body: some View {
//         NavigationLink(destination: ActivityDetailView(activity: activity)) {
//             HStack {
//                 VStack(alignment: .leading) {
//                     Text(activity.name).font(.headline)
//                     Text("\(activity.notifications.count) reminders").font(.caption).foregroundColor(.secondary)
//                     Text("\(activity.history.count) history").font(.caption).foregroundColor(.secondary)
//                 }
//                 Spacer()
//                 if let nextTime = activity.formatNextNotification() {
//                     VStack(alignment: .leading) {
//                         Text("Next Reminder:").font(.caption)
//                         Text("\(nextTime)").font(.caption).foregroundColor(.secondary)
//                     }
//                 }
//                 Spacer()
//
//                 Text("Count: \(activity.count)").font(.subheadline)
//             }
//         }
//         .alert("How many \(activity.name)s did you do?", isPresented: $showInputAlert) {
//             TextField("5", text: $addToCount).keyboardType(.numbersAndPunctuation)
//             Button("OK", action: incrementCount)
//             Button("Cancel", role: .cancel, action: { addToCount = "" })
//         }
//         .swipeActions(edge: .leading) {
//             Button {
//                 showInputAlert = true
//             } label: {
//                 Label("Increase", systemImage: "plus.circle.fill")
//             }
//         }
//         .swipeActions(edge: .trailing) {
//             Button(role: .destructive) {
//                 deleteAction()
//             } label: {
//                 Label("Delete", systemImage: "trash")
//             }
//         }
//     }
//
//     private func incrementCount() {
//         guard let increment = Int(addToCount), increment > 0 else {
//             addToCount = ""
//             return
//         }
//
//         if activity.isNewDay() {
//             activity.updateIfNewDay()
//         }
//
//         activity.count += increment
//         activity.todayCount += increment
//         activity.lastCounted = Date()
//         addToCount = ""
//     }
// }

struct ActivityRow: View {
    let activity: Activity
    let deleteAction: () -> Void

    @State private var showInputAlert = false
    @State private var addToCount = ""
    var body: some View {
        NavigationLink(destination: ActivityDetailView(activity: activity)) {
            HStack {
                VStack(alignment: .leading) {
                    Text(activity.name).font(.headline)
                    Text("\(activity.notifications.count) reminders").font(.caption).foregroundColor(.secondary)
                    Text("\(activity.history.count) history").font(.caption).foregroundColor(.secondary)
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
        .alert("How many \(activity.name)s did you do?", isPresented: $showInputAlert) {
            TextField("Enter number", text: $addToCount).keyboardType(.numbersAndPunctuation)
            Button("Add") {
                print("\(activity.name) - Add button tapped")
                incrementCount()
                showInputAlert = false
            }
            Button("Cancel", role: .cancel) {
                addToCount = ""
                showInputAlert = false
            }
        }
        .onChange(of: showInputAlert) { _, newValue in
            if !newValue {
                // Clear the input when alert is dismissed
                addToCount = ""
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                addToCount = ""
                showInputAlert = true
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

    private func incrementCount() {
        print("Incrementing count for \(activity.name)")
        guard let increment = Int(addToCount) else {
            print("Invalid input: \(addToCount)")
            return
        }

        print("Adding \(increment) to \(activity.name) from input \(addToCount)")

        if activity.isNewDay() {
            activity.updateIfNewDay()
        }

        activity.count += increment
        activity.todayCount += increment
        activity.lastCounted = Date()

        addToCount = ""
    }
}
