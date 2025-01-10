import SwiftUI

struct AddWorkoutModal: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var workoutName: String = ""
    @State private var exerciseDuration: String = ""
    @State private var restDuration: String = ""
    @State private var exercises: [String] = []
    @State private var isBulkInput: Bool = false
    @State private var bulkExercises: String = ""

    @State private var numberOfRandomTimes: String = ""
    @State private var notificationTimes: [DateComponents] = []
    @State var notificationText: NotificationTextData = .init(title: "", body: "")
    @EnvironmentObject private var lnManager: LocalNotificationManager
    @State private var showingNotificationPermissionAlert = false

    var body: some View {
        NavigationView {
            Form {
                WorkoutNameAndTimeInputs(workoutName: $workoutName, exerciseDuration: $exerciseDuration, restDuration: $restDuration)
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
                AddNotificationView(
                    numberOfRandomTimes: $numberOfRandomTimes,
                    notificationTimes: $notificationTimes,
                    notificationText: $notificationText
                )
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
                        Task {
                            await saveActivity()
                        }
                    }.disabled(workoutName.isEmpty || exerciseDuration.isEmpty || restDuration.isEmpty || exercises.isEmpty)
                }
            }
        }
    }

    private func saveActivity() async {
        let exercisesObj = exercises.map {
            Exercise(
                name: $0,
                duration: Int(exerciseDuration) ?? 0,
                rest: Int(restDuration) ?? 0
            )
        }

        let newWorkout = WorkoutPlan(name: workoutName, notifications: notificationTimes, exercises: exercisesObj, notificationText: notificationText)
        modelContext.insert(newWorkout)
        await lnManager.scheduleNotifications(for: newWorkout)
        dismiss()
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
}

struct WorkoutNameAndTimeInputs: View {
    @Binding var workoutName: String
    @Binding var exerciseDuration: String
    @Binding var restDuration: String

    var body: some View {
        Section(header: Text("Workout Details")) {
            TextField("Workout Name", text: $workoutName)
            TextField("Exercise Duration (seconds)", text: $exerciseDuration)
                .keyboardType(.numberPad)
            TextField("Rest Duration (seconds)", text: $restDuration)
                .keyboardType(.numberPad)
        }
    }
}
