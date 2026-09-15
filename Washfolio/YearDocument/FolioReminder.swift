import Foundation
import UserNotifications

/// Role: Year document. Evening ping to mark today. Local only.
@MainActor
enum FolioReminder {
    static let identifier = "wfo.daily.mark"
    static let hour = 21

    static func enable() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { return false }
        } catch {
            return false
        }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = "How was today?"
        content.body = "One mark. The year keeps it."
        content.sound = .default
        var parts = DateComponents()
        parts.hour = hour
        parts.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    static func disable() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
