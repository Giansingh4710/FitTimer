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

    @State private var activityToShow: Activity? = nil
    @State private var showAddActivityModal = false

    @State private var isShowingAddWorkoutModal = false

    @State private var showingNotificationCenter = false

    @Environment(\.modelContext) var modelContext
    var body: some View {
        NavigationView {
            List {
                ListOfWorkouts(isShowingAddWorkoutModal: $isShowingAddWorkoutModal)
                ListOfActivities(activityToShow: $activityToShow, showAddActivityModal: $showAddActivityModal)
                Button(action: { showingNotificationCenter = true }) {
                    HStack {
                        Image(systemName: "bell.badge")
                        Text("Notifications: \(lnManager.pendingRequests.count)")
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
        .onAppear {
            // requestNotificationPermission()
        }
        .sheet(isPresented: $showingNotificationCenter) {
            NavigationView {
                UpcomingNotificationsView()
            }
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
