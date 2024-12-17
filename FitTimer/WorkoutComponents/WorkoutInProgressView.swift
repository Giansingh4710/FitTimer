import AVFoundation
import SwiftUI

struct WorkoutInProgressView: View {
    let plan: WorkoutPlan
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var currentExerciseIndex = -1
    @State private var isResting = true
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    private let speechSynthesizer = AVSpeechSynthesizer()

    private var upcomingExercises: [UpcomingExercise] {
        if currentExerciseIndex >= plan.exercises.count {
            return []
        }

        let startIndex = currentExerciseIndex + 1
        return Array(plan.exercises[startIndex...].prefix(3))
            .map { UpcomingExercise(name: $0.name, duration: $0.duration) }
    }

    private var totalTimeRemaining: Int {
        // Calculate time remaining in current exercise/rest
        var total = timeRemaining

        // If we're not done yet, add remaining exercises and rests
        if currentExerciseIndex < plan.exercises.count - 1 {
            // Add remaining time from future exercises
            for index in (currentExerciseIndex + 1) ..< plan.exercises.count {
                total += plan.exercises[index].duration
                if index < plan.exercises.count - 1 { // Don't add rest after last exercise
                    total += plan.exercises[index].rest
                }
            }

            // If we're in an exercise, add the rest period after it
            if !isResting && currentExerciseIndex < plan.exercises.count - 1 {
                total += plan.exercises[currentExerciseIndex].rest
            }
        }

        return total
    }

    var body: some View {
        VStack {
            if currentExerciseIndex < plan.exercises.count {
                let currentExercise = currentExerciseIndex >= 0 ? plan.exercises[currentExerciseIndex] : plan.exercises[0]
                WorkoutTimerView(
                    exerciseName: isResting ? "Get Ready" : currentExercise.name,
                    timeRemaining: timeRemaining,
                    totalTime: isResting ?
                        (currentExerciseIndex >= 0 ? currentExercise.rest : 5) :
                        currentExercise.duration,
                    isResting: isResting,
                    upcomingExercises: upcomingExercises,
                    currentExerciseNumber: max(1, currentExerciseIndex + 1),
                    totalExercises: plan.exercises.count,
                    totalTimeRemaining: totalTimeRemaining
                )

                Button(action: cancelWorkout) {
                    Text("Cancel Workout")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Workout Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    Button("Done") {
                        onComplete()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        .onAppear(perform: startWorkout)
        .onDisappear {
            cancelWorkout()
        }
    }

    private func startWorkout() {
        startTimer(isInitialRest: true)
    }

    private func startTimer(isInitialRest: Bool = false) {
        let exercise = currentExerciseIndex >= 0 ? plan.exercises[currentExerciseIndex] : plan.exercises[0]
        timeRemaining = isResting ?
            (isInitialRest ? 5 : exercise.rest) :
            exercise.duration

        announce(isResting ?
            (isInitialRest ? "Get ready to start" : "Rest") :
            "Start \(exercise.name)")

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            handleTimerTick(exercise: exercise)
        }
    }

    private func handleTimerTick(exercise: Exercise) {
        if timeRemaining > 0 {
            timeRemaining -= 1
            if !isResting {
                if timeRemaining == exercise.duration / 2 {
                    announce("Halfway there!")
                }
                if timeRemaining <= 3 && timeRemaining > 0 {
                    announce("\(timeRemaining)")
                }
            }
        } else {
            timer?.invalidate()

            if isResting {
                if currentExerciseIndex < plan.exercises.count - 1 {
                    currentExerciseIndex += 1
                    isResting = false
                    startTimer()
                } else {
                    currentExerciseIndex += 1
                }
            } else {
                if currentExerciseIndex < plan.exercises.count - 1 {
                    isResting = true
                    startTimer()
                } else {
                    currentExerciseIndex += 1
                }
            }

            if currentExerciseIndex >= plan.exercises.count {
                // HistoryManager.shared.logWorkoutCompletion(plan)
            }
        }
    }

    private func announce(_ message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    private func cancelWorkout() {
        timer?.invalidate()
        speechSynthesizer.stopSpeaking(at: .immediate)
        onCancel()
    }
}


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
