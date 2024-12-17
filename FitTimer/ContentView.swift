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
    @State private var activityToShow: DailyActivity? = nil
    @State private var showAddActivityModal = false

    @State private var isShowingAddWorkoutModal = false

    @State private var showingNotificationCenter = false
    @State private var showingHistory = false

    // @State private var isShowingCalendarView = false

    @Environment(\.modelContext) var modelContext
    var body: some View {
        NavigationView {
            List {
                ListOfWorkouts(
                    isShowingAddWorkoutModal: $isShowingAddWorkoutModal
                )
                ListOfDailyActivities(
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
        }
        .onAppear {
            requestNotificationPermission()
        }
        .sheet(isPresented: $showingNotificationCenter) {
            NavigationView {
                NotificationCenterView()
            }
        }
        .sheet(isPresented: $showingHistory) {
            // HistoryView()
        }
        // activity modals
        .sheet(isPresented: $showAddActivityModal) {
            AddActivityModal()
        }
        .sheet(item: $activityToShow) { activity in
            ActivityDetailModal(activity: activity)
        }

        // workout modals
        .sheet(isPresented: $isShowingAddWorkoutModal) {
            AddWorkoutModal()
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

#Preview {
    ContentView()
    // .preferredColorScheme(.light)
}
