import SwiftData
import SwiftUI

struct CalendarView: View {
    @Query private var workoutPlans: [WorkoutPlan]
    @Query private var activities: [Activity]

    @State private var selectedDate: Date = .init()

    private let calendar = Calendar.current

    var body: some View {
        VStack {
            DatePicker("Start Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .onChange(of: selectedDate) { oldDate, newDate in
                }
                .overlay(
                    GeometryReader { geometry in
                        // Overlay dots for each date with associated data
                        ForEach(getDatesForCurrentMonth(), id: \.self) { date in
                            if let cellPosition = getCellPosition(for: date, geometry: geometry) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                    .position(cellPosition)
                            }
                        }
                    }
                )

            // Selected date details
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if let workouts = workoutsForDate(selectedDate), !workouts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Workouts")
                                .font(.headline)
                                .foregroundColor(.primary)

                            ForEach(workouts, id: \.self) { workout in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(workout)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    if let activities = activitiesForDate(selectedDate), !activities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activities")
                                .font(.headline)
                                .foregroundColor(.primary)

                            ForEach(activities, id: \.self) { activity in
                                HStack {
                                    Image(systemName: "figure.run")
                                        .foregroundColor(.blue)
                                    Text(activity)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    if workoutsForDate(selectedDate) == nil && activitiesForDate(selectedDate) == nil {
                        Text("No activities or workouts recorded for this date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
    }

    private func getDatesForCurrentMonth() -> [Date] {
        var dates: [Date] = []
        
        // Get the start and end of the current displayed month
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        guard let firstOfMonth = calendar.date(from: components),
              let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth)
        else { return [] }
        
        // Only include dates that fall within the current month
        for act in activities {
            for history in act.history {
                if calendar.isDate(history.date, equalTo: firstOfMonth, toGranularity: .month) {
                    dates.append(history.date)
                }
            }
        }
        
        for plan in workoutPlans {
            for history in plan.completedHistory {
                if calendar.isDate(history, equalTo: firstOfMonth, toGranularity: .month) {
                    dates.append(history)
                }
            }
        }
        
        return dates
    }

    private func getCellPosition(for date: Date, geometry: GeometryProxy) -> CGPoint? {
        let calendar = Calendar.current

        // Get the first day of the displayed month
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        guard let firstOfMonth = calendar.date(from: components) else { return nil }

        // Get the weekday of the first day (1-7, 1 is Sunday)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        // Calculate the day offset from the start of the month
        let dayOffset = calendar.dateComponents([.day], from: firstOfMonth, to: date).day ?? 0

        // Calculate grid position
        let startOffset = firstWeekday - 1
        let position = startOffset + dayOffset

        // Calculate row and column
        let row = position / 7
        let col = position % 7

        // Cell size calculation (approximate)
        let cellWidth = geometry.size.width / 7
        let cellHeight = geometry.size.height / 7

        // Position calculation
        let x = (CGFloat(col) + 0.5) * cellWidth
        let y = (CGFloat(row) + 2.6) * cellHeight

        return CGPoint(x: x, y: y)
    }

    private func activitiesForDate(_ date: Date) -> [String]? {
        var strings: [String] = []
        for activity in activities {
            let activityHistoryItem = activity.history.first { history in
                calendar.isDate(history.date, inSameDayAs: date)
            }

            if let item = activityHistoryItem {
                let count = item.count
                strings.append("\(activity.name): \(count) \(count == 1 ? "time" : "times")")
            }
        }
        return strings
    }

    private func workoutsForDate(_ date: Date) -> [String]? {
        var strings: [String] = []
        for plan in workoutPlans {
            let completed = plan.completedHistory.contains { historyDate in
                calendar.isDate(historyDate, inSameDayAs: date)
            }
            if completed {
                strings.append("\(plan.name)")
            }
        }
        return strings
    }
}
