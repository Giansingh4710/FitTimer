//
//  FitTimerApp.swift
//  FitTimer
//
//  Created by gian singh on 11/17/24.
//

import SwiftData
import SwiftUI

@main
struct FitTimerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Exercise.self,
            WorkoutPlan.self,
            DailyActivity.self,
        ])
    }
}
