import SwiftUI

struct Exercise: Identifiable, Codable {
    var id = UUID()
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

struct WorkoutPlan: Identifiable, Codable {
    var id = UUID()
    var name: String
    var exercises: [Exercise]

    init(id: UUID = UUID(), name: String, exercises: [Exercise]) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
}

struct DailyActivity: Identifiable, Codable {
    var id: UUID // Changed to var and will be initialized in init
    var name: String
    var count: Int
    var notifications: [DateComponents]

    init(id: UUID = UUID(), name: String, count: Int = 0, notifications: [DateComponents] = []) {
        self.id = id
        self.name = name
        self.count = count
        self.notifications = notifications
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
}
