import SwiftUI

struct UpcomingExercise: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let duration: Int
}

struct WorkoutTimerView: View {
    let exerciseName: String
    let timeRemaining: Int
    let totalTime: Int
    let isResting: Bool
    let upcomingExercises: [UpcomingExercise]
    let currentExerciseNumber: Int
    let totalExercises: Int
    let totalTimeRemaining: Int

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(exerciseName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isResting ? .red : .green)

                Text("Exercise \(currentExerciseNumber)/\(totalExercises)")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Total Time: \(formatTime(totalTimeRemaining))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(isResting ? .red : .green)

                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(totalTime))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(isResting ? .red : .green)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: timeRemaining)

                Text("\(timeRemaining)")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(width: 250, height: 250)
            .padding()

            if !upcomingExercises.isEmpty {
                VStack(spacing: 8) {
                    Text("Coming Up")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ForEach(Array(upcomingExercises.enumerated()), id: \.element.id) { index, exercise in
                        HStack {
                            Text(exercise.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(exercise.duration)s")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: upcomingExercises)
                        .zIndex(Double(upcomingExercises.count - index))
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(16)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
