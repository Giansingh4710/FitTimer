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
                onComplete: { showingWorkout = false },
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
    @State private var draftExercises: [Exercise] = []

    var body: some View {
        Form {
            Section(header: Text("Workout Details")) {
                TextField("Workout Name", text: $draftName)
                    .font(.headline)
            }

            Section(header: Text("Exercises")) {
                ForEach($draftExercises) { $exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Exercise Name", text: $exercise.name)
                            .font(.headline)

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
            draftExercises = plan.exercises.map { $0.copy() }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    plan.name = draftName
                    plan.exercises = draftExercises
                    dismiss()
                }
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
