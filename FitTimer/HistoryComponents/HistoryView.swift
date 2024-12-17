// import SwiftUI
//
// struct HistoryView: View {
//     @StateObject private var historyManager = HistoryManager.shared
//     @State private var selectedDate = Date()
//     
//     var body: some View {
//         NavigationView {
//             VStack(spacing: 0) {
//                 // Calendar
//                 DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
//                     .datePickerStyle(.graphical)
//                     .padding()
//                 
//                 ScrollView {
//                     VStack(spacing: 20) {
//                         // Today's Summary
//                         if Calendar.current.isDateInToday(selectedDate) {
//                             HStack {
//                                 Text("Today's Progress")
//                                     .font(.title2)
//                                     .fontWeight(.bold)
//                                 Spacer()
//                             }
//                             .padding(.horizontal)
//                         }
//                         
//                         if let dayLog = getDayLog(for: selectedDate) {
//                             // Completed Workouts Section
//                             if !dayLog.completedWorkouts.isEmpty {
//                                 VStack(alignment: .leading, spacing: 12) {
//                                     Text("Completed Workouts")
//                                         .font(.headline)
//                                         .padding(.horizontal)
//                                     
//                                     ForEach(dayLog.completedWorkouts) { workout in
//                                         WorkoutLogCard(workout: workout)
//                                     }
//                                 }
//                             }
//                             
//                             // Activity Counts Section
//                             if !dayLog.activityCounts.isEmpty {
//                                 VStack(alignment: .leading, spacing: 12) {
//                                     Text("Daily Activities")
//                                         .font(.headline)
//                                         .padding(.horizontal)
//                                     
//                                     ForEach(dayLog.activityCounts) { activity in
//                                         ActivityLogCard(activity: activity)
//                                     }
//                                 }
//                             }
//                         } else {
//                             EmptyStateView(
//                                 title: "No Activity",
//                                 systemImage: "calendar",
//                                 description: "No workouts or activities were completed on this day"
//                             )
//                         }
//                     }
//                     .padding()
//                 }
//             }
//             .navigationTitle("History")
//         }
//     }
//     
//     private func getDayLog(for date: Date) -> DayLog? {
//         historyManager.dayLogs.first {
//             Calendar.current.isDate($0.date, inSameDayAs: date)
//         }
//     }
// }
//
// // Helper Views
// struct WorkoutLogCard: View {
//     let workout: CompletedWorkout
//
//     private let dateFmt: DateFormatter = {
//         let formatter = DateFormatter()
//         formatter.dateStyle = .short
//         formatter.timeStyle = .medium
//         return formatter
//     }()
//
//     
//     var body: some View {
//         VStack(alignment: .leading, spacing: 8) {
//             Text(workout.workoutName)
//                 .font(.title3)
//                 .fontWeight(.semibold)
//             
//             HStack {
//                 Image(systemName: "dumbbell.fill")
//                 Text("\(workout.exercises.count) exercises")
//                 Spacer()
//                 Image(systemName: "clock")
//                 Text(dateFmt.string(from: workout.completedAt))
//             }
//             .font(.subheadline)
//             .foregroundColor(.secondary)
//         }
//         .padding()
//         .background(Color.secondary.opacity(0.1))
//         .cornerRadius(10)
//         .padding(.horizontal)
//     }
// }
//
// struct ActivityLogCard: View {
//     let activity: ActivityCount
//     
//     var body: some View {
//         HStack {
//             VStack(alignment: .leading) {
//                 Text(activity.activityName)
//                     .font(.headline)
//                 Text("Completed \(activity.count) times")
//                     .font(.subheadline)
//                     .foregroundColor(.secondary)
//             }
//             
//             Spacer()
//             
//             Text("\(activity.count)")
//                 .font(.title2)
//                 .fontWeight(.bold)
//                 .foregroundColor(.accentColor)
//         }
//         .padding()
//         .background(Color.secondary.opacity(0.1))
//         .cornerRadius(10)
//         .padding(.horizontal)
//     }
// } 
