import Foundation
import UserNotifications

public final class NotificationService {
    public static let shared = NotificationService()
    
    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            return false
        }
    }
    
    public func scheduleRecurringReminder(item: RecurringTransaction, currencySymbol: String) {
        guard item.reminderEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        let identifier = "recurring_\(item.id.uuidString)"
        
        // Remove existing notification for this item
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Bill: \(item.title)"
        content.body = "Due today: \(currencySymbol)\(String(format: "%.2f", item.amount)) (\(item.category))"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9 // 9:00 AM
        dateComponents.minute = 0
        
        switch item.frequency {
        case .monthly:
            dateComponents.day = item.dueDay
        case .weekly:
            dateComponents.weekday = 2 // Monday
        case .biweekly, .yearly:
            dateComponents.day = item.dueDay
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    public func cancelReminder(for itemId: UUID) {
        let identifier = "recurring_\(itemId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
