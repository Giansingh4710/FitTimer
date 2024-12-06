import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var pendingNotifications: [NotificationItem] = []
    @Published var deliveredNotifications: [NotificationItem] = []
    
    struct NotificationItem: Identifiable {
        let id: String
        let title: String
        let body: String
        let scheduledDate: Date
        let activityId: UUID
        let activityName: String
        var isDelivered: Bool
    }
    
    func scheduleNotifications(for activity: DailyActivity) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications for this activity
        removeNotifications(for: activity)
        
        // Schedule new notifications
        for components in activity.notifications {
            let content = UNMutableNotificationContent()
            content.title = "Time for \(activity.name)!"
            content.body = "Track your progress by adding to your daily count."
            content.sound = .default
            content.badge = 1
            content.userInfo = ["activityId": activity.id.uuidString]
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let identifier = "\(activity.id)_\(components.hour ?? 0)_\(components.minute ?? 0)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
        
        refreshNotificationLists()
    }
    
    func removeNotifications(for activity: DailyActivity) {
        let center = UNUserNotificationCenter.current()
        let identifiers = activity.notifications.map { 
            "\(activity.id)_\($0.hour ?? 0)_\($0.minute ?? 0)" 
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        refreshNotificationLists()
    }
    
    func refreshNotificationLists() {
        let center = UNUserNotificationCenter.current()
        
        // Get pending notifications
        center.getPendingNotificationRequests { [weak self] requests in
            let items = requests.compactMap { request -> NotificationItem? in
                guard 
                    let trigger = request.trigger as? UNCalendarNotificationTrigger,
                    let nextTriggerDate = trigger.nextTriggerDate(),
                    let activityId = UUID(uuidString: (request.content.userInfo["activityId"] as? String) ?? "")
                else { return nil }
                
                return NotificationItem(
                    id: request.identifier,
                    title: request.content.title,
                    body: request.content.body,
                    scheduledDate: nextTriggerDate,
                    activityId: activityId,
                    activityName: request.content.title.replacingOccurrences(of: "Time for ", with: "").replacingOccurrences(of: "!", with: ""),
                    isDelivered: false
                )
            }
            
            DispatchQueue.main.async {
                self?.pendingNotifications = items.sorted { $0.scheduledDate < $1.scheduledDate }
            }
        }
        
        // Get delivered notifications
        center.getDeliveredNotifications { [weak self] notifications in
            let items = notifications.compactMap { notification -> NotificationItem? in
                guard let activityId = UUID(uuidString: (notification.request.content.userInfo["activityId"] as? String) ?? "") else { return nil }
                
                return NotificationItem(
                    id: notification.request.identifier,
                    title: notification.request.content.title,
                    body: notification.request.content.body,
                    scheduledDate: notification.date,
                    activityId: activityId,
                    activityName: notification.request.content.title.replacingOccurrences(of: "Time for ", with: "").replacingOccurrences(of: "!", with: ""),
                    isDelivered: true
                )
            }
            
            DispatchQueue.main.async {
                self?.deliveredNotifications = items.sorted { $0.scheduledDate > $1.scheduledDate }
            }
        }
    }
} 