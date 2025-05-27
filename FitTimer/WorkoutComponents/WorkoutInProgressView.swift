import AVFoundation
import SwiftUI

struct WorkoutInProgressView: View {
    let plan: WorkoutPlan
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var currentExerciseIndex = 0
    @State private var isResting = true
    @State private var timeLeftForCurrentRound = 0
    @State private var timer: Timer?
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // Add UIApplication reference
    @Environment(\.scenePhase) private var scenePhase

    private var totalTimeRemaining: Int {
        var total = timeLeftForCurrentRound

        if isResting && currentExerciseIndex < plan.exercises.count {
            total += plan.exercises[currentExerciseIndex].duration
        }

        for index in (currentExerciseIndex + 1) ..< plan.exercises.count {
            total += plan.exercises[index].rest
            total += plan.exercises[index].duration
        }

        return total
    }

    var body: some View {
        VStack {
            if currentExerciseIndex < plan.exercises.count {
                let currentExercise = plan.exercises[currentExerciseIndex]
                WorkoutTimerView(
                    exerciseName: isResting ? "Get Ready for \(currentExercise.name)" : currentExercise.name,
                    timeLeftForCurrentRound: timeLeftForCurrentRound,
                    totalTimeForCurrentRound: isResting ? currentExercise.rest : currentExercise.duration,
                    isResting: isResting,
                    currentExerciseIndex: currentExerciseIndex,
                    allExercises: plan.exercises,
                    totalTimeRemaining: totalTimeRemaining
                )

                HStack {
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
                    Button(action: skipToNextThing) {
                        Text("Skip to \(isResting ? "\(currentExercise.name)" : "Rest")")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
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
        .onAppear {
            startWorkout()
            // Keep screen on during workout
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            cleanup()
            // Allow screen to sleep again
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func startWorkout() {
        startTimer(isInitialRest: true)
    }

    private func startTimer(isInitialRest: Bool = false) {
        let exercise = plan.exercises[currentExerciseIndex]
        timeLeftForCurrentRound = isResting ? exercise.rest : exercise.duration

        announce(isResting ?
            (isInitialRest ? "Get ready to start" : "Rest") :
            "Start \(exercise.name)")

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            handleTimerTick(exercise: exercise)
        }
    }

    private func handleTimerTick(exercise: Exercise) {
        if timeLeftForCurrentRound > 0 {
            timeLeftForCurrentRound -= 1
            if !isResting {
                if timeLeftForCurrentRound == exercise.duration / 2 {
                    announce("Halfway there!")
                }
                if timeLeftForCurrentRound <= 3 && timeLeftForCurrentRound > 0 {
                    announce("\(timeLeftForCurrentRound)")
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
        }
    }

    private func announce(_ message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    private func cleanup() {
        timer?.invalidate()
        timer = nil
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    private func cancelWorkout() {
        cleanup()
        onCancel()
    }

    private func skipToNextThing() {
        if isResting {
            isResting = false
            startTimer()
        } else {
            if currentExerciseIndex < plan.exercises.count - 1 {
                isResting = true
                startTimer()
            }
            currentExerciseIndex += 1
        }
    }
}

struct UpcomingExercise: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let duration: Int
}

struct WorkoutTimerView: View {
    let exerciseName: String
    let timeLeftForCurrentRound: Int
    let totalTimeForCurrentRound: Int
    let isResting: Bool

    let currentExerciseIndex: Int
    let allExercises: [Exercise]
    let totalTimeRemaining: Int

    private var upcomingExercises: [UpcomingExercise] {
        if currentExerciseIndex >= allExercises.count {
            return []
        }

        let startIndex = currentExerciseIndex + 1
        return Array(allExercises[startIndex...].prefix(3))
            .map { UpcomingExercise(name: $0.name, duration: $0.duration) }
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(exerciseName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isResting ? .red : .green)

                Text("Exercise \(max(1, currentExerciseIndex + 1))/\(allExercises.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Total Time Left: \(formatTime(totalTimeRemaining))")
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
                    .trim(from: 0, to: CGFloat(timeLeftForCurrentRound) / CGFloat(totalTimeForCurrentRound))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(isResting ? .red : .green)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: timeLeftForCurrentRound)

                Text("\(timeLeftForCurrentRound)")
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
        .onAppear {}
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

