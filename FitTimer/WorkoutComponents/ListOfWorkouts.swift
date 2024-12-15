import SwiftUI

struct ListOfWorkouts: View {
    @Binding var workoutPlans: [WorkoutPlan]
    @Binding var isShowingAddWorkoutModal: Bool

    var body: some View {
        Section {
            ForEach(workoutPlans) { plan in
                NavigationLink(destination: WorkoutDetailView(plan: plan, onSave: { newWorkoutPlan in updateWorkout(newWorkoutPlan, &workoutPlans) })) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.name)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)

                            HStack(spacing: 8) {
                                Text("\(plan.exercises.count) exercises")
                                Text("•")
                                Text(formatDuration(getTotalTime(plan)))
                            }
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    // .padding(.vertical, 8)
                    // .padding(.horizontal, 16)
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        deleteWorkout(plan)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteWorkout(plan)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            Button(action: {
                isShowingAddWorkoutModal = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Workout Plan")
                }.foregroundColor(.accentColor)
            }
        } header: {
            HStack {
                Text("Workout Plans")
                    .font(.title2)
                    .bold()
                InfoButton(
                    title: "💪 Workout Plans",
                    message: """
                    Create and run timed workout routines!

                    • Design custom exercise sequences
                    • Set exercise and rest durations
                    • Follow along with voice guidance
                    • Perfect for HIIT and circuit training
                    """
                )
            }
        }
    }

    private func deleteWorkout(_ plan: WorkoutPlan) {
        if let index = workoutPlans.firstIndex(where: { $0.id == plan.id }) {
            workoutPlans.remove(at: index)
            saveWorkouts(workoutPlans)
        }
    }

    private func getTotalTime(_ plan: WorkoutPlan) -> Int {
        plan.exercises.reduce(0) { $0 + $1.duration + $1.rest }
    }

    private func getTotalWorkTime(_ plan: WorkoutPlan) -> Int {
        plan.exercises.reduce(0) { $0 + $1.duration }
    }

    private func getTotalRestTime(_ plan: WorkoutPlan) -> Int {
        plan.exercises.reduce(0) { $0 + $1.rest }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)m \(remainingSeconds)s"
    }
}
