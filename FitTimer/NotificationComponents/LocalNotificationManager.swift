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
            print("Pending: \(pendingRequests.count)")
        }
    }

    func removeNotificationsForActivity(activity: Activity) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers:
            activity.notifications.map { "\(activity.id)_\(activity.name)_\($0.hour ?? 0)_\($0.minute ?? 0)" }
        ) 

        pendingRequests.removeAll(where: { $0.identifier.contains(activity.id.uuidString) })
    }

    func scheduleNotificationsForActivity(activity: Activity) async {
        removeNotificationsForActivity(activity: activity) // do i need this because if same identifier will be overwritten

        for components in activity.notifications {
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute

            await scheduleCalendarNotification(
                identifier: "\(activity.id)_\(activity.name)_\(components.hour ?? 0)_\(components.minute ?? 0)",
                title: "\(activity.name)",
                body: "Track your progress by adding to your daily count.",
                subtitle: "Time for \(activity.name)!",
                dateComponents: dateComponents,
                repeats: true
            )
        }
    }

    func clearRequests() {
        notificationCenter.removeAllPendingNotificationRequests()
        pendingRequests.removeAll()
        print("Pending: \(pendingRequests.count)")
    }
}
