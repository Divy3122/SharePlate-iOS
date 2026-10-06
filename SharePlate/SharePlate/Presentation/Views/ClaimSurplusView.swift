import SwiftUI

struct ClaimSurplusView: View {
    let listing: SurplusListing
    let organisation: CommunityOrganisation
    let onClaimed: ((RescueClaim) -> Void)?

    @State private var viewModel: ClaimSurplusViewModel

    init(
        listing: SurplusListing,
        organisation: CommunityOrganisation,
        viewModel: ClaimSurplusViewModel,
        onClaimed: ((RescueClaim) -> Void)? = nil,
        currentDate: Date = Date()
    ) {
        self.listing = listing
        self.organisation = organisation
        self.onClaimed = onClaimed

        // Start at the next full minute so the selected pickup time
        // does not become "past" while the user fills in the form.
        let calendar = Calendar.current

        let startOfCurrentMinute = calendar.date(
            bySetting: .second,
            value: 0,
            of: currentDate
        ) ?? currentDate

        let nextMinute = calendar.date(
            byAdding: .minute,
            value: 1,
            to: startOfCurrentMinute
        ) ?? currentDate.addingTimeInterval(60)

        let initialPickupTime = min(
            max(nextMinute, listing.pickupWindowStart),
            listing.pickupWindowEnd
        )

        viewModel.plannedPickupAt = initialPickupTime

        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Introduction

                VStack(alignment: .leading, spacing: 8) {
                    Text("Arrange a community collection")
                        .font(.title2.bold())

                    Text(
                        "Review the food and tell the business who will collect it."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // MARK: - Surplus

                card {
                    heading(
                        "Surplus available",
                        icon: "basket"
                    )

                    Text(listing.title)
                        .font(.title2.bold())

                    ForEach(listing.items) { item in
                        VStack(
                            alignment: .leading,
                            spacing: 5
                        ) {
                            Text(item.foodName)
                                .font(.headline)

                            Text(
                                "\(item.quantity.formatted()) \(unitDescription(item))"
                            )

                            Text(
                                storageDescription(
                                    item.storageRequirement
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                    }
                }

                // MARK: - Collection Location

                card {
                    heading(
                        "Collection location",
                        icon: "mappin.and.ellipse"
                    )

                    detail(
                        "Pickup address",
                        value: listing.pickupAddress
                    )

                    if let instructions = listing.pickupInstructions,
                       !instructions.isEmpty {
                        detail(
                            "Pickup instructions",
                            value: instructions
                        )
                    }

                    Divider()

                    detail(
                        "Pickup window",
                        value:
                            "\(listing.pickupWindowStart.formatted(date: .abbreviated, time: .shortened)) – \(listing.pickupWindowEnd.formatted(date: .abbreviated, time: .shortened))"
                    )
                }

                // MARK: - Collector Details

                card {
                    heading(
                        "Collector details",
                        icon: "person.fill"
                    )

                    DatePicker(
                        "Planned pickup",
                        selection: $viewModel.plannedPickupAt,
                        in: listing.pickupWindowStart...listing.pickupWindowEnd
                    )
                    .datePickerStyle(.compact)
                    .tint(.accentColor)

                    Divider()

                    TextField(
                        "Collector name",
                        text: $viewModel.collectorName
                    )
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)

                    TextField(
                        "Collector phone",
                        text: $viewModel.collectorPhone
                    )
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .textFieldStyle(.roundedBorder)

                    TextField(
                        "Collection notes (optional)",
                        text: collectionNotesBinding,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                }

                // MARK: - Error

                if let errorMessage = viewModel.errorMessage {
                    Label(
                        errorMessage,
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(16)
                    .background(
                        Color.red.opacity(0.08),
                        in: RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }

                // MARK: - Claim Action

                Button {
                    Task {
                        await viewModel.claimSurplus(
                            listingID: listing.id,
                            organisationID: organisation.id
                        )

                        if let claim = viewModel.createdClaim {
                            onClaimed?(claim)
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
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
                    .roundedRectangle(radius: 16)
                )
                .tint(.accentColor)
                .disabled(viewModel.isLoading)
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

    // MARK: - Bindings

    private var collectionNotesBinding: Binding<String> {
        Binding(
            get: {
                viewModel.collectionNotes ?? ""
            },
            set: {
                viewModel.collectionNotes =
                    $0.isEmpty ? nil : $0
            }
        )
    }

    // MARK: - UI Helpers

    private func card<Content: View>(
        @ViewBuilder content: () -> Content
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
            Color(.secondarySystemGroupedBackground),
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
                    Color.accentColor.opacity(0.12),
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

    // MARK: - Domain Display Helpers

    private func unitDescription(
        _ item: SurplusItem
    ) -> String {
        switch item.quantityUnit {
        case .pieces:
            item.quantity == 1
            ? "piece"
            : "pieces"

        case .portions:
            item.quantity == 1
            ? "portion"
            : "portions"

        case .packs:
            item.quantity == 1
            ? "pack"
            : "packs"

        case .trays:
            item.quantity == 1
            ? "tray"
            : "trays"

        case .kilograms:
            "kg"

        case .litres:
            "L"
        }
    }

    private func storageDescription(
        _ requirement: SurplusItem.StorageRequirement
    ) -> String {
        switch requirement {
        case .ambient:
            "Room temperature"

        case .refrigerated:
            "Refrigerated"

        case .frozen:
            "Frozen"
        }
    }
}
