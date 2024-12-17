import SwiftData
import SwiftUI

struct ListOfDailyActivities: View {
    @Binding var activityToShow: DailyActivity?
    @Binding var showAddActivityModal: Bool

    @Query private var dailyActivities: [DailyActivity]
    @State private var selectedActivity: DailyActivity? = nil
    @Environment(\.modelContext) var modelContext

    var body: some View {
        Section {
            ForEach(dailyActivities) { activity in
                ActivityRow(
                    activity: activity,
                    selectActivity: { activityToShow = activity },
                    deleteAction: { modelContext.delete(activity) }
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
        .onAppear {
            for activity in dailyActivities {
                activity.updateIfNewDay()
            }
        }
    }
}

struct ActivityRow: View {
    @State var activity: DailyActivity
    let selectActivity: () -> Void
    let deleteAction: () -> Void

    @State private var showInputAlert = false
    @State private var addToCount = ""

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(activity.name).font(.headline)
                Text("\(activity.notifications.count) reminders").font(.caption).foregroundColor(.secondary)
                Text("Reset Count: \(activity.resetDaily ? "Daily" : "Never")").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if let nextTime = activity.formatNextNotification() {
                VStack(alignment: .leading) {
                    Text("Next Reminder:").font(.caption)
                    Text("\(nextTime)").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()

            // button will run when whole row tapped. Not Warping here because has styling side effects
            Button(action: selectActivity) {
                Text("Count: \(activity.count)").font(.subheadline)
            }
        }
        .alert("How many \(activity.name)s did you do?", isPresented: $showInputAlert) {
            TextField("5", text: $addToCount).keyboardType(.numberPad)
            Button("OK", action: {
                activity.count += Int(addToCount) ?? 0
                activity.todayCount += Int(addToCount) ?? 0
                activity.lastCounted = Date()
                addToCount = ""
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
