import SwiftUI

struct WorkoutOverviewView: View {
    let plan: WorkoutPlan
    let onStartWorkout: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Display workout name and exercises
            Text(plan.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            List {
                ForEach(plan.exercises) { exercise in
                    ExerciseRow(exercise: exercise)
                }
            }
            
            // Action buttons
            HStack(spacing: 20) {
                StartWorkoutButton(action: onStartWorkout)
                EditWorkoutButton(action: onEdit)
            }
            .padding(.horizontal)
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
        .padding(.vertical, 8)
    }
}

private struct StartWorkoutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Start Workout", systemImage: "play.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
        }
    }
}

private struct EditWorkoutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Edit", systemImage: "pencil.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
    }
} 