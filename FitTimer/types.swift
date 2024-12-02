import SwiftUI

struct Exercise: Identifiable, Codable {
    let id = UUID()
    var name: String
    var duration: Int // in seconds
    var rest: Int // in seconds
}

struct WorkoutPlan: Identifiable, Codable {
    let id = UUID()
    var name: String
    var exercises: [Exercise]
}

struct DailyActivity: Identifiable, Codable {
    let id = UUID()
    var name: String
    var count: Int
    var notifications: [DateComponents] // Times for notifications
}
