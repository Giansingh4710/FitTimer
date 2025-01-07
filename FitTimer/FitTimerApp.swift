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
    @StateObject var lnManager = LocalNotificationManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                // .environmentObject(lnManager)
        }
        .environmentObject(lnManager)
        .modelContainer(for: [
            WorkoutPlan.self,
            Activity.self,
        ])
    }

    // init() {
    //     UNUserNotificationCenter.current().delegate = lnManager
    // }
}
