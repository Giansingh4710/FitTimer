import SwiftUI

struct AddWorkoutModal: View {
    @Environment(\.dismiss) var dismiss
    let saveNewWorkout: (WorkoutPlan) -> Void
    
    @State private var workoutName: String = ""
    @State private var exerciseDuration: String = ""
    @State private var restDuration: String = ""
    @State private var exercises: [String] = []
    @State private var isBulkInput: Bool = false
    @State private var bulkExercises: String = ""

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
                    Toggle("Bulk Input Mode", isOn: $isBulkInput)

                    if isBulkInput {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter exercises (one per line)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextEditor(text: $bulkExercises)
                                .frame(minHeight: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            Text("Example:\nSquats\nPush-ups\nLunges")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button("Convert to Individual Exercises") {
                                convertBulkExercises()
                                isBulkInput = false
                            }
                            .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 8)
                    } else {
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
            }
            .navigationTitle("New Workout")
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
                    .disabled(workoutName.isEmpty || exerciseDuration.isEmpty || restDuration.isEmpty || exercises.isEmpty)
                }
            }
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    private func convertBulkExercises() {
        let newExercises = bulkExercises
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        exercises = newExercises
        bulkExercises = ""
    }

    private func saveWorkout() {
        guard let duration = Int(exerciseDuration), let rest = Int(restDuration) else { return }
        let newExercises = exercises.map { Exercise(name: $0, duration: duration, rest: rest) }
        let newWorkoutPlan = WorkoutPlan(name: workoutName, exercises: newExercises)
        saveNewWorkout(newWorkoutPlan)
    }
}
