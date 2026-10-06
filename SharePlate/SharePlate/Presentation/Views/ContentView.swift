import SwiftUI

struct ContentView: View {

    // MARK: - Persisted App Role

    @AppStorage("shareplate.selectedRole")
    private var selectedRoleRawValue = ""

    // MARK: - Business Identity

    @State private var foodBusinessID: UUID

    // MARK: - Navigation

    @State private var showEstimateSurplus = false
    @State private var showFinaliseSurplus = false
    @State private var showActiveRescue = false
    @State private var showPickupDetails = false
    @State private var showDonationHistory = false

    @State private var showClaimSurplus = false
    @State private var showCommunityPickup = false

    // MARK: - Selected Business Activity

    @State private var selectedBusinessListing:
        SurplusListing?

    @State private var selectedBusinessClaim:
        RescueClaim?

    // MARK: - Selected Community Activity

    @State private var selectedAvailableListing:
        SurplusListing?

    @State private var communityPickupListing:
        SurplusListing?

    @State private var communityPickupClaim:
        RescueClaim?

    // MARK: - Refresh Tokens

    @State private var businessRefreshID = UUID()
    @State private var communityRefreshID = UUID()

    // MARK: - Temporary Repository Composition

    @State private var developmentRepository:
        DevelopmentSurplusRepository

    @State private var businessDashboardViewModel:
        BusinessDashboardViewModel

    @State private var availableSurplusViewModel:
        AvailableSurplusViewModel

    private let communityOrganisation:
        CommunityOrganisation

    // MARK: - Init

    init(
        surplusListing: SurplusListing? = nil,
        rescueClaim: RescueClaim? = nil
    ) {

        let businessID =
            surplusListing?.foodBusinessID
            ?? UUID()

        _foodBusinessID = State(
            initialValue: businessID
        )

        let organisation =
            SharePlateDemo.communityOrganisation

        let repository =
            DevelopmentSurplusRepository(
                listing: surplusListing,
                claim: rescueClaim,
                organisation: organisation
            )

        _developmentRepository = State(
            initialValue: repository
        )

        _businessDashboardViewModel = State(
            initialValue:
                BusinessDashboardViewModel(
                    useCase:
                        LoadBusinessSurplusUseCase(
                            surplusRepository:
                                repository,
                            claimRepository:
                                repository
                        )
                )
        )

        _availableSurplusViewModel = State(
            initialValue:
                AvailableSurplusViewModel(
                    useCase:
                        LoadAvailableSurplusUseCase(
                            surplusRepository:
                                repository
                        )
                )
        )

        _communityPickupListing = State(
            initialValue: surplusListing
        )

        _communityPickupClaim = State(
            initialValue: rescueClaim
        )

        communityOrganisation =
            organisation
    }

    // MARK: - Selected Role

    private var selectedRole:
        SharePlateRole? {

        SharePlateRole(
            rawValue:
                selectedRoleRawValue
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {

            Group {

                if let role =
                    selectedRole {

                    switch role {

                    case .business:
                        businessDashboard

                    case .community:
                        communityDashboard
                    }

                } else {

                    RoleSelectionView(
                        onSelectRole:
                            selectRole
                    )
                }
            }

            .safeAreaInset(
                edge: .top,
                spacing: 0
            ) {

                if let role =
                    selectedRole {

                    profileBar(
                        role: role
                    )
                }
            }

            // MARK: - Estimate Surplus

            .navigationDestination(
                isPresented:
                    $showEstimateSurplus
            ) {

                EstimateSurplusDevelopmentScreen(
                    foodBusinessID:
                        foodBusinessID,
                    repository:
                        developmentRepository,
                    onSaved: { _ in

                        businessRefreshID =
                            UUID()

                        communityRefreshID =
                            UUID()

                        showEstimateSurplus =
                            false
                    }
                )
            }

            // MARK: - Finalise Surplus

            .navigationDestination(
                isPresented:
                    $showFinaliseSurplus
            ) {

                if let listing =
                    selectedBusinessListing {

                    FinaliseSurplusView(
                        listing:
                            listing,
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

                            selectedBusinessListing =
                                finalisedListing

                            businessRefreshID =
                                UUID()

                            communityRefreshID =
                                UUID()

                            showFinaliseSurplus =
                                false
                        }
                    )
                }
            }

            // MARK: - Active Rescue

            .navigationDestination(
                isPresented:
                    $showActiveRescue
            ) {

                if let listing =
                    selectedBusinessListing,
                   let claim =
                    selectedBusinessClaim {

                    ActiveRescueView(
                        listing:
                            listing,
                        claim:
                            claim,
                        onViewPickupDetails: {

                            showPickupDetails =
                                true
                        }
                    )
                }
            }

            // MARK: - Pickup Completion

            .navigationDestination(
                isPresented:
                    $showPickupDetails
            ) {

                if let listing =
                    selectedBusinessListing,
                   let claim =
                    selectedBusinessClaim {

                    ClaimPickupDetailsView(
                        listing:
                            listing,
                        claim:
                            claim,
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

                            if communityPickupClaim?
                                .id ==
                                claim.id {

                                communityPickupClaim =
                                    nil

                                communityPickupListing =
                                    nil
                            }

                            selectedBusinessListing =
                                nil

                            selectedBusinessClaim =
                                nil

                            showPickupDetails =
                                false

                            showActiveRescue =
                                false

                            businessRefreshID =
                                UUID()

                            communityRefreshID =
                                UUID()
                        }
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

            // MARK: - Community Claim

            .navigationDestination(
                isPresented:
                    $showClaimSurplus
            ) {

                if let listing =
                    selectedAvailableListing {

                    ClaimSurplusView(
                        listing:
                            listing,
                        organisation:
                            communityOrganisation,
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
                        listing:
                            listing,
                        claim:
                            claim,
                        organisation:
                            communityOrganisation
                    )
                }
            }
        }
    }

    // MARK: - Business Home

    private var businessDashboard:
        some View {

        BusinessDashboardView(
            foodBusinessID:
                foodBusinessID,

            businessName:
                "SharePlate Business",

            viewModel:
                businessDashboardViewModel,

            refreshID:
                businessRefreshID,

            onCreateSurplus: {

                showEstimateSurplus =
                    true
            },

            onFinaliseSurplus: {
                listing in

                selectedBusinessListing =
                    listing

                selectedBusinessClaim =
                    nil

                showFinaliseSurplus =
                    true
            },

            onViewActiveRescue: {
                listing,
                claim in

                selectedBusinessListing =
                    listing

                selectedBusinessClaim =
                    claim

                showActiveRescue =
                    true
            },

            onViewDonationHistory: {

                showDonationHistory =
                    true
            }
        )
    }

    // MARK: - Community Home

    private var communityDashboard:
        some View {

        VStack(spacing: 0) {

            if let claim =
                communityPickupClaim,
               let listing =
                communityPickupListing,
               claim.status ==
                .active {

                communityPickupCard(
                    listing:
                        listing,
                    claim:
                        claim
                )
            }

            AvailableSurplusView(
                viewModel:
                    availableSurplusViewModel,

                refreshID:
                    communityRefreshID,

                onSelectListing: {
                    listing in

                    selectedAvailableListing =
                        listing

                    showClaimSurplus =
                        true
                }
            )
        }
        .background(
            Color(
                .systemGroupedBackground
            )
        )
    }

    // MARK: - Community Pickup Card

    private func communityPickupCard(
        listing: SurplusListing,
        claim: RescueClaim
    ) -> some View {

        Button {

            showCommunityPickup =
                true

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
                            .weight(
                                .semibold
                            )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                Text(
                    listing.title
                )
                .font(
                    .title3.bold()
                )
                .foregroundStyle(
                    .primary
                )
                .frame(
                    maxWidth:
                        .infinity,
                    alignment:
                        .leading
                )

                HStack(
                    spacing: 8
                ) {

                    Image(
                        systemName:
                            "clock.fill"
                    )
                    .foregroundStyle(
                        Color.accentColor
                    )

                    Text(
                        claim
                            .plannedPickupAt
                            .formatted(
                                date:
                                    .abbreviated,
                                time:
                                    .shortened
                            )
                    )
                    .font(
                        .subheadline
                            .weight(
                                .semibold
                            )
                    )
                    .foregroundStyle(
                        .primary
                    )
                }

                HStack(
                    spacing: 8
                ) {

                    Image(
                        systemName:
                            "mappin.and.ellipse"
                    )
                    .foregroundStyle(
                        Color.accentColor
                    )

                    Text(
                        listing
                            .pickupAddress
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .lineLimit(2)
                }

                HStack {

                    Text("CLAIMED")
                        .font(
                            .caption.bold()
                        )
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
                            Color
                                .accentColor
                                .opacity(
                                    0.12
                                ),
                            in:
                                Capsule()
                        )

                    Spacer()

                    Text(
                        "View pickup"
                    )
                    .font(
                        .subheadline
                            .weight(
                                .semibold
                            )
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
                in:
                    RoundedRectangle(
                        cornerRadius:
                            20
                    )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: 20
                )
                .stroke(
                    Color
                        .accentColor
                        .opacity(
                            0.18
                        ),
                    lineWidth: 1
                )
            }
            .padding(
                .horizontal,
                20
            )
            .padding(
                .top,
                16
            )
            .padding(
                .bottom,
                10
            )
        }
        .buttonStyle(
            .plain
        )
    }

    // MARK: - Profile Bar

    private func profileBar(
        role: SharePlateRole
    ) -> some View {

        HStack(
            spacing: 12
        ) {

            Label(
                role.title,
                systemImage:
                    role.systemImage
            )
            .font(
                .subheadline
                    .weight(
                        .semibold
                    )
            )
            .foregroundStyle(
                Color.accentColor
            )

            Spacer()

            Button(
                "Switch Profile"
            ) {

                switchProfile()
            }
            .font(
                .subheadline
                    .weight(
                        .semibold
                    )
            )
            .buttonStyle(
                .bordered
            )
            .tint(
                .accentColor
            )
        }
        .padding(
            .horizontal,
            20
        )
        .padding(
            .vertical,
            8
        )
        .background(
            Color(
                .systemGroupedBackground
            )
        )
    }

    // MARK: - Role Selection

    private func selectRole(
        _ role: SharePlateRole
    ) {

        selectedRoleRawValue =
            role.rawValue

        businessRefreshID =
            UUID()

        communityRefreshID =
            UUID()
    }

    private func switchProfile() {

        clearNavigationState()

        selectedRoleRawValue =
            ""
    }

    // MARK: - Successful Community Claim

    private func handleSuccessfulClaim(
        _ claim: RescueClaim
    ) {

        let claimedListing =
            selectedAvailableListing

        communityPickupClaim =
            claim

        communityPickupListing =
            claimedListing

        selectedAvailableListing =
            nil

        showClaimSurplus =
            false

        businessRefreshID =
            UUID()

        communityRefreshID =
            UUID()

        showCommunityPickup =
            true
    }

    // MARK: - Navigation Reset

    private func clearNavigationState() {

        selectedBusinessListing =
            nil

        selectedBusinessClaim =
            nil

        selectedAvailableListing =
            nil

        showEstimateSurplus =
            false

        showFinaliseSurplus =
            false

        showActiveRescue =
            false

        showPickupDetails =
            false

        showDonationHistory =
            false

        showClaimSurplus =
            false

        showCommunityPickup =
            false
    }
}

// MARK: - Demo Profiles

private enum SharePlateDemo {

    static let communityOrganisation =
        CommunityOrganisation(
            organisationName:
                "Inner Sydney Food Relief",
            suburb:
                "Ultimo",
            isVerified:
                true,
            contactName:
                "Alex Morgan",
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

// MARK: - Estimate Composition

private struct
EstimateSurplusDevelopmentScreen:
    View {

    let foodBusinessID:
        UUID

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

            onSaved:
                onSaved
        )
    }
}

// MARK: - Temporary In-Memory Repository

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

            listings[
                listing.id
            ] = listing
        }

        if let claim {

            claims[
                claim.id
            ] = claim
        }

        if let pickup {

            pickups[
                pickup.id
            ] = pickup
        }

        if let organisation {

            organisations[
                organisation.id
            ] = organisation
        }
    }

    // MARK: SurplusRepository

    func saveSurplusListing(
        _ listing:
            SurplusListing
    ) async throws {

        listings[
            listing.id
        ] = listing
    }

    func surplusListing(
        id: UUID
    ) async throws
        -> SurplusListing? {

        listings[id]
    }

    func surplusListings(
        forFoodBusinessID
            foodBusinessID:
                UUID
    ) async throws
        -> [SurplusListing] {

        listings.values
            .filter {

                $0.foodBusinessID ==
                    foodBusinessID
            }
    }

    func availableSurplusListings(
        at date: Date
    ) async throws
        -> [SurplusListing] {

        listings.values
            .filter {

                $0.status ==
                    .available
                &&
                $0.pickupWindowEnd >
                    date
            }
    }

    // MARK: CommunityOrganisationRepository

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

    // MARK: RescueClaimRepository

    func saveRescueClaim(
        _ claim:
            RescueClaim
    ) async throws {

        claims[
            claim.id
        ] = claim
    }

    func rescueClaim(
        id: UUID
    ) async throws
        -> RescueClaim? {

        claims[id]
    }

    func rescueClaims(
        forSurplusListingID
            surplusListingID:
                UUID
    ) async throws
        -> [RescueClaim] {

        claims.values
            .filter {

                $0.surplusListingID ==
                    surplusListingID
            }
    }

    // MARK: DonationRepository

    func donationPickup(
        forRescueClaimID
            rescueClaimID:
                UUID
    ) async throws
        -> DonationPickup? {

        pickups.values
            .first {

                $0.rescueClaimID ==
                    rescueClaimID
            }
    }

    func saveDonationPickup(
        _ pickup:
            DonationPickup
    ) async throws {

        pickups[
            pickup.id
        ] = pickup
    }

    func donationPickups(
        forFoodBusinessID
            foodBusinessID:
                UUID
    ) async throws
        -> [DonationPickup] {

        let listingIDs =
            Set(
                listings.values
                    .filter {

                        $0.foodBusinessID ==
                            foodBusinessID
                    }
                    .map(\.id)
            )

        let claimIDs =
            Set(
                claims.values
                    .filter {

                        listingIDs.contains(
                            $0.surplusListingID
                        )
                    }
                    .map(\.id)
            )

        return pickups.values
            .filter {

                claimIDs.contains(
                    $0.rescueClaimID
                )
            }
    }
}

#Preview {
    ContentView()
}
