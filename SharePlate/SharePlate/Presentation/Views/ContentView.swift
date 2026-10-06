import SwiftUI

struct ContentView: View {
    @State private var showEstimateSurplus = false
    @State private var todaySurplusListing: SurplusListing?
    @State private var rescueClaim: RescueClaim?
    @State private var showActiveRescue = false

    init(
        surplusListing: SurplusListing? = nil,
        rescueClaim: RescueClaim? = nil
    ) {
        _todaySurplusListing = State(
            initialValue: surplusListing
        )

        _rescueClaim = State(
            initialValue: rescueClaim
        )

        _foodBusinessID = State(
            initialValue:
                surplusListing?.foodBusinessID
                ?? UUID()
        )

#if DEBUG
        let organisation =
            DevelopmentDemo.communityOrganisation

        let repository =
            DevelopmentSurplusRepository(
                listing: surplusListing,
                claim: rescueClaim,
                organisation: organisation
            )

        _developmentRepository = State(
            initialValue: repository
        )

        _availableSurplusViewModel = State(
            initialValue:
                AvailableSurplusViewModel(
                    useCase:
                        LoadAvailableSurplusUseCase(
                            surplusRepository: repository
                        )
                )
        )

        developmentOrganisation = organisation
#endif
    }

    @State private var foodBusinessID: UUID

#if DEBUG
    @State private var showFinaliseSurplus = false
    @State private var showPickupDetails = false
    @State private var showDonationHistory = false
    @State private var showClaimSurplus = false
    @State private var showCommunityPickup = false

    @State private var selectedAvailableListing:
        SurplusListing?

    @State private var developmentRole =
        DevelopmentRole.business

    @State private var communityRefreshID =
        UUID()

    @State private var developmentRepository:
        DevelopmentSurplusRepository

    @State private var availableSurplusViewModel:
        AvailableSurplusViewModel

    private let developmentOrganisation:
        CommunityOrganisation
#endif

    var body: some View {
        NavigationStack {
            Group {
#if DEBUG
                if developmentRole == .business {
                    businessDashboard
                } else {
                    communityDashboard
                }
#else
                businessDashboard
#endif
            }

#if DEBUG
            .safeAreaInset(
                edge: .top,
                spacing: 0
            ) {
                developmentControls
            }
#endif

            // MARK: - Estimate Surplus

            .navigationDestination(
                isPresented: $showEstimateSurplus
            ) {
#if DEBUG
                EstimateSurplusDevelopmentScreen(
                    foodBusinessID: foodBusinessID,
                    repository: developmentRepository,
                    onSaved: { listing in
                        todaySurplusListing = listing
                        rescueClaim = nil
                        showEstimateSurplus = false
                    }
                )
#endif
            }

            // MARK: - Active Rescue

            .navigationDestination(
                isPresented: $showActiveRescue
            ) {
                if let listing =
                    todaySurplusListing,
                   let claim = activeClaim {

                    ActiveRescueView(
                        listing: listing,
                        claim: claim,
                        onViewPickupDetails:
                            pickupDetailsAction
                    )
                }
            }

#if DEBUG

            // MARK: - Claim Surplus

            .navigationDestination(
                isPresented: $showClaimSurplus
            ) {
                if let listing =
                    selectedAvailableListing {

                    ClaimSurplusView(
                        listing: listing,
                        organisation:
                            developmentOrganisation,
                        viewModel:
                            ClaimSurplusViewModel(
                                useCase:
                                    ClaimSurplusUseCase(
                                        surplusRepository:
                                            developmentRepository,
                                        organisationRepository:
                                            developmentRepository,
                                        claimRepository:
                                            developmentRepository
                                    )
                            ),
                        onClaimed:
                            handleSuccessfulClaim
                    )
                }
            }

            // MARK: - Community Pickup

            .navigationDestination(
                isPresented:
                    $showCommunityPickup
            ) {
                if let listing =
                    communityPickupListing,
                   let claim =
                    communityPickupClaim {

                    CommunityPickupView(
                        listing: listing,
                        claim: claim,
                        organisation:
                            developmentOrganisation
                    )
                }
            }

            // MARK: - Donation History

            .navigationDestination(
                isPresented:
                    $showDonationHistory
            ) {
                DonationHistoryView(
                    foodBusinessID:
                        foodBusinessID,
                    viewModel:
                        DonationHistoryViewModel(
                            useCase:
                                LoadDonationHistoryUseCase(
                                    donationRepository:
                                        developmentRepository,
                                    claimRepository:
                                        developmentRepository,
                                    surplusRepository:
                                        developmentRepository
                                )
                        )
                )
            }

            // MARK: - Pickup Details

            .navigationDestination(
                isPresented:
                    $showPickupDetails
            ) {
                if let listing =
                    todaySurplusListing,
                   let claim =
                    activeClaim {

                    ClaimPickupDetailsView(
                        listing: listing,
                        claim: claim,
                        viewModel:
                            CompleteDonationPickupViewModel(
                                useCase:
                                    CompleteDonationPickupUseCase(
                                        claimRepository:
                                            developmentRepository,
                                        donationRepository:
                                            developmentRepository,
                                        surplusRepository:
                                            developmentRepository
                                    )
                            ),
                        onCompleted: { _ in

                            var collectedListing =
                                listing

                            collectedListing.status =
                                .collected

                            todaySurplusListing =
                                collectedListing

                            var collectedClaim =
                                claim

                            collectedClaim.status =
                                .collected

                            rescueClaim =
                                collectedClaim

                            showPickupDetails =
                                false

                            showActiveRescue =
                                false
                        }
                    )
                }
            }

            // MARK: - Finalise Surplus

            .navigationDestination(
                isPresented:
                    $showFinaliseSurplus
            ) {
                if let listing =
                    todaySurplusListing {

                    FinaliseSurplusView(
                        listing: listing,
                        viewModel:
                            FinaliseSurplusViewModel(
                                useCase:
                                    FinaliseSurplusListingUseCase(
                                        surplusRepository:
                                            developmentRepository
                                    )
                            ),
                        onFinalised: {
                            finalisedListing in

                            todaySurplusListing =
                                finalisedListing

                            showFinaliseSurplus =
                                false
                        }
                    )
                }
            }

#endif
        }
    }

    // MARK: - Business Dashboard

    private var businessDashboard: some View {
        TodayDashboardView(
            surplusListing:
                todaySurplusListing,
            rescueClaim:
                activeClaim,
            onEstimateSurplus: {
                showEstimateSurplus = true
            },
            onFinaliseSurplus:
                finaliseAction,
            onViewActiveRescue:
                activeClaim == nil
                ? nil
                : {
                    showActiveRescue = true
                },
            onViewDonationHistory:
                donationHistoryAction
        )
    }

#if DEBUG

    // MARK: - Community Dashboard

    private var communityDashboard: some View {
        VStack(spacing: 0) {

            if let claim = communityPickupClaim,
               let listing = communityPickupListing {

                Button {
                    showCommunityPickup = true
                } label: {
                    VStack(
                        alignment: .leading,
                        spacing: 14
                    ) {

                        HStack {
                            Label(
                                "My Pickup",
                                systemImage:
                                    "shippingbox.fill"
                            )
                            .font(.headline)
                            .foregroundStyle(
                                Color.accentColor
                            )

                            Spacer()

                            Image(
                                systemName:
                                    "chevron.right"
                            )
                            .font(
                                .subheadline
                                    .weight(.semibold)
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }

                        Text(listing.title)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )

                        HStack(spacing: 8) {
                            Image(
                                systemName:
                                    "clock.fill"
                            )
                            .foregroundStyle(
                                Color.accentColor
                            )

                            Text(
                                claim.plannedPickupAt
                                    .formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    )
                            )
                            .font(
                                .subheadline
                                    .weight(.semibold)
                            )
                            .foregroundStyle(.primary)
                        }

                        HStack(spacing: 8) {
                            Image(
                                systemName:
                                    "mappin.and.ellipse"
                            )
                            .foregroundStyle(
                                Color.accentColor
                            )

                            Text(
                                listing.pickupAddress
                            )
                            .font(.subheadline)
                            .foregroundStyle(
                                .secondary
                            )
                            .lineLimit(2)
                        }

                        HStack {
                            Text("CLAIMED")
                                .font(.caption.bold())
                                .foregroundStyle(
                                    Color.accentColor
                                )
                                .padding(
                                    .horizontal,
                                    10
                                )
                                .padding(
                                    .vertical,
                                    6
                                )
                                .background(
                                    Color.accentColor
                                        .opacity(0.12),
                                    in: Capsule()
                                )

                            Spacer()

                            Text("View pickup")
                                .font(
                                    .subheadline
                                        .weight(.semibold)
                                )
                                .foregroundStyle(
                                    Color.accentColor
                                )
                        }
                    }
                    .padding(18)
                    .background(
                        Color(
                            .secondarySystemGroupedBackground
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 20
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 20
                        )
                        .stroke(
                            Color.accentColor
                                .opacity(0.18),
                            lineWidth: 1
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 10)
                }
                .buttonStyle(.plain)
            }

            AvailableSurplusView(
                viewModel:
                    availableSurplusViewModel,
                refreshID:
                    communityRefreshID,
                onSelectListing: { listing in
                    selectedAvailableListing =
                        listing

                    showClaimSurplus = true
                }
            )
        }
        .background(
            Color(.systemGroupedBackground)
        )
    }

    // MARK: - Temporary Role Switch

    private var developmentControls:
        some View {

        HStack {
            Spacer()

            Button(
                action:
                    switchDevelopmentRole
            ) {
                Label(
                    developmentRole == .business
                    ? "Community Demo"
                    : "Business Demo",
                    systemImage:
                        "arrow.triangle.2.circlepath"
                )
                .font(
                    .subheadline.weight(
                        .semibold
                    )
                )
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            Color(
                .systemGroupedBackground
            )
        )
    }

#endif

    // MARK: - Active Business Claim

    private var activeClaim:
        RescueClaim? {

        guard
            let listing =
                todaySurplusListing,
            listing.status == .claimed,
            let claim =
                rescueClaim,
            claim.status == .active,
            claim.surplusListingID ==
                listing.id
        else {
            return nil
        }

        return claim
    }

#if DEBUG

    // MARK: - Community Pickup

    private var communityPickupClaim:
        RescueClaim? {

        guard
            let claim =
                rescueClaim,
            claim.communityOrganisationID ==
                developmentOrganisation.id,
            claim.status == .active
        else {
            return nil
        }

        return claim
    }

    private var communityPickupListing:
        SurplusListing? {

        guard
            let claim =
                communityPickupClaim,
            let listing =
                todaySurplusListing,
            listing.id ==
                claim.surplusListingID
        else {
            return nil
        }

        return listing
    }

#endif

    // MARK: - Navigation Actions

    private var finaliseAction:
        (() -> Void)? {

#if DEBUG
        return {
            showFinaliseSurplus = true
        }
#else
        return nil
#endif
    }

    private var pickupDetailsAction:
        (() -> Void)? {

#if DEBUG
        return {
            showPickupDetails = true
        }
#else
        return nil
#endif
    }

    private var donationHistoryAction:
        (() -> Void)? {

#if DEBUG
        return {
            showDonationHistory = true
        }
#else
        return nil
#endif
    }

#if DEBUG

    // MARK: - Role Switching

    private func switchDevelopmentRole() {

        developmentRole =
            developmentRole == .business
            ? .community
            : .business

        selectedAvailableListing = nil

        showClaimSurplus = false
        showCommunityPickup = false
        showActiveRescue = false
        showPickupDetails = false

        communityRefreshID = UUID()
    }

    // MARK: - Successful Claim

    private func handleSuccessfulClaim(
        _ claim: RescueClaim
    ) {
        rescueClaim = claim

        Task {
            if let claimedListing =
                try? await
                    developmentRepository
                        .surplusListing(
                            id:
                                claim
                                    .surplusListingID
                        ) {

                todaySurplusListing =
                    claimedListing
            }

            communityRefreshID = UUID()

            selectedAvailableListing =
                nil

            showClaimSurplus = false

            showCommunityPickup = true
        }
    }

#endif
}

#if DEBUG

// MARK: - Development Role

private enum DevelopmentRole {
    case business
    case community
}

// MARK: - Demo Organisation

private enum DevelopmentDemo {

    static let communityOrganisation =
        CommunityOrganisation(
            organisationName:
                "Inner Sydney Food Relief",
            suburb: "Ultimo",
            isVerified: true,
            contactName: "Alex Morgan",
            contactPhone:
                "0400 123 456",
            contactEmail:
                "alex@innersydneyfoodrelief.org.au",
            serviceArea:
                "Inner Sydney",
            foodHandlingNotes:
                "Trained volunteers collect and transport donated food safely."
        )
}

// MARK: - Estimate Screen Composition

private struct
EstimateSurplusDevelopmentScreen:
    View {

    let foodBusinessID: UUID

    let repository:
        DevelopmentSurplusRepository

    let onSaved:
        (SurplusListing) -> Void

    var body: some View {

        EstimateSurplusView(
            foodBusinessID:
                foodBusinessID,
            viewModel:
                EstimateSurplusViewModel(
                    estimateSurplusUseCase:
                        EstimateSurplusUseCase(
                            surplusRepository:
                                repository
                        )
                ),
            onSaved: onSaved
        )
    }
}

// MARK: - Shared Development Repository

final class DevelopmentSurplusRepository:
    SurplusRepository,
    CommunityOrganisationRepository,
    RescueClaimRepository,
    DonationRepository {

    private var listings:
        [UUID: SurplusListing] = [:]

    private var organisations:
        [UUID: CommunityOrganisation] = [:]

    private var claims:
        [UUID: RescueClaim] = [:]

    private var pickups:
        [UUID: DonationPickup] = [:]

    init(
        listing:
            SurplusListing? = nil,
        claim:
            RescueClaim? = nil,
        pickup:
            DonationPickup? = nil,
        organisation:
            CommunityOrganisation? = nil
    ) {

        if let listing {
            listings[listing.id] =
                listing
        }

        if let claim {
            claims[claim.id] =
                claim
        }

        if let pickup {
            pickups[pickup.id] =
                pickup
        }

        if let organisation {
            organisations[
                organisation.id
            ] = organisation
        }
    }

    func saveSurplusListing(
        _ listing: SurplusListing
    ) async throws {

        listings[listing.id] =
            listing
    }

    func surplusListing(
        id: UUID
    ) async throws
        -> SurplusListing? {

        listings[id]
    }

    func surplusListings(
        forFoodBusinessID
            foodBusinessID: UUID
    ) async throws
        -> [SurplusListing] {

        listings.values.filter {
            $0.foodBusinessID ==
                foodBusinessID
        }
    }

    func availableSurplusListings(
        at date: Date
    ) async throws
        -> [SurplusListing] {

        listings.values.filter {
            $0.status == .available &&
            $0.pickupWindowEnd > date
        }
    }

    func saveCommunityOrganisation(
        _ organisation:
            CommunityOrganisation
    ) async throws {

        organisations[
            organisation.id
        ] = organisation
    }

    func communityOrganisation(
        id: UUID
    ) async throws
        -> CommunityOrganisation? {

        organisations[id]
    }

    func saveRescueClaim(
        _ claim: RescueClaim
    ) async throws {

        claims[claim.id] =
            claim
    }

    func rescueClaim(
        id: UUID
    ) async throws
        -> RescueClaim? {

        claims[id]
    }

    func rescueClaims(
        forSurplusListingID
            surplusListingID: UUID
    ) async throws
        -> [RescueClaim] {

        claims.values.filter {
            $0.surplusListingID ==
                surplusListingID
        }
    }

    func donationPickup(
        forRescueClaimID
            rescueClaimID: UUID
    ) async throws
        -> DonationPickup? {

        pickups.values.first {
            $0.rescueClaimID ==
                rescueClaimID
        }
    }

    func saveDonationPickup(
        _ pickup: DonationPickup
    ) async throws {

        pickups[pickup.id] =
            pickup
    }

    func donationPickups(
        forFoodBusinessID
            foodBusinessID: UUID
    ) async throws
        -> [DonationPickup] {

        let listingIDs = Set(
            listings.values
                .filter {
                    $0.foodBusinessID ==
                        foodBusinessID
                }
                .map(\.id)
        )

        let claimIDs = Set(
            claims.values
                .filter {
                    listingIDs.contains(
                        $0.surplusListingID
                    )
                }
                .map(\.id)
        )

        return pickups.values.filter {
            claimIDs.contains(
                $0.rescueClaimID
            )
        }
    }
}

#endif

#Preview {
    ContentView()
}
