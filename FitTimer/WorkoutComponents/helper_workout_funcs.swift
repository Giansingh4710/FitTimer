import SwiftUI

func getTotalWorkoutTime(_ plan: WorkoutPlan) -> Int {
    plan.exercises.reduce(0) { $0 + $1.duration + $1.rest }
}

func getTotalWorkTime(_ plan: WorkoutPlan) -> Int {
    plan.exercises.reduce(0) { $0 + $1.duration }
}

func getTotalRestTime(_ plan: WorkoutPlan) -> Int {
    plan.exercises.reduce(0) { $0 + $1.rest }
}

func formatDuration(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return "\(minutes)m \(remainingSeconds)s"
}

func deepCopy<T: Codable>(_ object: T) -> T? {
    guard let data = try? JSONEncoder().encode(object),
          let copy = try? JSONDecoder().decode(T.self, from: data)
    else { return nil }
    return copy
}
