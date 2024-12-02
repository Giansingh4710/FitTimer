//
//  ContentView.swift
//  FitTimer
//
//  Created by gian singh on 11/17/24.
//

import SwiftUI

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

struct ContentView: View {
    @State private var isShowingCalendarView = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    WorkoutSection()
                    DailyActivitySection()
                }
                Spacer()
                Button(action: {
                    isShowingCalendarView = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("View Calendar")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Fit Timer")
            .onAppear { requestNotificationPermission() }
            // .sheet(isPresented: $isShowingCalendarView) { CalendarDetailView(activityLogs: $activityLogs) }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

struct WorkoutSection: View {
    @State private var workoutPlans: [WorkoutPlan] = []
    @State private var isShowingAddWorkoutModal = false
    @State private var selectedWorkout: WorkoutPlan?
    var body: some View {
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
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        if let index = workoutPlans.firstIndex(where: { $0.id == plan.id }) {
                            workoutPlans.remove(at: index)
                            saveWorkouts()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        selectedWorkout = plan
                        isShowingAddWorkoutModal = true
                    } label: {
                        Label("Edit", systemImage: "edit")
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
                }.foregroundColor(.accentColor)
            }
        }
        .sheet(isPresented: $isShowingAddWorkoutModal) {
            AddWorkoutModal(workoutPlans: $workoutPlans, selectedWorkout: $selectedWorkout)
        }
        .onAppear { loadWorkouts() }
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
}

#Preview {
    ContentView()
}
