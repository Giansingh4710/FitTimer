//
//  ContentView.swift
//  FitTimer
//
//  Created by gian singh on 11/17/24.
//

import SwiftData
import SwiftUI
import UserNotifications

struct ContentView: View {
    @EnvironmentObject private var lnManager: LocalNotificationManager
    @Environment(\.scenePhase) private var scenePhase

    @Query private var the_workouts: [WorkoutPlan]
    @Query private var the_activities: [Activity]

    @State private var showAddActivityModal = false

    @State private var isShowingAddWorkoutModal = false
    @State private var isShowingNotificationCenter = false
    @State private var isShowingCalender = false

    @Environment(\.modelContext) var modelContext
    var body: some View {
        NavigationView {
            List {
                ListOfWorkouts(isShowingAddWorkoutModal: $isShowingAddWorkoutModal)
                ListOfActivities(showAddActivityModal: $showAddActivityModal)
                Button(action: { isShowingNotificationCenter = true }) {
                    HStack {
                        Image(systemName: "bell.badge")
                        Text("Notifications: \(lnManager.pendingRequests.count)")
                    }
                }
                Button(action: { isShowingCalender = true }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Open Calendar")
                    }
                }
            }
            .navigationTitle("Fit Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .task {
            try? await lnManager.requestAuthorization()
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .active {
                Task {
                    await lnManager.getCurrentSettings()
                    await lnManager.getPendingRequests()
                }
            }
        }
        .sheet(item: $lnManager.nextView) { nextView in
            // nextView.view()

            switch nextView.type {
            case .workout_plans:
                if let plan = the_workouts.first(where: { $0.id.uuidString == nextView.id }) {
                    WorkoutDetailView(plan: plan)
                }
            case .activities:
                if let act = the_activities.first(where: { $0.id.uuidString == nextView.id }) {
                    ActivityDetailView(activity: act)
                }
            }
        }
        .sheet(isPresented: $isShowingCalender) {
            CalendarView()
        }
        .sheet(isPresented: $isShowingNotificationCenter) {
            NavigationView {
                UpcomingNotificationsView()
            }
        }
        // activity modals
        .sheet(isPresented: $showAddActivityModal) {
            AddActivityModal()
        }

        // workout modals
        .sheet(isPresented: $isShowingAddWorkoutModal) {
            AddWorkoutModal()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            if success {
                print("Notification permission granted")
            } else if let error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
    // .preferredColorScheme(.light)
}
