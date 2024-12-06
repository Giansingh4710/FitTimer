import SwiftUI
import AVFoundation

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
            for index in (currentExerciseIndex + 1)..<plan.exercises.count {
                total += plan.exercises[index].duration
                if index < plan.exercises.count - 1 {  // Don't add rest after last exercise
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
                WorkoutCompleteView(onDismiss: onComplete)
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
