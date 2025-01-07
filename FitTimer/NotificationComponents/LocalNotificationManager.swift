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

    func scheduleCalendarNotification(identifier: String, title: String, body: String, dateComponents: DateComponents, repeats: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await notificationCenter.add(request)
        await getPendingRequests()
    }

    func getPendingRequests() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        pendingRequests = requests.sorted { request1, request2 in
            guard let trigger1 = request1.trigger as? UNCalendarNotificationTrigger,
                  let trigger2 = request2.trigger as? UNCalendarNotificationTrigger,
                  let date1 = trigger1.nextTriggerDate(),
                  let date2 = trigger2.nextTriggerDate()
            else {
                return false
            }
            return date1 < date2
        }
    }

    func removeRequest(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        if let index = pendingRequests.firstIndex(where: { $0.identifier == identifier }) {
            pendingRequests.remove(at: index)
        }
    }

    func removeNotifications(for activityOrWorkout: any CommonProps) {
        var newPendingRequests: [UNNotificationRequest] = []
        var uuidsToRemove: [String] = []
        for request in pendingRequests {
            if request.identifier.hasPrefix(activityOrWorkout.id.uuidString) {
                uuidsToRemove.append(request.identifier)
            } else {
                newPendingRequests.append(request)
            }
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: uuidsToRemove)

        pendingRequests = newPendingRequests
    }

    func scheduleNotifications(for activityOrWorkout: any CommonProps) async {
        removeNotifications(for: activityOrWorkout)
        for components in activityOrWorkout.notifications {
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute

            await scheduleCalendarNotification(
                identifier: makeNotificationIdString(activityOrWorkout, dateComponents),
                title: activityOrWorkout.notificationText.title,
                body: activityOrWorkout.notificationText.body,
                // subtitle: nil,
                dateComponents: dateComponents,
                repeats: true
            )
        }
    }

    func clearRequests() {
        notificationCenter.removeAllPendingNotificationRequests()
        pendingRequests.removeAll()
    }

    func makeNotificationIdString(_ activityOrWorkout: any CommonProps, _ components: DateComponents) -> String {
        return "\(activityOrWorkout.id)_\(activityOrWorkout.name)_\(components.hour ?? 0)_\(components.minute ?? 0)"
    }
}

protocol CommonProps {
    var id: UUID { get }
    var name: String { get }
    var notifications: [DateComponents] { get }
    var notificationText: NotificationTextData { get }
}

extension Activity: CommonProps {}
extension WorkoutPlan: CommonProps {}
