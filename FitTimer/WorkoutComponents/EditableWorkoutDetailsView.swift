import SwiftUI

struct EditableWorkoutDetailsView: View {
    @Binding var plan: WorkoutPlan
    let saveChanges: () -> Void
    
    var body: some View {
        VStack {
            TextField("Workout Name", text: $plan.name)
                .font(.title)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            List {
                ForEach($plan.exercises) { $exercise in
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
            }
            
            VStack(spacing: 16) {
                Button(action: addExercise) {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
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