import SwiftUI

struct WorkoutEditorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var plan: WorkoutPlan
    let onSave: (WorkoutPlan) -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Workout Details")) {
                TextField("Workout Name", text: $plan.name)
                    .font(.headline)
            }
            
            Section(header: Text("Exercises")) {
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
                
                Button(action: addExercise) {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    onSave(plan)
                    dismiss()
                }
            }
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