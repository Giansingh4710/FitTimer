import Foundation

struct DayLog: Identifiable, Codable {
    let id: UUID
    let date: Date
    var completedWorkouts: [CompletedWorkout]
    var activityCounts: [ActivityCount]
}

struct CompletedWorkout: Identifiable, Codable {
    let id: UUID
    let workoutName: String
    let exercises: [Exercise]
    let completedAt: Date
}

struct ActivityCount: Identifiable, Codable {
    let id: UUID
    let activityName: String
    let count: Int
} 
