import SwiftUI

struct AddWorkoutModal: View {
    @Environment(\.dismiss) var dismiss
    @Binding var workoutPlans: [WorkoutPlan]
    @Binding var selectedWorkout: WorkoutPlan?
    @State private var workoutName: String = ""
    @State private var exerciseDuration: String = ""
    @State private var restDuration: String = ""
    @State private var exercises: [String] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Details")) {
                    TextField("Workout Name", text: $workoutName)
                    TextField("Exercise Duration (seconds)", text: $exerciseDuration)
                        .keyboardType(.numberPad)
                    TextField("Rest Duration (seconds)", text: $restDuration)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Exercises")) {
                    ForEach(exercises.indices, id: \.self) { index in
                        TextField("Exercise Name", text: $exercises[index])
                    }
                    .onDelete(perform: deleteExercise)

                    Button(action: {
                        exercises.append("")
                    }) {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .navigationTitle(selectedWorkout == nil ? "New Workout" : "Edit Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let workout = selectedWorkout {
                    workoutName = workout.name
                    exercises = workout.exercises.map { $0.name }
                    if let firstExercise = workout.exercises.first {
                        exerciseDuration = String(firstExercise.duration)
                        restDuration = String(firstExercise.rest)
                    }
                }
            }
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    private func saveWorkout() {
        guard let duration = Int(exerciseDuration), let rest = Int(restDuration) else { return }
        let newExercises = exercises.map { Exercise(name: $0, duration: duration, rest: rest) }
        let newWorkoutPlan = WorkoutPlan(name: workoutName, exercises: newExercises)
        
        if let index = workoutPlans.firstIndex(where: { $0.id == selectedWorkout?.id }) {
            workoutPlans[index] = newWorkoutPlan
        } else {
            workoutPlans.append(newWorkoutPlan)
        }
    }
} 