import SwiftUI
import WidgetKit

struct SharePlateWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SharePlateWidgetSnapshot
}

struct SharePlateWidgetProvider: TimelineProvider {

    func placeholder(
        in context: Context
    ) -> SharePlateWidgetEntry {

        SharePlateWidgetEntry(
            date: Date(),
            snapshot: .empty
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (SharePlateWidgetEntry) -> Void
    ) {

        let snapshot =
            SharePlateWidgetSnapshotStore.load()
            ?? .empty

        completion(
            SharePlateWidgetEntry(
                date: Date(),
                snapshot: snapshot
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<SharePlateWidgetEntry>) -> Void
    ) {
        let snapshot = SharePlateWidgetSnapshotStore.load() ?? .empty

        let entry = SharePlateWidgetEntry(
            date: Date(),
            snapshot: snapshot
        )

        let nextRefresh = Date().addingTimeInterval(15 * 60)

        completion(
            Timeline(
                entries: [entry],
                policy: .after(nextRefresh)
            )
        )
    }
}

struct SharePlateWidgetEntryView: View {

    @Environment(\.widgetFamily)
    private var family

    let entry: SharePlateWidgetEntry

    var body: some View {
        switch family {

        case .systemSmall:
            smallWidget

        case .systemMedium:
            mediumWidget

        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Label(
                "SharePlate",
                systemImage: "leaf.fill"
            )
            .font(.headline)
            .foregroundStyle(.green)

            Spacer()

            if entry.snapshot.role == "community" {

                Text(
                    "\(entry.snapshot.activePickupCount)"
                )
                .font(
                    .system(
                        size: 34,
                        weight: .bold
                    )
                )

                Text(
                    entry.snapshot.activePickupCount == 1
                    ? "active pickup"
                    : "active pickups"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

            } else {

                Text(
                    "\(entry.snapshot.activeListingCount)"
                )
                .font(
                    .system(
                        size: 34,
                        weight: .bold
                    )
                )

                Text(
                    entry.snapshot.activeListingCount == 1
                    ? "active listing"
                    : "active listings"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let pickupDate =
                entry.snapshot.nextPickupAt {

                Text(
                    pickupDate,
                    style: .relative
                )
                .font(.caption2)
                .foregroundStyle(.green)
            }
        }
        .containerBackground(
            .fill.tertiary,
            for: .widget
        )
    }

    private var mediumWidget: some View {

        HStack(
            spacing: 18
        ) {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Label(
                    "SharePlate",
                    systemImage: "leaf.fill"
                )
                .font(.headline)
                .foregroundStyle(.green)

                if entry.snapshot.role == "community" {

                    Text(
                        "\(entry.snapshot.activePickupCount) active pickup\(entry.snapshot.activePickupCount == 1 ? "" : "s")"
                    )
                    .font(.title3.bold())

                } else {

                    Text(
                        "\(entry.snapshot.activeListingCount) active listing\(entry.snapshot.activeListingCount == 1 ? "" : "s")"
                    )
                    .font(.title3.bold())

                    Text(
                        "\(entry.snapshot.claimedListingCount) claimed"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                Text("Next pickup")
                    .font(
                        .caption
                            .weight(.semibold)
                    )
                    .foregroundStyle(
                        .secondary
                    )

                if let title =
                    entry.snapshot.nextTitle {

                    Text(title)
                        .font(.headline)
                        .lineLimit(1)

                    if let date =
                        entry.snapshot
                            .nextPickupAt {

                        Text(
                            date.formatted(
                                date: .omitted,
                                time: .shortened
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    }

                    if let address =
                        entry.snapshot
                            .nextPickupAddress {

                        Text(address)
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                            .lineLimit(1)
                    }

                } else {

                    Text(
                        "Nothing scheduled"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .containerBackground(
            .fill.tertiary,
            for: .widget
        )
    }
}

struct SharePlateRescueWidget: Widget {

    static let kind =
        SharePlateWidgetConfiguration.widgetKind

    var body: some WidgetConfiguration {

        StaticConfiguration(
            kind: Self.kind,
            provider:
                SharePlateWidgetProvider()
        ) { entry in

            SharePlateWidgetEntryView(
                entry: entry
            )
        }
        .configurationDisplayName(
            "SharePlate Status"
        )
        .description(
            "See active surplus and your next SharePlate pickup."
        )
        .supportedFamilies(
            [
                .systemSmall,
                .systemMedium
            ]
        )
    }
}
