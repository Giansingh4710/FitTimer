import SwiftUI

struct DailyActivitySection: View {
    @State private var isShowingAddActivityModal = false
    @State private var dailyActivities: [DailyActivity] = []
    @State private var selectedActivity: DailyActivity?
    @State private var isShowingActivityDetailModal = false

    var body: some View {
        Section(header: Text("Daily Activities").font(.title2).bold()) {
            ForEach(Array(dailyActivities.enumerated()), id: \.offset) { index, activity in
                ActivityRow(
                    activity: activity,
                    incrementAction: {
                        dailyActivities[index].count += 1
                    },
                    decrementAction: {
                        if dailyActivities[index].count > 0 {
                            dailyActivities[index].count -= 1
                        }
                    }
                )
                .padding(.vertical, 8)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        dailyActivities.remove(at: index)
                        saveActivities()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        selectedActivity = activity
                        isShowingActivityDetailModal = true
                    } label: {
                        Label("Edit", systemImage: "edit")
                    }
                }
            }

            Button(action: {
                isShowingAddActivityModal = true
            }) {
                Label("Add Daily Activity", systemImage: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .sheet(isPresented: $isShowingAddActivityModal) {
            AddActivityModal(
                dailyActivities: $dailyActivities,
                saveActivities: saveActivities
            )
        }
        .sheet(isPresented: $isShowingActivityDetailModal) {
            if let activityIndex = dailyActivities.firstIndex(where: { $0.id == selectedActivity?.id }) {
                ActivityDetailView(
                    activity: $dailyActivities[activityIndex],
                    onSave: { updatedActivity in
                        if let index = dailyActivities.firstIndex(where: { $0.id == updatedActivity.id }) {
                            dailyActivities[index] = updatedActivity
                            saveActivities()
                        }
                    }
                )
            }
        }
        .onAppear {
            loadActivities()
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

    private func saveActivities() {
        if let encoded = try? JSONEncoder().encode(dailyActivities) {
            UserDefaults.standard.set(encoded, forKey: "dailyActivities")
        }
    }

    private func loadActivities() {
        if let savedData = UserDefaults.standard.data(forKey: "dailyActivities"),
           let decoded = try? JSONDecoder().decode([DailyActivity].self, from: savedData)
        {
            dailyActivities = decoded
        }
    }
}

// Helper view for consistent activity row presentation
struct ActivityRow: View {
    let activity: DailyActivity
    let incrementAction: () -> Void
    let decrementAction: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                Text("\(activity.notifications.count) notifications")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let nextTime = activity.formatNextNotification() {
                    Text("Next: \(nextTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: decrementAction) {
                Image(systemName: "minus.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
            }
            Text("Count: \(activity.count)").font(.subheadline)
            Button(action: incrementAction) {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
            }
        }
        // Disable the row's button behavior
        // .allowsHitTesting(false)
        .contentShape(Rectangle())
    }
}
