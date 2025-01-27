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
import SwiftUI

import SwiftData

@MainActor
class LocalNotificationManager: NSObject, ObservableObject {
    let notificationCenter = UNUserNotificationCenter.current()
    @Published var isGranted = false
    @Published var pendingRequests: [UNNotificationRequest] = []
    @Published var nextView: NextView? = nil
    // @Published var nextView: NextView? = NextView(type: .activities, id: "8ECCCE35-1DBE-4730-B8DC-3E7CBCFEE00A")

    override init() {
        super.init()
        notificationCenter.delegate = self
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

    func scheduleCalendarNotification(id: String, type: MainAppItems, identifier: String, title: String, body: String, dateComponents: DateComponents, repeats: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["id": id, "view_type": type.rawValue]

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

        let isWorkoutPlan = activityOrWorkout is WorkoutPlan
        for components in activityOrWorkout.notifications {
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute

            await scheduleCalendarNotification(
                id: activityOrWorkout.id.uuidString,
                type: isWorkoutPlan ? .workout_plans : .activities,
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

extension LocalNotificationManager: UNUserNotificationCenterDelegate {
    // Delegate function
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification) async -> UNNotificationPresentationOptions {
        await getPendingRequests()
        return [.sound, .banner]
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let id = response.notification.request.content.userInfo["id"] as? String else {
            print("no id in notification delegate")
            return
        }

        guard let view_type = response.notification.request.content.userInfo["view_type"] as? String else {
            print("no view_type in notification delegate")
            return
        }

        nextView = NextView(type: MainAppItems(rawValue: view_type) ?? .activities, id: id)
    }
}

struct NextView: Identifiable {
    let type: MainAppItems
    let id: String
}

protocol CommonProps {
    var id: UUID { get }
    var name: String { get }
    var notifications: [DateComponents] { get }
    var notificationText: NotificationTextData { get }
}

extension Activity: CommonProps {}
extension WorkoutPlan: CommonProps {}
