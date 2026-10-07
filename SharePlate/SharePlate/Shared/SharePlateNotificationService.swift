import Foundation
import UserNotifications

final class SharePlateNotificationService: NSObject, UNUserNotificationCenterDelegate {

    static let categoryIdentifier = "SHAREPLATE_RESCUE_UPDATE"

    func prepare() async {
        let center = UNUserNotificationCenter.current()

        center.delegate = self

        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])

        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            print("SharePlate notifications granted:", granted)

        } catch {
            print(
                "Notification permission error:",
                error.localizedDescription
            )
        }
    }

    func scheduleRescueUpdate(
        eventType: String,
        listingTitle: String,
        pickupDate: Date,
        pickupAddress: String
    ) async {

        let content = UNMutableNotificationContent()

        content.title = eventType
        content.body = "\(listingTitle) • \(pickupAddress)"
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier

        content.userInfo = [
            "eventType": eventType,
            "listingTitle": listingTitle,
            "pickupDate": ISO8601DateFormatter().string(from: pickupDate),
            "pickupAddress": pickupAddress
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 2,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current()
                .add(request)

            print(
                "SharePlate notification scheduled:",
                listingTitle
            )

        } catch {
            print(
                "SharePlate notification scheduling failed:",
                error.localizedDescription
            )
        }
    }

    // Show notifications even while SharePlate is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {

        [.banner, .sound, .list]
    }
}
