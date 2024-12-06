import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State var plan: WorkoutPlan
    let onSave: (WorkoutPlan) -> Void
    @State private var showingWorkout = false
    @State private var showingEditor = false

    var body: some View {
        VStack(spacing: 0) {
            Text(plan.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(plan.exercises) { exercise in
                        ExerciseRow(exercise: exercise)
                    }
                }
                .padding(.horizontal)
            }

            VStack(spacing: 12) {
                NavigationLink(destination: WorkoutEditorView(plan: $plan, onSave: onSave)) {
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
            .background(Color.systemBackground)
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

extension Color {
    static let systemBackground = Color(UIColor.systemBackground)
}
