import SwiftUI

func updateActivity(_ updatedActivity: DailyActivity, _ dailyActivities: inout [DailyActivity]) {
    if let index = dailyActivities.firstIndex(where: { $0.id == updatedActivity.id }) {
        dailyActivities[index] = updatedActivity
        saveActivities(dailyActivities)
    }
}

func appendActivity(_ activity: DailyActivity, _ dailyActivities: inout [DailyActivity]) {
    dailyActivities.append(activity)
    saveActivities(dailyActivities)
}

func saveActivities(_ theDailyActivities: [DailyActivity]) {
    if let encoded = try? JSONEncoder().encode(theDailyActivities) {
        UserDefaults.standard.set(encoded, forKey: "dailyActivities")
    }
}

func loadActivities(_ dailyActivities: inout [DailyActivity]) {
    if let savedData = UserDefaults.standard.data(forKey: "dailyActivities"),
       let decoded = try? JSONDecoder().decode([DailyActivity].self, from: savedData)
    {
        dailyActivities = decoded
        print("Loaded activities: \(type(of: dailyActivities)) vaheguru")
    }
}
