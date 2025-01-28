import SwiftData
import SwiftUI

struct ImportObject: Identifiable {
    let id = UUID()
    let type: String // "workouts" | "activities"
    var items: [ImportItemType]
}

enum ImportItemType {
    case activity(Activity)
    case workoutPlan(WorkoutPlan)
}

struct ImportPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Binding var importObject: ImportObject

    @Query private var the_workouts: [WorkoutPlan]
    @Query private var the_activities: [Activity]

    @State private var currentIndex = 0
    @State private var showError = false
    @State private var errorMessage = ""

    @State private var currentItem: ImportItemType = .activity(Activity(name: ""))

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("\(currentIndex + 1)/\(importObject.items.count) \(importObject.type)")
                    .font(.headline)

                switch currentItem {
                case .activity:
                    ActivityDetailsViewForImport(item: $currentItem)
                case .workoutPlan:
                    WorkoutPlanDetailsViewForImport(item: $currentItem)
                }

                HStack(spacing: 20) {
                    Button("Skip") {
                        moveToNext()
                    }
                    .buttonStyle(.bordered)

                    Button("Import") {
                        switch currentItem {
                        case let .activity(act):
                            if idIsUnique(activity: act) {
                                act.history = act.history.sorted { $0.date < $1.date }
                                modelContext.insert(act)
                                moveToNext()
                            }
                        case let .workoutPlan(plan):
                            if idIsUnique(plan: plan) {
                                plan.completedHistory = plan.completedHistory.sorted { $0 < $1 }
                                modelContext.insert(plan)
                                moveToNext()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Import Preview")
            .toolbar {
                ToolbarItem {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            currentItem = importObject.items[currentIndex]
        }
    }

    private func idIsUnique(activity: Activity? = nil, plan: WorkoutPlan? = nil) -> Bool {
        if let the_activity = activity {
            if the_activities.contains(where: { $0.id == the_activity.id }) {
                errorMessage = "\(the_activity.name) Activity with id \(the_activity.id) already exists. Delete that Activity if you want to import this one"
                showError = true
                return false
            }
        }

        if let the_plan = plan {
            if the_workouts.contains(where: { $0.id == the_plan.id }) {
                errorMessage = "\(the_plan.name) Workout plan with id \(the_plan.id) already exists. Delete that Workout Plan if you want to import this one"
                showError = true
                return false
            }
        }

        return true
    }

    private func moveToNext() {
        if currentIndex < importObject.items.count - 1 {
            currentIndex += 1
            currentItem = importObject.items[currentIndex]
        } else {
            dismiss()
        }
    }
}

struct ActivityDetailsViewForImport: View {
    @Binding var item: ImportItemType
    private var activity: Binding<Activity> {
        Binding(
            get: {
                if case let .activity(act) = item {
                    return act
                }
                fatalError("Expected an activity type")
            },
            set: { newValue in
                item = .activity(newValue)
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Basic Info Section
                GroupBox("Basic Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Activity Name", text: activity.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        DatePicker("Created",
                                   selection: activity.createdAt,
                                   in: ...Date.now)
                            .datePickerStyle(.compact)
                    }
                }

                // Counts & Settings Section
                GroupBox("Settings") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Total Count")
                            Spacer()
                            Text("\(activity.wrappedValue.count)")
                                .foregroundColor(.secondary)
                        }
                        Toggle("Reset Daily", isOn: activity.resetDaily)
                    }
                }

                // Notifications Section
                GroupBox("Notifications") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Title", text: activity.notificationText.title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Body", text: activity.notificationText.body)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("Notification Times")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(activity.wrappedValue.notifications.indices, id: \.self) { index in
                            HStack {
                                Text("• ")
                                let components = activity.wrappedValue.notifications[index]
                                Text(String(format: "%02d:%02d",
                                            components.hour ?? 0,
                                            components.minute ?? 0))
                            }
                        }
                    }
                }

                // History Section
                GroupBox("Activity History") {
                    if activity.wrappedValue.history.isEmpty {
                        Text("No history available")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(activity.wrappedValue.history, id: \.self) { historyItem in
                            HStack {
                                Text(historyItem.date.formatted(date: .abbreviated, time: .shortened))
                                Spacer()
                                Text("\(historyItem.count) counts")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct WorkoutPlanDetailsViewForImport: View {
    @Binding var item: ImportItemType
    private var plan: Binding<WorkoutPlan> {
        Binding(
            get: {
                if case let .workoutPlan(plann) = item {
                    return plann
                }
                fatalError("Expected a workout plan type")
            },
            set: { newValue in
                item = .workoutPlan(newValue)
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Basic Info Section
                GroupBox("Basic Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Workout Plan Name", text: plan.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        DatePicker("Created",
                                   selection: plan.createdAt,
                                   in: ...Date.now)
                            .datePickerStyle(.compact)
                    }
                }

                // Exercises Section
                GroupBox("Exercises") {
                    if plan.wrappedValue.exercises.isEmpty {
                        Text("No exercises added")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(plan.wrappedValue.exercises.indices, id: \.self) { index in
                            let exercise = plan.wrappedValue.exercises[index]
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                Text("\(exercise.duration) duration × \(exercise.rest) rest")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Notifications Section
                GroupBox("Notifications") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Title", text: plan.notificationText.title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Body", text: plan.notificationText.body)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("Notification Times")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(plan.wrappedValue.notifications.indices, id: \.self) { index in
                            HStack {
                                Text("• ")
                                let components = plan.wrappedValue.notifications[index]
                                Text(formatTime(components))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // Completion History Section
                GroupBox("Completion History") {
                    if plan.wrappedValue.completedHistory.isEmpty {
                        Text("No completion history available")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(plan.wrappedValue.completedHistory.sorted(by: <), id: \.self) { date in
                            HStack {
                                Text("✓")
                                    .foregroundColor(.green)
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func formatTime(_ components: DateComponents) -> String {
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}
