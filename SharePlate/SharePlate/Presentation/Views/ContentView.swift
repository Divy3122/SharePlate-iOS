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

    @State private var selectedCommunityPickupActivity:
        CommunityPickupActivity?

    // MARK: - Refresh Tokens

    @State private var businessRefreshID = UUID()
    @State private var communityRefreshID = UUID()

    // MARK: - Repository Composition

    private let repository:
        any SharePlateRepository

    @State private var businessDashboardViewModel:
        BusinessDashboardViewModel

    @State private var availableSurplusViewModel:
        AvailableSurplusViewModel

    @State private var communityPickupsViewModel:
        CommunityPickupsViewModel

    private let communityOrganisation:
        CommunityOrganisation

    private let businessName:
        String

    // MARK: - Init

    init(dependencies: SharePlateAppDependencies) {
        _foodBusinessID = State(
            initialValue: dependencies.foodBusiness.id
        )

        repository = dependencies.repository

        _businessDashboardViewModel = State(
            initialValue:
                BusinessDashboardViewModel(
                    useCase:
                        LoadBusinessSurplusUseCase(
                            surplusRepository:
                                dependencies.repository,
                            claimRepository:
                                dependencies.repository
                        )
                )
        )

        _availableSurplusViewModel = State(
            initialValue:
                AvailableSurplusViewModel(
                    useCase:
                        LoadAvailableSurplusUseCase(
                            surplusRepository:
                                dependencies.repository
                        )
                )
        )

        _communityPickupsViewModel = State(
            initialValue:
                CommunityPickupsViewModel(
                    useCase:
                        LoadCommunityPickupsUseCase(
                            claimRepository:
                                dependencies.repository,
                            surplusRepository:
                                dependencies.repository
                        )
                )
        )

        communityOrganisation = dependencies.communityOrganisation
        businessName = dependencies.foodBusiness.businessName
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

                EstimateSurplusCompositionScreen(
                    foodBusinessID:
                        foodBusinessID,
                    repository:
                        repository,
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
                                            repository
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
                                            repository,
                                        donationRepository:
                                            repository,
                                        surplusRepository:
                                            repository
                                    )
                            ),
                        onCompleted: { _ in

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
                                        repository,
                                    claimRepository:
                                        repository,
                                    surplusRepository:
                                        repository
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
                                            repository,
                                        organisationRepository:
                                            repository,
                                        claimRepository:
                                            repository
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

                if let activity =
                    selectedCommunityPickupActivity {

                    CommunityPickupView(
                        listing:
                            activity.listing,
                        claim:
                            activity.claim,
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
                businessName,

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

        CommunityHomeView(
            communityOrganisationID:
                communityOrganisation.id,
            pickupsViewModel:
                communityPickupsViewModel,
            availableSurplusViewModel:
                availableSurplusViewModel,
            refreshID:
                communityRefreshID,
            onSelectPickup: { activity in
                selectedCommunityPickupActivity = activity
                showCommunityPickup = true
            },
            onSelectListing: { listing in
                selectedAvailableListing = listing
                showClaimSurplus = true
            }
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

        guard let claimedListing else {
            showClaimSurplus = false
            communityRefreshID = UUID()
            return
        }

        selectedCommunityPickupActivity =
            CommunityPickupActivity(
                listing: claimedListing,
                claim: claim
            )

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

        selectedCommunityPickupActivity =
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

// MARK: - Estimate Composition

private struct
EstimateSurplusCompositionScreen:
    View {

    let foodBusinessID:
        UUID

    let repository:
        any SurplusRepository

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

#Preview {
    ContentView(dependencies: SharePlateAppDependencies())
}
