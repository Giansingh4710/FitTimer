//
//  ContentView.swift
//  FitTimer
//
//  Created by gian singh on 11/17/24.
//

import SwiftUI

struct ContentView: View {
    // @State private var isShowingCalendarView = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    WorkoutSection()
                    DailyActivitySection()
                }
                Spacer()
                Button(action: {
                    // isShowingCalendarView = true
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

#Preview {
    ContentView()
}
