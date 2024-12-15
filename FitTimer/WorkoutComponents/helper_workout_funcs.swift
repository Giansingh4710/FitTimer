import SwiftUI

func pushWorkout(_ newWorkoutPlan: WorkoutPlan, _ workoutPlans: inout [WorkoutPlan]) {
    workoutPlans.append(newWorkoutPlan)
    saveWorkouts(workoutPlans)
}

func updateWorkout(_ updatedPlan: WorkoutPlan, _ workoutPlans: inout [WorkoutPlan]) {
    if let index = workoutPlans.firstIndex(where: { $0.id == updatedPlan.id }) {
        workoutPlans[index] = updatedPlan
        saveWorkouts(workoutPlans)
    }
}

func saveWorkouts(_ workoutPlans: [WorkoutPlan]) {
    if let encoded = try? JSONEncoder().encode(workoutPlans) {
        UserDefaults.standard.set(encoded, forKey: "workoutPlans")
    }
}

func loadWorkouts(_ workoutPlans: inout [WorkoutPlan]) {
    if let savedData = UserDefaults.standard.data(forKey: "workoutPlans"),
       let decoded = try? JSONDecoder().decode([WorkoutPlan].self, from: savedData)
    {
        workoutPlans = decoded
    }
}
