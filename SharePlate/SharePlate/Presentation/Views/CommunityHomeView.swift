import SwiftUI

struct CommunityHomeView: View {
    let communityOrganisationID: UUID
    @State private var pickupsViewModel: CommunityPickupsViewModel
    @State private var availableSurplusViewModel: AvailableSurplusViewModel
    let refreshID: UUID
    let onSelectPickup: (CommunityPickupActivity) -> Void
    let onSelectListing: (SurplusListing) -> Void

    init(
        communityOrganisationID: UUID,
        pickupsViewModel: CommunityPickupsViewModel,
        availableSurplusViewModel: AvailableSurplusViewModel,
        refreshID: UUID,
        onSelectPickup: @escaping (CommunityPickupActivity) -> Void,
        onSelectListing: @escaping (SurplusListing) -> Void
    ) {
        self.communityOrganisationID = communityOrganisationID
        _pickupsViewModel = State(initialValue: pickupsViewModel)
        _availableSurplusViewModel = State(initialValue: availableSurplusViewModel)
        self.refreshID = refreshID
        self.onSelectPickup = onSelectPickup
        self.onSelectListing = onSelectListing
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header
                pickupsSection
                availableSurplusSection
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Community Home")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await refresh() }
        .task(id: refreshID) { await refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("SharePlate", systemImage: "leaf")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text("Rescue food for your community")
                .font(.title2.bold())
            Text("Keep track of your planned pickups and find local surplus ready to collect.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var pickupsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("My Pickups", icon: "shippingbox.fill")

            if pickupsViewModel.isLoading && pickupsViewModel.activities.isEmpty {
                card {
                    HStack(spacing: 12) {
                        ProgressView().tint(.accentColor)
                        Text("Loading your pickups…").foregroundStyle(.secondary)
                    }
                }
            } else if let errorMessage = pickupsViewModel.errorMessage,
                      pickupsViewModel.activities.isEmpty {
                card {
                    Label("Unable to load your pickups", systemImage: "exclamationmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task {
                            await pickupsViewModel.loadPickups(
                                communityOrganisationID: communityOrganisationID
                            )
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                }
            } else if pickupsViewModel.activities.isEmpty {
                card {
                    Text("No planned pickups")
                        .font(.headline)
                    Text("Surplus you claim will appear here with its collection details.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(pickupsViewModel.activities) { activity in
                    Button { onSelectPickup(activity) } label: {
                        pickupCard(activity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens pickup details")
                }
            }
        }
    }

    @ViewBuilder
    private var availableSurplusSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Available Surplus", icon: "basket.fill")

            if availableSurplusViewModel.isLoading && availableSurplusViewModel.listings.isEmpty {
                card {
                    HStack(spacing: 12) {
                        ProgressView().tint(.accentColor)
                        Text("Finding available surplus…").foregroundStyle(.secondary)
                    }
                }
            } else if let errorMessage = availableSurplusViewModel.errorMessage,
                      availableSurplusViewModel.listings.isEmpty {
                card {
                    Label("Unable to load available surplus", systemImage: "exclamationmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await availableSurplusViewModel.loadAvailableSurplus() }
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                }
            } else if availableSurplusViewModel.listings.isEmpty {
                card {
                    Text("No surplus available nearby right now")
                        .font(.headline)
                    Text("Newly finalised surplus will appear here when a local business makes food available for collection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(availableSurplusViewModel.listings) { listing in
                    Button { onSelectListing(listing) } label: {
                        listingCard(listing)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens surplus details and claim form")
                }
            }
        }
    }

    private func pickupCard(_ activity: CommunityPickupActivity) -> some View {
        card {
            HStack(alignment: .top, spacing: 14) {
                icon("shippingbox.fill")
                VStack(alignment: .leading, spacing: 5) {
                    Text("Claimed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text(activity.listing.title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            detail(
                "Planned pickup",
                value: activity.claim.plannedPickupAt.formatted(date: .abbreviated, time: .shortened),
                icon: "clock.fill"
            )
            detail("Pickup address", value: activity.listing.pickupAddress, icon: "mappin.and.ellipse")
        }
    }

    private func listingCard(_ listing: SurplusListing) -> some View {
        card {
            HStack(alignment: .top, spacing: 14) {
                icon("basket.fill")
                VStack(alignment: .leading, spacing: 5) {
                    Text("Available for Collection")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text(listing.title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            detail(
                "Surplus",
                value: "\(listing.items.count) surplus food \(listing.items.count == 1 ? "type" : "types")",
                icon: "takeoutbag.and.cup.and.straw"
            )
            detail(
                "Pickup window",
                value: "\(listing.pickupWindowStart.formatted(date: .abbreviated, time: .shortened)) – \(listing.pickupWindowEnd.formatted(date: .abbreviated, time: .shortened))",
                icon: "clock"
            )
            detail("Pickup address", value: listing.pickupAddress, icon: "mappin.and.ellipse")
        }
    }

    private func sectionHeading(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(Color.accentColor)
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.headline)
            .foregroundStyle(Color.accentColor)
            .padding(11)
            .background(Color.accentColor.opacity(0.12), in: Circle())
            .accessibilityHidden(true)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func detail(_ title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
            }
        }
    }

    private func refresh() async {
        await pickupsViewModel.loadPickups(
            communityOrganisationID: communityOrganisationID
        )
        await availableSurplusViewModel.loadAvailableSurplus()
    }
}
