import SwiftData
import SwiftUI

struct ListOfWorkouts: View {
    @Binding var isShowingAddWorkoutModal: Bool
    @Query(sort: \WorkoutPlan.createdAt) private var workoutPlans: [WorkoutPlan]
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var lnManager: LocalNotificationManager

    @State private var workoutToDelete: WorkoutPlan?
    @State private var showDeleteAlert = false

    var body: some View {
        Section {
            ForEach(workoutPlans) { plan in
                NavigationLink(destination: WorkoutDetailView(plan: plan)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.name)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)

                            HStack(spacing: 8) {
                                Text(formatDuration(getTotalWorkoutTime(plan)))
                                Text("•")
                                Text("\(plan.notifications.count) reminders")
                            }
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        workoutToDelete = plan
                        showDeleteAlert = true
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
                Text(workoutPlans.count == 1 ? "1 Workout Plan" : "\(workoutPlans.count) Workout Plans")
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
        .onAppear {
            for workout in workoutPlans {
                Task {
                    await lnManager.scheduleNotifications(for: workout)
                }
            }
        }
        .alert("Are you sure you want to delete this workout plan?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive, action: {
                if let plan = workoutToDelete {
                    modelContext.delete(plan)
                }
            })
            Button("Cancel", role: .cancel, action: {
                workoutToDelete = nil
                showDeleteAlert = false
            })
        }
    }
}
