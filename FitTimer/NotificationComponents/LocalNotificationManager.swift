//
// Created for LocalNotifications
// by Stewart Lynch on 2022-05-22
// Using Swift 5.0
//
// Follow me on Twitter: @StewartLynch
// Subscribe on YouTube: https://youTube.com/StewartLynch
//

import Foundation
import NotificationCenter

@MainActor
class LocalNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    let notificationCenter = UNUserNotificationCenter.current()
    @Published var isGranted = false
    @Published var pendingRequests: [UNNotificationRequest] = []

    override init() {
        super.init()
        notificationCenter.delegate = self
    }

    // Delegate function
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification) async -> UNNotificationPresentationOptions {
        await getPendingRequests()
        return [.sound, .banner]
    }

    func requestAuthorization() async throws {
        try await notificationCenter.requestAuthorization(options: [.sound, .badge, .alert])
        await getCurrentSettings()
    }

    func getCurrentSettings() async {
        let currentSettings = await notificationCenter.notificationSettings()
        isGranted = (currentSettings.authorizationStatus == .authorized)
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                Task {
                    await UIApplication.shared.open(url)
                }
            }
        }
    }

    func scheduleCalendarNotification(identifier: String, title: String, body: String, subtitle: String? = nil, dateComponents: DateComponents, repeats: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let theSubtitle = subtitle {
            content.subtitle = theSubtitle
        }
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await notificationCenter.add(request)
        await getPendingRequests()
    }

    func getPendingRequests() async {
        pendingRequests = await notificationCenter.pendingNotificationRequests()
        print("Pending: \(pendingRequests.count)")
    }

    func removeRequest(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        if let index = pendingRequests.firstIndex(where: { $0.identifier == identifier }) {
            pendingRequests.remove(at: index)
        }
    }

    func removeNotificationsForActivity(activity: Activity) {
        var newPendingRequests: [UNNotificationRequest] = []
        var uuidsToRemove: [String] = []
        for request in pendingRequests {
            if request.identifier.hasPrefix(activity.id.uuidString) {
                uuidsToRemove.append(request.identifier)
            } else {
                newPendingRequests.append(request)
            }
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: uuidsToRemove)

        print("before removal: \(pendingRequests.count), \(activity.id.uuidString)")
        pendingRequests = newPendingRequests
        print("after removal: \(pendingRequests.count)")
    }

    func scheduleNotificationsForActivity(activity: Activity) async {
        removeNotificationsForActivity(activity: activity)

        print("Before Schedule: \(pendingRequests.count)")
        await getPendingRequests()
        for components in activity.notifications {
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute

            await scheduleCalendarNotification(
                identifier: makeNotificationIdString(activity, dateComponents),
                title: "\(activity.name)",
                body: "Track your progress by adding to your daily count.",
                subtitle: "Time for \(activity.name)!",
                dateComponents: dateComponents,
                repeats: true
            )
        }
        print("After Schedule: \(pendingRequests.count)")
    }

    func clearRequests() {
        notificationCenter.removeAllPendingNotificationRequests()
        pendingRequests.removeAll()
        print("After Clear Pending: \(pendingRequests.count) == 0")
    }
}

func makeNotificationIdString(_ activity: Activity, _ components: DateComponents) -> String {
    return "\(activity.id)_\(activity.name)_\(components.hour ?? 0)_\(components.minute ?? 0)"
}
