import Foundation
import SwiftUI

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    @Published var dayLogs: [DayLog] = []
    
    private init() {
        loadHistory()
    }
    
    func logWorkoutCompletion(_ workout: WorkoutPlan) {
        let completedWorkout = CompletedWorkout(
            id: UUID(),
            workoutName: workout.name,
            exercises: workout.exercises,
            completedAt: Date()
        )
        
        let today = Calendar.current.startOfDay(for: Date())
        
        if let index = dayLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            dayLogs[index].completedWorkouts.append(completedWorkout)
        } else {
            let newLog = DayLog(
                id: UUID(),
                date: today,
                completedWorkouts: [completedWorkout],
                activityCounts: []
            )
            dayLogs.append(newLog)
        }
        
        saveHistory()
    }
    
    func logActivityCounts(_ activities: [DailyActivity]) {
        let activityCounts = activities.map { activity in
            ActivityCount(
                id: UUID(),
                activityName: activity.name,
                count: activity.count
            )
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        if let index = dayLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            dayLogs[index].activityCounts = activityCounts
        } else {
            let newLog = DayLog(
                id: UUID(),
                date: today,
                completedWorkouts: [],
                activityCounts: activityCounts
            )
            dayLogs.append(newLog)
        }
        
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(dayLogs) {
            UserDefaults.standard.set(encoded, forKey: "dayLogs")
        }
    }
    
    private func loadHistory() {
        if let savedData = UserDefaults.standard.data(forKey: "dayLogs"),
           let decoded = try? JSONDecoder().decode([DayLog].self, from: savedData) {
            dayLogs = decoded
        }
    }
} 