import Foundation

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

extension DailyActivity {
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