import SwiftUI

struct ClaimPickupDetailsView: View {
    let listing: SurplusListing
    let claim: RescueClaim
    let onCompleted: ((DonationPickup) -> Void)?

    @State private var viewModel: CompleteDonationPickupViewModel

    init(
        listing: SurplusListing,
        claim: RescueClaim,
        viewModel: CompleteDonationPickupViewModel,
        onCompleted: ((DonationPickup) -> Void)? = nil
    ) {
        self.listing = listing
        self.claim = claim
        self.onCompleted = onCompleted
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm the handover")
                        .font(.title2.bold())
                    Text("Only confirm collection after the surplus has been handed to the collector.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                card {
                    Label("Claimed", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Color.accentColor.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    Text("This surplus is reserved and ready for its planned collection.")
                        .font(.headline)
                }

                card {
                    heading("Collector", icon: "person")
                    detail("Collector name", value: claim.collectorName)
                    detail("Phone number", value: claim.collectorPhone)
                    if let notes = claim.collectionNotes, !notes.isEmpty {
                        detail("Collection notes", value: notes)
                    }
                }

                card {
                    heading("Pickup", icon: "clock")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Planned collection")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(claim.plannedPickupAt, format: .dateTime.hour().minute())
                            .font(.largeTitle.bold())
                        Text(
                            claim.plannedPickupAt,
                            format: .dateTime.weekday(.wide).day().month(.wide).year()
                        )
                        .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        Color.accentColor.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 16)
                    )

                    Divider()
                    detail(
                        "Pickup window",
                        value: "\(formatted(listing.pickupWindowStart)) to \(formatted(listing.pickupWindowEnd))"
                    )
                    detail("Pickup address", value: listing.pickupAddress)
                    if let instructions = listing.pickupInstructions, !instructions.isEmpty {
                        detail("Pickup instructions", value: instructions)
                    }
                }

                card {
                    heading("Surplus", icon: "basket")
                    Text(listing.title)
                        .font(.title2.bold())
                    Text(
                        "\(listing.items.count) surplus food \(listing.items.count == 1 ? "type" : "types")"
                    )
                    .foregroundStyle(.secondary)

                    ForEach(listing.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.foodName)
                                .font(.headline)
                            Text("\(item.quantity.formatted()) \(unitDescription(item))")
                            Text(storageDescription(item.storageRequirement))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                }

                card {
                    heading("Handover notes", icon: "square.and.pencil")
                    Text("Optionally record anything useful about the completed collection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextEditor(text: handoverNotes)
                        .frame(minHeight: 96)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(
                            Color(.tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .accessibilityLabel("Handover notes")
                }

                if let errorMessage = viewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Color.red.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }

                Button {
                    Task {
                        await viewModel.completeDonationPickup(rescueClaimID: claim.id)
                        if let completedPickup = viewModel.completedPickup {
                            onCompleted?(completedPickup)
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(viewModel.isLoading ? "Confirming Collection…" : "Confirm Collection")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .tint(.accentColor)
                .disabled(viewModel.isLoading)
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pickup Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private var handoverNotes: Binding<String> {
        Binding(
            get: { viewModel.handoverNotes ?? "" },
            set: { viewModel.handoverNotes = $0.isEmpty ? nil : $0 }
        )
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20)
            )
    }

    private func heading(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .padding(10)
                .background(Color.accentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private func detail(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.medium))
        }
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private func unitDescription(_ item: SurplusItem) -> String {
        switch item.quantityUnit {
        case .pieces: item.quantity == 1 ? "piece" : "pieces"
        case .portions: item.quantity == 1 ? "portion" : "portions"
        case .packs: item.quantity == 1 ? "pack" : "packs"
        case .trays: item.quantity == 1 ? "tray" : "trays"
        case .kilograms: "kg"
        case .litres: "L"
        }
    }

    private func storageDescription(_ storage: SurplusItem.StorageRequirement) -> String {
        switch storage {
        case .ambient: "Room temperature"
        case .refrigerated: "Refrigerated"
        case .frozen: "Frozen"
        }
    }
}

#if DEBUG
private struct ClaimPickupDetailsPreview: View {
    var body: some View {
        let now = Date()
        let listing = SurplusListing(
            foodBusinessID: UUID(),
            title: "Bread for the community",
            items: [
                SurplusItem(
                    foodName: "Sourdough loaves",
                    quantity: 6,
                    quantityUnit: .pieces,
                    storageRequirement: .ambient
                )
            ],
            pickupAddress: "12 Example Street, Ultimo",
            pickupInstructions: "Please use the side entrance beside the bakery.",
            pickupWindowStart: now,
            pickupWindowEnd: now.addingTimeInterval(3600),
            createdAt: now,
            finalisedAt: now,
            status: .claimed
        )
        let claim = RescueClaim(
            surplusListingID: listing.id,
            communityOrganisationID: UUID(),
            claimedAt: now,
            plannedPickupAt: now.addingTimeInterval(1800),
            collectorName: "Alex Morgan",
            collectorPhone: "0400 000 000",
            collectionNotes: "I will bring reusable crates for the bread."
        )
        let repository = DevelopmentSurplusRepository(listing: listing, claim: claim)

        NavigationStack {
            ClaimPickupDetailsView(
                listing: listing,
                claim: claim,
                viewModel: CompleteDonationPickupViewModel(
                    useCase: CompleteDonationPickupUseCase(
                        claimRepository: repository,
                        donationRepository: repository,
                        surplusRepository: repository
                    )
                )
            )
        }
    }
}

#Preview("Claim and pickup details") {
    ClaimPickupDetailsPreview()
}
#endif
