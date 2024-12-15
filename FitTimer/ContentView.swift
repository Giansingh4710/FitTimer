//
//  ContentView.swift
//  FitTimer
//
//  Created by gian singh on 11/17/24.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var dailyActivities: [DailyActivity] = []
    @State private var activityToShow: DailyActivity? = nil
    @State private var showAddActivityModal = false

    @State private var workoutPlans: [WorkoutPlan] = []
    @State private var isShowingAddWorkoutModal = false

    @State private var showingNotificationCenter = false
    @State private var showingHistory = false

    // @State private var isShowingCalendarView = false

    var body: some View {
        NavigationView {
            List {
                ListOfWorkouts(
                    workoutPlans: $workoutPlans,
                    isShowingAddWorkoutModal: $isShowingAddWorkoutModal
                )
                ListOfDailyActivities(
                    dailyActivities: $dailyActivities,
                    activityToShow: $activityToShow,
                    showAddActivityModal: $showAddActivityModal
                )

                Button(action: { showingHistory = true }) {
                    Label("View History", systemImage: "calendar")
                }
            }
            .navigationTitle("Fit Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNotificationCenter = true }) {
                        Image(systemName: "bell.badge")
                    }
                }
            }
            .sheet(isPresented: $showingNotificationCenter) {
                NavigationView {
                    NotificationCenterView()
                }
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
        }
        .onAppear {
            loadActivities(&dailyActivities)
            loadWorkouts(&workoutPlans)
            requestNotificationPermission()
        }
        // activity modals
        .sheet(isPresented: $showAddActivityModal) {
            AddActivityModal(dailyActivities: $dailyActivities)
        }
        .sheet(item: $activityToShow) { activity in
            ActivityDetailModal(activity: activity, dailyActivities: $dailyActivities)
        }

        // workout modals
        .sheet(isPresented: $isShowingAddWorkoutModal) {
            AddWorkoutModal(saveNewWorkout: { (newWorkoutPlan: WorkoutPlan) in
                pushWorkout(newWorkoutPlan, &workoutPlans)
            })
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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
    // .preferredColorScheme(.light)
}
