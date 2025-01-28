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
                Text("Longest 🔥: \(plan.getLongestStreak())")
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
    @State private var draftHistory: [Date] = []

    @State private var notificationTimes: [DateComponents] = []
    @State private var notificationText: NotificationTextData = .init(title: "", body: "")
    @State private var notificationsOff: Bool = false

    @EnvironmentObject private var lnManager: LocalNotificationManager
    var body: some View {
        Form {
            AddNotificationView(
                notificationTimes: $notificationTimes,
                notificationText: $notificationText,
                notificationsOff: $notificationsOff
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
                .onMove(perform: moveExercise)

                Button(action: addExercise) {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }

            Section {
                if draftHistory.count > 0 {
                    DisclosureGroup("Workout History: \(draftHistory.count)") {
                        ForEach(draftHistory, id: \.self) { entry in
                            HStack {
                                Text(entry, style: .date)
                                // Spacer()
                                // Text("Count: \(entry.count)") .bold()
                            }
                            .font(.subheadline)
                        }
                        .onDelete(perform: deleteHistory)
                    }
                }
            }
        }
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draftName = plan.name
            draftExerciseDuration = String(plan.exercises.first?.duration ?? 0)
            draftRestDuration = String(plan.exercises.first?.rest ?? 0)
            draftExercises = plan.exercises.map { $0 }
            draftHistory = plan.completedHistory.map { $0 }
            notificationTimes = plan.notifications
            notificationText.title = plan.notificationText.title
            notificationText.body = plan.notificationText.body
            notificationsOff = plan.notificationsOff
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    plan.name = draftName
                    plan.exercises = draftExercises
                    plan.completedHistory = draftHistory
                    plan.notifications = notificationTimes
                    (plan.notificationText.title, plan.notificationText.body) = (notificationText.title, notificationText.body)
                    plan.notificationsOff = notificationsOff

                    Task {
                        await lnManager.scheduleNotifications(for: plan)
                    }
                    dismiss()
                }
            }
        }
        .onChange(of: draftExerciseDuration) { newValue in
            let value = Int(newValue) ?? 0
            for index in draftExercises.indices {
                draftExercises[index].duration = value
            }
        }
        .onChange(of: draftRestDuration) { newValue in
            let value = Int(newValue) ?? 0
            for index in draftExercises.indices {
                draftExercises[index].rest = value
            }
        }
    }

    private func deleteHistory(at offsets: IndexSet) {
        draftHistory.remove(atOffsets: offsets)
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

    private func moveExercise(from source: IndexSet, to destination: Int) {
        draftExercises.move(fromOffsets: source, toOffset: destination)
    }
}
