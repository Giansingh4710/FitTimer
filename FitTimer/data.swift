import SwiftData
import SwiftUI

@Model
class NotificationTextData {
    var title: String
    var body: String
    init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}

@Model
class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var duration: Int // in seconds
    var rest: Int // in seconds

    init(id: UUID = UUID(), name: String, duration: Int, rest: Int) {
        self.id = id
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
    @Relationship(deleteRule: .cascade) var notificationText: NotificationTextData
    var notifications: [DateComponents]
    var completedHistory: [Date]
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]

    init(id: UUID = UUID(), createdAt: Date = Date(), completedHistory: [Date] = [], name: String, notifications: [DateComponents] = [], exercises: [Exercise] = [], notificationText: NotificationTextData = NotificationTextData(title: "", body: "")) {
        self.id = id
        self.createdAt = createdAt
        self.completedHistory = completedHistory
        self.name = name
        self.notifications = notifications
        self.exercises = exercises
        self.notificationText = notificationText
        if self.notificationText.title == "" {
            self.notificationText.title = name
            self.notificationText.body = "Reminder for \(name)"
        }
    }

    func print_workout() {
        print("name: \(name)")
        print("createdAt: \(createdAt)")
        print("completedHistory: \(completedHistory)")
        print("notifications: \(notifications)")
        print("exercises: \(exercises)")
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
    @Relationship(deleteRule: .cascade) var notificationText: NotificationTextData

    var resetDaily: Bool
    var lastCounted: Date
    var todayCount: Int
    @Relationship(deleteRule: .cascade) var history: [ActivityHistory]

    init(id: UUID = UUID(), name: String, count: Int = 0, notifications: [DateComponents] = [], resetDaily: Bool = true, createdAt: Date = Date(), lastCounted: Date = Date(), todayCount: Int = 0, history: [ActivityHistory] = [], notificationText: NotificationTextData = NotificationTextData(title: "", body: "")) {
        self.id = id
        self.name = name
        self.count = count
        self.notifications = notifications
        self.resetDaily = resetDaily
        self.createdAt = createdAt
        self.lastCounted = lastCounted
        self.todayCount = todayCount
        self.history = history
        self.notificationText = notificationText
        if self.notificationText.title == "" {
            self.notificationText.title = name
            self.notificationText.body = "Reminder for \(name)"
        }
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
        if isNewDay() {
            if todayCount != 0 {
                history.append(ActivityHistory(count: todayCount, date: lastCounted))
            }

            if resetDaily {
                count = 0
            }
            lastCounted = Date()
            todayCount = 0
        }
    }

    func isNewDay() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        return !calendar.isDate(lastCounted, inSameDayAs: now) // Check if the last reset was on a different day
    }

    func print_activity() {
        print("name: \(name)")
        print("createdAt: \(createdAt)")
        print("count: \(count)")
        print("notifications: \(notifications)")
        print("resetDaily: \(resetDaily)")
        print("lastCounted: \(lastCounted)")
        print("todayCount: \(todayCount)")
        for historyItem in history {
            print("Date: \(historyItem.date), Count: \(historyItem.count)")
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
