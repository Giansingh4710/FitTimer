import SwiftData
import SwiftUI

struct NotificationTextData: Codable, Hashable {
    var title: String
    var body: String
}

struct ActivityHistory: Codable, Hashable {
    var count: Int
    var date: Date
}

struct Exercise: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var duration: Int // in seconds
    var rest: Int // in seconds

    init(id: UUID = UUID(), name: String, duration: Int, rest: Int) {
        self.id = id
        self.name = name
        self.duration = duration
        self.rest = rest
    }
}

@Model
class WorkoutPlan {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var name: String
    @Relationship(deleteRule: .cascade) var notificationText: NotificationTextData
    var notificationsOff: Bool
    var notifications: [DateComponents]
    var completedHistory: [Date]
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]

    init(id: UUID = UUID(), createdAt: Date = Date(), completedHistory: [Date] = [], name: String, notifications: [DateComponents] = [], exercises: [Exercise] = [], notificationText: NotificationTextData = NotificationTextData(title: "", body: ""), notificationsOff: Bool = false) {
        self.id = id
        self.createdAt = createdAt
        self.completedHistory = completedHistory
        self.name = name
        self.notifications = notifications
        self.exercises = exercises
        self.notificationText = notificationText
        self.notificationsOff = notificationsOff
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
class Activity {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var name: String
    var count: Int
    var notificationsOff: Bool
    var notifications: [DateComponents]
    @Relationship(deleteRule: .cascade) var notificationText: NotificationTextData

    var resetDaily: Bool
    var lastCounted: Date
    var todayCount: Int

    var history: [ActivityHistory]

    init(id: UUID = UUID(), name: String, count: Int = 0, notifications: [DateComponents] = [], resetDaily: Bool = true, createdAt: Date = Date(), lastCounted: Date = Date(), todayCount: Int = 0, history: [ActivityHistory] = [], notificationText: NotificationTextData = NotificationTextData(title: "", body: ""), notificationsOff: Bool = false) {
        self.id = id
        self.name = name
        self.count = count
        self.notifications = notifications
        self.resetDaily = resetDaily
        self.createdAt = createdAt
        self.lastCounted = lastCounted
        self.todayCount = todayCount
        self.history = history
        self.notificationsOff = notificationsOff
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
            let sortedHistory = history.sorted { $0.date > $1.date }
            history = sortedHistory
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

    func calculateStreak() -> Int {
        guard !history.isEmpty else { return 0 }

        var currentStreak = 0
        let calendar = Calendar.current
        var lastDate = calendar.startOfDay(for: Date())

        for historyItem in history {
            let historyDate = calendar.startOfDay(for: historyItem.date)
            let daysBetween = calendar.dateComponents([.day], from: historyDate, to: lastDate).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
                lastDate = historyDate
            } else {
                break
            }
        }

        return currentStreak
    }

    func getLongestStreak() -> Int {
        guard !history.isEmpty else { return 0 }

        var longestStreak = 0
        var currentStreak = 0
        let calendar = Calendar.current
        var lastDate = calendar.startOfDay(for: Date())

        for historyItem in history {
            let historyDate = calendar.startOfDay(for: historyItem.date)
            let daysBetween = calendar.dateComponents([.day], from: historyDate, to: lastDate).day ?? 0
            if daysBetween == -1 {
                currentStreak += 1
            } else {
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
                currentStreak = 0
            }
            lastDate = historyDate
        }

        return longestStreak
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

enum MainAppItems: String { case workout_plans, activities }
