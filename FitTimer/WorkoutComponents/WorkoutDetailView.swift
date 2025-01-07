import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State var plan: WorkoutPlan
    @State private var showingWorkout = false

    var body: some View {
        VStack(spacing: 0) {
            Text(plan.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            HStack(spacing: 8) {
                Text("\(plan.exercises.count) exercises")
                Text("•")
                Text(formatDuration(getTotalWorkoutTime(plan)))
            }
            HStack(spacing: 8) {
                Text("\(plan.completedHistory.count) workouts completed")
                Text("•")
                Text("\(plan.notifications.count) daily reminders")
            }
            .font(.system(.caption, design: .rounded))
            .foregroundColor(.secondary)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(plan.exercises) { exercise in
                        ExerciseRow(exercise: exercise)
                    }
                }
                .padding(.horizontal)
            }

            VStack(spacing: 12) {
                NavigationLink(destination: WorkoutEditorView(plan: plan)) {
                    Label("Edit", systemImage: "pencil.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                Button(action: { showingWorkout = true }) {
                    Label("Start Workout", systemImage: "play.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingWorkout) {
            WorkoutInProgressView(
                plan: plan,
                onComplete: {
                    showingWorkout = false
                    plan.completedHistory.append(Date())
                },
                onCancel: { showingWorkout = false }
            )
        }
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            HStack {
                Label("\(exercise.duration)s", systemImage: "timer")
                Spacer()
                Label("\(exercise.rest)s rest", systemImage: "pause.circle")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

struct WorkoutEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var plan: WorkoutPlan

    @State private var draftName: String = ""
    @State private var draftExerciseDuration: String = ""
    @State private var draftRestDuration: String = ""
    @State private var draftExercises: [Exercise] = []

    @State private var numberOfRandomTimes: String = ""
    @State private var notificationTimes: [DateComponents] = []
    @State private var notificationText: NotificationTextData = .init(title: "", body: "")

    @EnvironmentObject private var lnManager: LocalNotificationManager
    var body: some View {
        Form {
            AddNotificationView(
                numberOfRandomTimes: $numberOfRandomTimes,
                notificationTimes: $notificationTimes,
                notificationText: $notificationText
            )
            WorkoutNameAndTimeInputs(workoutName: $draftName, exerciseDuration: $draftExerciseDuration, restDuration: $draftRestDuration)

            Section(header: Text("Exercises")) {
                ForEach($draftExercises) { $exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Exercise Name", text: $exercise.name).font(.headline)

                        HStack(spacing: 16) {
                            HStack {
                                Text("Duration:")
                                TextField("seconds", value: $exercise.duration, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                            }

                            HStack {
                                Text("Rest:")
                                TextField("seconds", value: $exercise.rest, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onDelete(perform: deleteExercise)

                Button(action: addExercise) {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draftName = plan.name
            draftExerciseDuration = String(plan.exercises.first?.duration ?? 0)
            draftRestDuration = String(plan.exercises.first?.rest ?? 0)
            draftExercises = plan.exercises.map { $0.copy() }
            notificationTimes = plan.notifications

            (notificationText.title, notificationText.body) = (plan.notificationText.title, plan.notificationText.body)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    plan.name = draftName
                    plan.exercises = draftExercises
                    plan.notifications = notificationTimes
                    (plan.notificationText.title, plan.notificationText.body) = (notificationText.title, notificationText.body)

                    Task {
                        await lnManager.scheduleNotifications(for: plan)
                    }
                    dismiss()
                }
            }
        }
        .onChange(of: draftExerciseDuration) { newValue in
            let value = Int(newValue) ?? 0
            for exercise in draftExercises {
                exercise.duration = value
            }
        }
        .onChange(of: draftRestDuration) { newValue in
            let value = Int(newValue) ?? 0
            for exercise in draftExercises {
                exercise.rest = value
            }
        }
    }

    private func addExercise() {
        let duration = draftExercises.last?.duration ?? 0
        let rest = draftExercises.last?.rest ?? 0
        let newExercise = Exercise(name: "", duration: duration, rest: rest)
        draftExercises.append(newExercise)
    }

    private func deleteExercise(at offsets: IndexSet) {
        draftExercises.remove(atOffsets: offsets)
    }
}
