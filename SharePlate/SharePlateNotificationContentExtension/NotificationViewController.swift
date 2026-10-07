import UIKit
import UserNotifications
import UserNotificationsUI

final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private enum UserInfoKey {
        static let eventType = "eventType"
        static let listingTitle = "listingTitle"
        static let pickupDate = "pickupDate"
        static let pickupAddress = "pickupAddress"
    }

    private let iconView = UIImageView()
    private let statusLabel = UILabel()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let addressLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureInterface()
    }

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        let userInfo = content.userInfo

        let eventType = stringValue(
            for: UserInfoKey.eventType,
            in: userInfo
        ) ?? content.title.nonEmpty ?? "Rescue update"

        let listingTitle = stringValue(
            for: UserInfoKey.listingTitle,
            in: userInfo
        ) ?? content.body.nonEmpty ?? "SharePlate rescue"

        let pickupAddress = stringValue(
            for: UserInfoKey.pickupAddress,
            in: userInfo
        ) ?? "Pickup location unavailable"

        statusLabel.text = eventType
        titleLabel.text = listingTitle
        dateLabel.text = pickupDateText(from: userInfo)
        addressLabel.text = pickupAddress
        iconView.image = UIImage(
            systemName: eventType.localizedCaseInsensitiveContains("completed")
                ? "checkmark.circle.fill"
                : "shippingbox.fill"
        )
    }

    private func configureInterface() {
        view.backgroundColor = .systemBackground

        let sharePlateGreen = UIColor(
            red: 0.18,
            green: 0.55,
            blue: 0.31,
            alpha: 1
        )

        iconView.image = UIImage(systemName: "leaf.fill")
        iconView.tintColor = sharePlateGreen
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 28,
            weight: .semibold
        )
        iconView.widthAnchor.constraint(equalToConstant: 42).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 42).isActive = true

        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.textColor = sharePlateGreen
        statusLabel.text = "Rescue update"

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 2
        titleLabel.text = "SharePlate rescue"

        dateLabel.font = .preferredFont(forTextStyle: .subheadline)
        dateLabel.textColor = .secondaryLabel
        dateLabel.numberOfLines = 2

        addressLabel.font = .preferredFont(forTextStyle: .subheadline)
        addressLabel.textColor = .secondaryLabel
        addressLabel.numberOfLines = 2

        let heading = UIStackView(arrangedSubviews: [iconView, statusLabel])
        heading.axis = .horizontal
        heading.alignment = .center
        heading.spacing = 12

        let dateRow = detailRow(
            symbol: "calendar.badge.clock",
            label: dateLabel,
            tint: sharePlateGreen
        )
        let addressRow = detailRow(
            symbol: "mappin.and.ellipse",
            label: addressLabel,
            tint: sharePlateGreen
        )

        let stack = UIStackView(
            arrangedSubviews: [heading, titleLabel, dateRow, addressRow]
        )
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -18)
        ])
    }

    private func detailRow(
        symbol: String,
        label: UILabel,
        tint: UIColor
    ) -> UIStackView {
        let imageView = UIImageView(image: UIImage(systemName: symbol))
        imageView.tintColor = tint
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true

        let row = UIStackView(arrangedSubviews: [imageView, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 10
        return row
    }

    private func stringValue(
        for key: String,
        in userInfo: [AnyHashable: Any]
    ) -> String? {
        (userInfo[key] as? String)?.nonEmpty
    }

    private func pickupDateText(
        from userInfo: [AnyHashable: Any]
    ) -> String {
        if let date = userInfo[UserInfoKey.pickupDate] as? Date {
            return date.formatted(date: .abbreviated, time: .shortened)
        }

        if let value = userInfo[UserInfoKey.pickupDate] as? String,
           let date = ISO8601DateFormatter().date(from: value) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }

        return "Pickup time unavailable"
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
