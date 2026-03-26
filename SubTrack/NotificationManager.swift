import UserNotifications
import Foundation

@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    var isAuthorized: Bool {
        get async {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Schedule
    /// Schedules a local notification 3 days before next billing date.
    /// Uses subscription ID as unique identifier — safe to call multiple times.
    func scheduleReminder(for subscription: Subscription) async {
        guard await isAuthorized else { return }

        let reminderDate = Calendar.current.date(
            byAdding: .day, value: -3, to: subscription.nextBillingDate
        ) ?? subscription.nextBillingDate

        guard reminderDate > Date() else { return }

        let lang = UserDefaults.standard.object(forKey: "st_language") as? Int ?? 0
        let content = UNMutableNotificationContent()
        content.title = lang == 0
            ? "\(subscription.name) 3天后续费"
            : "\(subscription.name) renewing in 3 days"
        content.body = lang == 0
            ? "即将扣款 \(subscription.formattedAmount())，记得确认账户余额充足。"
            : "\(subscription.formattedAmount()) will be charged. Make sure your account is funded."
        content.sound = .default

        var components = Calendar.current.dateComponents(
            [.year, .month, .day], from: reminderDate
        )
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: notificationID(for: subscription.id),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    // MARK: - Cancel
    func cancelReminder(for id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationID(for: id)])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - State check
    func isReminderScheduled(for id: UUID) async -> Bool {
        let pending = await center.pendingNotificationRequests()
        return pending.contains { $0.identifier == notificationID(for: id) }
    }

    // MARK: - Bulk reschedule (call on app launch)
    func rescheduleAll(for subscriptions: [Subscription]) async {
        guard await isAuthorized else { return }
        for sub in subscriptions where sub.status == .active {
            await scheduleReminder(for: sub)
        }
    }

    // MARK: - Private
    private func notificationID(for id: UUID) -> String {
        "subtrack_\(id.uuidString)"
    }
}
