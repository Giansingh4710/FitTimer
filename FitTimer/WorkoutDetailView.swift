import SwiftUI
import AVFoundation

struct WorkoutDetailView: View {
    @State var plan: WorkoutPlan
    let onSave: (WorkoutPlan) -> Void
    @State private var currentExerciseIndex = 0
    @State private var isResting = false
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var isWorkoutStarted = false
    @State private var isEditing = false
    private let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack {
            if isWorkoutStarted {
                TimerView(plan: plan, currentExerciseIndex: $currentExerciseIndex, isResting: $isResting, timeRemaining: $timeRemaining, timer: $timer, speechSynthesizer: speechSynthesizer, cancelWorkout: cancelWorkout)
            } else {
                if isEditing {
                    EditableWorkoutDetailsView(plan: $plan, saveChanges: saveChanges)
                } else {
                    WorkoutDetailsView(plan: plan, startWorkout: startWorkout, editWorkout: { isEditing = true })
                }
            }
        }
        .padding()
        .onDisappear {
            cancelWorkout()
            onSave(plan)
        }
    }

    private func startWorkout() {
        isWorkoutStarted = true
        if currentExerciseIndex < plan.exercises.count {
            let currentExercise = plan.exercises[currentExerciseIndex]
            startTimer(for: currentExercise)
        }
    }

    private func startTimer(for exercise: Exercise) {
        timeRemaining = isResting ? exercise.rest : exercise.duration
        announce(isResting ? "Rest" : "Start \(exercise.name)")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                if timeRemaining == exercise.duration / 2 {
                    announce("Halfway there!")
                }
                if timeRemaining <= 3 {
                    announce("\(timeRemaining)")
                }
            } else {
                timer?.invalidate()
                if isResting {
                    currentExerciseIndex += 1
                }
                isResting.toggle()
                if currentExerciseIndex < plan.exercises.count {
                    startTimer(for: plan.exercises[currentExerciseIndex])
                } else {
                    isWorkoutStarted = false
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
        isWorkoutStarted = false
    }

    private func saveChanges() {
        isEditing = false
        onSave(plan)
    }
}

struct WorkoutDetailsView: View {
    var plan: WorkoutPlan
    var startWorkout: () -> Void
    var editWorkout: () -> Void

    var body: some View {
        VStack {
            Text(plan.name)
                .font(.largeTitle)
            List(plan.exercises) { exercise in
                Text(exercise.name)
            }
            HStack {
                Button("Start Workout") {
                    startWorkout()
                }
                .padding()
                Button("Edit Workout") {
                    editWorkout()
                }
                .padding()
            }
        }
    }
}

struct EditableWorkoutDetailsView: View {
    @Binding var plan: WorkoutPlan
    var saveChanges: () -> Void

    var body: some View {
        VStack {
            TextField("Workout Name", text: $plan.name)
                .font(.largeTitle)
                .padding()
            List {
                ForEach($plan.exercises) { $exercise in
                    VStack(alignment: .leading) {
                        TextField("Exercise Name", text: $exercise.name)
                        HStack {
                            TextField("Duration (seconds)", value: $exercise.duration, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                            TextField("Rest (seconds)", value: $exercise.rest, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                        }
                    }
                }
                .onDelete(perform: deleteExercise)
            }
            Button("Add Exercise") {
                addExercise()
            }
            .padding()
            Button("Save Changes") {
                saveChanges()
            }
            .padding()
        }
    }

    private func addExercise() {
        let newExercise = Exercise(name: "New Exercise", duration: 30, rest: 10)
        plan.exercises.append(newExercise)
    }

    private func deleteExercise(at offsets: IndexSet) {
        plan.exercises.remove(atOffsets: offsets)
    }
}

struct TimerView: View {
    var plan: WorkoutPlan
    @Binding var currentExerciseIndex: Int
    @Binding var isResting: Bool
    @Binding var timeRemaining: Int
    @Binding var timer: Timer?
    var speechSynthesizer: AVSpeechSynthesizer
    var cancelWorkout: () -> Void

    var body: some View {
        VStack {
            if currentExerciseIndex < plan.exercises.count {
                let currentExercise = plan.exercises[currentExerciseIndex]
                Text(isResting ? "Rest" : currentExercise.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isResting ? .red : .green)
                    .padding()

                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.3)
                        .foregroundColor(isResting ? .red : .green)

                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(isResting ? currentExercise.rest : currentExercise.duration))
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

                Button(action: cancelWorkout) {
                    Text("Cancel Workout")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            } else {
                Text("Workout Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
} 
