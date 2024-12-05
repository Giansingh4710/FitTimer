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

    // @State private var isShowingCalendarView = false

    var body: some View {
        NavigationView {
            List {
                ListOfWorkouts()
                ListOfDailyActivities(
                    dailyActivities: $dailyActivities,
                    activityToShow: $activityToShow, showAddActivityModal:
                    $showAddActivityModal
                )

                // Button(action: {
                //     isShowingCalendarView = true
                // }) {
                //     HStack {
                //         Image(systemName: "calendar")
                //         Text("View Calendar")
                //     }
                //     .font(.headline)
                //     .padding()
                //     .background(Color.accentColor)
                //     .foregroundColor(.white)
                //     .cornerRadius(10)
                // }
                // .padding()
            }
            .navigationTitle("Fit Timer")
            // .sheet(isPresented: $isShowingCalendarView) { CalendarDetailView(activityLogs: $activityLogs) }
        }
        .onAppear {
            loadActivities(&dailyActivities)
            requestNotificationPermission()
        }
        .sheet(isPresented: $showAddActivityModal) {
            AddActivityModal(dailyActivities: $dailyActivities)
        }
        .sheet(item: $activityToShow) { activity in
            ActivityDetailModal(activity: activity, dailyActivities: $dailyActivities)
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
