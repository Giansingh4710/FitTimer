import SwiftData
import SwiftUI

@Model
class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var duration: Int // in seconds
    var rest: Int // in seconds

    init(name: String, duration: Int, rest: Int) {
        id = UUID()
        self.name = name
        self.duration = duration
        self.rest = rest
    }

    func copy() -> Exercise {
        return Exercise(name: name, duration: duration, rest: rest)
    }
}

@Model
class WorkoutPlan {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var name: String
    var notifications: [DateComponents]
    var completedHistory: [Date]
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]

    init(name: String, exercises: [Exercise] = [], notifications: [DateComponents] = []) {
        id = UUID()
        createdAt = Date()
        completedHistory = []
        self.name = name
        self.notifications = notifications
        self.exercises = exercises
    }
}

@Model
class ActivityHistory {
    var count: Int
    var date: Date
    init(count: Int, date: Date) {
        self.count = count
        self.date = date
    }
}

@Model
class Activity {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var name: String
    var count: Int
    var notifications: [DateComponents]

    var resetDaily: Bool
    var lastCounted: Date
    var todayCount: Int
    @Relationship(deleteRule: .cascade) var history: [ActivityHistory]

    init(id: UUID = UUID(), name: String, count: Int = 0, notifications: [DateComponents] = [], resetDaily: Bool = true) {
        self.id = id
        self.name = name
        self.count = count
        self.notifications = notifications
        self.resetDaily = resetDaily
        createdAt = Date()
        lastCounted = Date()
        todayCount = 0
        history = []
    }

    func getNextNotification() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        return notifications.compactMap { components -> Date? in
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            dateComponents.day = calendar.component(.day, from: now)
            dateComponents.month = calendar.component(.month, from: now)
            dateComponents.year = calendar.component(.year, from: now)
            guard let date = calendar.date(from: dateComponents) else { return nil }
            return date > now ? date : calendar.date(byAdding: .day, value: 1, to: date)
        }.min()
    }

    func formatNextNotification() -> String? {
        guard let next = getNextNotification() else { return nil }
        return DateFormatter.timeFormatter.string(from: next)
    }

    func updateIfNewDay() {
        let calendar = Calendar.current
        let now = Date()

        // Check if the last reset was on a different day
        if !calendar.isDate(lastCounted, inSameDayAs: now) {
            if todayCount != 0 {
                history.append(ActivityHistory(count: todayCount, date: now))
            }

            if resetDaily {
                count = 0
            }
            lastCounted = now
            todayCount = 0
        }
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
