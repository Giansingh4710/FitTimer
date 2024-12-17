import SwiftData
import SwiftUI

@Model
class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var duration: Int // in seconds
    var rest: Int // in seconds
    var notifications: [DateComponents]

    init(name: String, duration: Int, rest: Int, notifications: [DateComponents] = []) {
        id = UUID()
        self.name = name
        self.duration = duration
        self.rest = rest
        self.notifications = notifications
    }

    func copy() -> Exercise {
        return Exercise(name: name, duration: duration, rest: rest)
    }
}

@Model
class WorkoutPlan {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]

    init(name: String, exercises: [Exercise] = []) {
        id = UUID()
        createdAt = Date()
        self.name = name
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
class DailyActivity {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var name: String
    var count: Int
    var notifications: [DateComponents]

    var resetDaily: Bool
    var lastCounted: Date
    var history: [ActivityHistory]
    var todayCount: Int

    init(id: UUID = UUID(), name: String, count: Int = 0, notifications: [DateComponents] = [], resetDaily: Bool = true) {
        self.id = id
        createdAt = Date()
        self.name = name
        self.count = count
        self.notifications = notifications
        self.resetDaily = resetDaily
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
            print(count, todayCount, now, lastCounted, todayCount)
            history.append(ActivityHistory(count: todayCount, date: now))

            if resetDaily {
                count = 0
            }
            lastCounted = now
            todayCount = 0
            // If you're using CoreData or another persistence method:
            // try? modelContext.save()
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
