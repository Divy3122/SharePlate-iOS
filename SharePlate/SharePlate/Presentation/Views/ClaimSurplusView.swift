import SwiftUI

struct ClaimSurplusView: View {
    let listing: SurplusListing
    let organisation: CommunityOrganisation
    let onClaimed: ((RescueClaim) -> Void)?

    @State private var viewModel: ClaimSurplusViewModel

    @State private var plannedPickupAt: Date
    @State private var collectorName = ""
    @State private var collectorPhone = ""
    @State private var collectionNotes = ""

    init(
        listing: SurplusListing,
        organisation: CommunityOrganisation,
        viewModel: ClaimSurplusViewModel,
        onClaimed: ((RescueClaim) -> Void)? = nil
    ) {
        self.listing = listing
        self.organisation = organisation
        self.onClaimed = onClaimed

        _viewModel = State(
            initialValue: viewModel
        )

        let now = Date()

        let initialPickupTime = min(
            max(
                now,
                listing.pickupWindowStart
            ),
            listing.pickupWindowEnd
        )

        _plannedPickupAt = State(
            initialValue: initialPickupTime
        )
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                // MARK: - Header

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Text("Claim this surplus")
                        .font(.title2.bold())

                    Text(
                        "Check the food, pickup location and collection window before reserving it."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // MARK: - Surplus Summary

                card {
                    HStack {
                        VStack(
                            alignment: .leading,
                            spacing: 6
                        ) {
                            Text(listing.title)
                                .font(.title2.bold())

                            Label(
                                "Available",
                                systemImage:
                                    "checkmark.circle.fill"
                            )
                            .font(
                                .subheadline
                                    .weight(.semibold)
                            )
                            .foregroundStyle(.green)
                        }

                        Spacer()
                    }

                    Divider()

                    let itemCount =
                        listing.items.count

                    Text(
                        "\(itemCount) surplus food \(itemCount == 1 ? "type" : "types")"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    ForEach(listing.items) { item in
                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text(item.foodName)
                                .font(.headline)

                            Text(
                                "\(item.quantity.formatted()) \(unitDescription(item))"
                            )
                            .font(.subheadline)

                            Text(
                                storageDescription(
                                    item.storageRequirement
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - MAP BEFORE CLAIMING

                PickupMapView(
                    title: listing.title,
                    address: listing.pickupAddress
                )

                // MARK: - Pickup Details

                card {
                    heading(
                        "Collection details",
                        icon: "clock"
                    )

                    detail(
                        "Pickup address",
                        value: listing.pickupAddress
                    )

                    if let instructions =
                        listing.pickupInstructions,
                       !instructions.isEmpty {

                        detail(
                            "Pickup instructions",
                            value: instructions
                        )
                    }

                    Divider()

                    detail(
                        "Available from",
                        value:
                            listing.pickupWindowStart
                                .formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                    )

                    detail(
                        "Available until",
                        value:
                            listing.pickupWindowEnd
                                .formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                    )
                }

                // MARK: - Pickup Time

                card {
                    heading(
                        "Plan your pickup",
                        icon: "calendar.badge.clock"
                    )

                    Text(
                        "Choose when your collector plans to arrive."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    DatePicker(
                        "Pickup time",
                        selection: $plannedPickupAt,
                        in:
                            listing.pickupWindowStart
                            ...
                            listing.pickupWindowEnd,
                        displayedComponents: [
                            .date,
                            .hourAndMinute
                        ]
                    )
                }

                // MARK: - Collector

                card {
                    heading(
                        "Collector details",
                        icon: "person"
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        Text("Collector name")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField(
                            "e.g. Alex Morgan",
                            text: $collectorName
                        )
                        .textContentType(.name)
                        .padding(12)
                        .background(
                            Color(
                                .tertiarySystemGroupedBackground
                            ),
                            in: RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        Text("Phone number")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField(
                            "e.g. 0400 000 000",
                            text: $collectorPhone
                        )
                        .keyboardType(.phonePad)
                        .textContentType(
                            .telephoneNumber
                        )
                        .padding(12)
                        .background(
                            Color(
                                .tertiarySystemGroupedBackground
                            ),
                            in: RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        Text(
                            "Collection notes (optional)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        TextField(
                            "e.g. Bringing reusable crates",
                            text: $collectionNotes,
                            axis: .vertical
                        )
                        .lineLimit(2...5)
                        .padding(12)
                        .background(
                            Color(
                                .tertiarySystemGroupedBackground
                            ),
                            in: RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                    }
                }

                // MARK: - Explanation

                Label(
                    "The surplus will be reserved for your organisation after you claim it.",
                    systemImage: "info.circle"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                // MARK: - Error

                if let errorMessage =
                    viewModel.errorMessage {

                    Label(
                        errorMessage,
                        systemImage:
                            "exclamationmark.circle.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(16)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(
                        Color.red.opacity(0.08),
                        in: RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }

                // MARK: - Claim Button

                Button {
                    claimSurplus()
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(
                                systemName:
                                    "hand.raised.fill"
                            )
                        }

                        Text(
                            viewModel.isLoading
                                ? "Claiming Surplus…"
                                : "Claim Surplus"
                        )
                        .fontWeight(.semibold)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 44
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .buttonBorderShape(
                    .roundedRectangle(
                        radius: 16
                    )
                )
                .disabled(
                    viewModel.isLoading ||
                    collectorName
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty ||
                    collectorPhone
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty
                )
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(
            Color(.systemGroupedBackground)
        )
        .navigationTitle("Claim Surplus")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Claim

    private func claimSurplus() {
        let cleanName =
            collectorName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let cleanPhone =
            collectorPhone
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let cleanNotes =
            collectionNotes
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        Task {
            await viewModel.claimSurplus(
                surplusListingID:
                    listing.id,
                communityOrganisationID:
                    organisation.id,
                plannedPickupAt:
                    plannedPickupAt,
                collectorName:
                    cleanName,
                collectorPhone:
                    cleanPhone,
                collectionNotes:
                    cleanNotes.isEmpty
                        ? nil
                        : cleanNotes
            )

            if let claim =
                viewModel.claimedClaim {

                onClaimed?(claim)
            }
        }
    }

    // MARK: - Cards

    private func card<Content: View>(
        @ViewBuilder
        content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16,
            content: content
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(20)
        .background(
            Color(
                .secondarySystemGroupedBackground
            ),
            in: RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

    private func heading(
        _ title: String,
        icon: String
    ) -> some View {

        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(
                    Color.accentColor
                )
                .padding(10)
                .background(
                    Color.accentColor
                        .opacity(0.12),
                    in: Circle()
                )
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
        }
        .accessibilityAddTraits(
            .isHeader
        )
    }

    private func detail(
        _ title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(
                    .body.weight(.medium)
                )
        }
    }

    // MARK: - Domain Formatting

    private func unitDescription(
        _ item: SurplusItem
    ) -> String {

        switch item.quantityUnit {

        case .pieces:
            return item.quantity == 1
                ? "piece"
                : "pieces"

        case .portions:
            return item.quantity == 1
                ? "portion"
                : "portions"

        case .packs:
            return item.quantity == 1
                ? "pack"
                : "packs"

        case .trays:
            return item.quantity == 1
                ? "tray"
                : "trays"

        case .kilograms:
            return "kg"

        case .litres:
            return "L"
        }
    }

    private func storageDescription(
        _ storage:
            SurplusItem.StorageRequirement
    ) -> String {

        switch storage {

        case .ambient:
            return "Room temperature"

        case .refrigerated:
            return "Refrigerated"

        case .frozen:
            return "Frozen"
        }
    }
}
