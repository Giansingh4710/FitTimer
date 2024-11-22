//
//  ContentView.swift
//  FitTimer
//
//  Created by gian singh on 11/17/24.
//

import SwiftUI
import UserNotifications

struct Exercise: Identifiable, Codable {
    let id = UUID()
    var name: String
    var duration: Int // in seconds
    var rest: Int // in seconds
}

struct WorkoutPlan: Identifiable, Codable {
    let id = UUID()
    var name: String
    var exercises: [Exercise]
}

struct DailyActivity: Identifiable, Codable {
    let id = UUID()
    var name: String
    var count: Int
    var notifications: [DateComponents] // Times for notifications
}

struct ActivityLog: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var activities: [DailyActivity]
}

struct ContentView: View {
    @State private var workoutPlans: [WorkoutPlan] = []
    @State private var dailyActivities: [DailyActivity] = []
    @State private var activityLogs: [ActivityLog] = []
    @State private var isShowingAddWorkoutModal = false
    @State private var isShowingAddActivityModal = false
    @State private var selectedWorkout: WorkoutPlan?
    @State private var selectedActivity: DailyActivity?
    @State private var isShowingActivityDetailModal = false
    @State private var isShowingCalendarView = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Workout Plans").font(.title2).bold()) {
                        ForEach(workoutPlans) { plan in
                            NavigationLink(destination: WorkoutDetailView(plan: plan, onSave: updateWorkout)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(plan.exercises.count) exercises")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .contextMenu {
                                Button("Edit") {
                                    selectedWorkout = plan
                                    isShowingAddWorkoutModal = true
                                }
                                Button("Delete", role: .destructive) {
                                    if let index = workoutPlans.firstIndex(where: { $0.id == plan.id }) {
                                        workoutPlans.remove(at: index)
                                        saveWorkouts()
                                    }
                                }
                            }
                        }
                        Button(action: {
                            selectedWorkout = nil
                            isShowingAddWorkoutModal = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Workout Plan")
                            }
                            .foregroundColor(.accentColor)
                        }
                    }

                    Section(header: Text("Daily Activities").font(.title2).bold()) {
                        ForEach(dailyActivities) { activity in
                            Button(action: {
                                selectedActivity = activity
                                isShowingActivityDetailModal = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activity.name)
                                            .font(.headline)
                                        Text("\(activity.notifications.count) notifications")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if let nextNotification = getNextNotification(for: activity) {
                                            Text("Next: \(formatTime(nextNotification))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Count: \(activity.count)")
                                            .font(.subheadline)
                                        HStack {
                                            Button(action: {
                                                incrementCount(for: activity)
                                            }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundColor(.accentColor)
                                            }
                                            Button(action: {
                                                decrementCount(for: activity)
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .onDelete(perform: deleteActivity)
                        Button(action: {
                            isShowingAddActivityModal = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Daily Activity")
                            }
                            .foregroundColor(.accentColor)
                        }
                    }
                }
                Spacer()
                Button(action: {
                    isShowingCalendarView = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("View Calendar Jio")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("FitTimer")
            .sheet(isPresented: $isShowingAddWorkoutModal) {
                AddWorkoutModal(
                    workoutPlans: $workoutPlans,
                    selectedWorkout: $selectedWorkout
                )
            }
            .sheet(isPresented: $isShowingAddActivityModal) {
                AddActivityModal(
                    dailyActivities: $dailyActivities
                )
            }
            .sheet(isPresented: $isShowingActivityDetailModal) {
                if let activity = selectedActivity {
                    ActivityDetailView(
                        activity: binding(for: activity),
                        onSave: { updatedActivity in
                            if let index = dailyActivities.firstIndex(where: { $0.id == updatedActivity.id }) {
                                dailyActivities[index] = updatedActivity
                                saveActivities()
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $isShowingCalendarView) {
                CalendarDetailView(activityLogs: $activityLogs)
            }
            .onAppear {
                loadWorkouts()
                loadActivities()
                loadActivityLogs()
                requestNotificationPermission()
            }
        }
    }

    private func updateWorkout(_ updatedPlan: WorkoutPlan) {
        if let index = workoutPlans.firstIndex(where: { $0.id == updatedPlan.id }) {
            workoutPlans[index] = updatedPlan
            saveWorkouts()
        }
    }

    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workoutPlans) {
            UserDefaults.standard.set(encoded, forKey: "workoutPlans")
        }
    }

    private func loadWorkouts() {
        if let savedData = UserDefaults.standard.data(forKey: "workoutPlans"),
           let decoded = try? JSONDecoder().decode([WorkoutPlan].self, from: savedData)
        {
            workoutPlans = decoded
        }
    }

    private func deleteActivity(at offsets: IndexSet) {
        dailyActivities.remove(atOffsets: offsets)
        saveActivities()
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

    private func loadActivityLogs() {
        if let savedData = UserDefaults.standard.data(forKey: "activityLogs"),
           let decoded = try? JSONDecoder().decode([ActivityLog].self, from: savedData)
        {
            activityLogs = decoded
        }
    }

    private func saveActivityLogs() {
        if let encoded = try? JSONEncoder().encode(activityLogs) {
            UserDefaults.standard.set(encoded, forKey: "activityLogs")
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func binding(for activity: DailyActivity) -> Binding<DailyActivity> {
        Binding(
            get: { activity },
            set: { newValue in
                if let index = dailyActivities.firstIndex(where: { $0.id == activity.id }) {
                    dailyActivities[index] = newValue
                    saveActivities()
                }
            }
        )
    }

    private func incrementCount(for activity: DailyActivity) {
        if let index = dailyActivities.firstIndex(where: { $0.id == activity.id }) {
            dailyActivities[index].count += 1
            logActivity(activity)
            saveActivities()
        }
    }

    private func decrementCount(for activity: DailyActivity) {
        if let index = dailyActivities.firstIndex(where: { $0.id == activity.id }), dailyActivities[index].count > 0 {
            dailyActivities[index].count -= 1
            saveActivities()
        }
    }

    private func logActivity(_ activity: DailyActivity) {
        let today = Calendar.current.startOfDay(for: Date())
        if let index = activityLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            activityLogs[index].activities.append(activity)
        } else {
            activityLogs.append(ActivityLog(date: today, activities: [activity]))
        }
        saveActivityLogs()
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

struct CalendarView: View {
    @Binding var activityLogs: [ActivityLog]
    @Binding var selectedDate: Date?

    var body: some View {
        VStack {
            Text("Activity Calendar")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(activityLogs) { log in
                    Button(action: {
                        selectedDate = log.date
                    }) {
                        Text("\(Calendar.current.component(.day, from: log.date))")
                            .frame(width: 30, height: 30)
                            .background(selectedDate == log.date ? Color.blue : Color.clear)
                            .foregroundColor(selectedDate == log.date ? .white : .primary)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

struct ActivityLogView: View {
    var date: Date
    var activityLogs: [ActivityLog]

    var body: some View {
        if let log = activityLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            List {
                ForEach(log.activities) { activity in
                    VStack(alignment: .leading) {
                        Text(activity.name)
                            .font(.headline)
                        Text("Count: \(activity.count)")
                            .font(.subheadline)
                    }
                }
            }
        } else {
            Text("No activities logged for this day.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
