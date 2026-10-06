import SwiftUI

struct ContentView: View {
    @State private var showEstimateSurplus = false
    @State private var todaySurplusListing: SurplusListing?
    @State private var rescueClaim: RescueClaim?
    @State private var showActiveRescue = false

    init(surplusListing: SurplusListing? = nil, rescueClaim: RescueClaim? = nil) {
        _todaySurplusListing = State(initialValue: surplusListing)
        _rescueClaim = State(initialValue: rescueClaim)
        _foodBusinessID = State(initialValue: surplusListing?.foodBusinessID ?? UUID())
#if DEBUG
        _developmentRepository = State(
            initialValue: DevelopmentSurplusRepository(
                listing: surplusListing,
                claim: rescueClaim
            )
        )
#endif
    }

    @State private var foodBusinessID: UUID
#if DEBUG
    @State private var showFinaliseSurplus = false
    @State private var showPickupDetails = false
    @State private var showDonationHistory = false
    @State private var developmentRepository: DevelopmentSurplusRepository
#endif

    var body: some View {
        NavigationStack {
            TodayDashboardView(
                surplusListing: todaySurplusListing,
                rescueClaim: activeClaim,
                onEstimateSurplus: {
                    showEstimateSurplus = true
                },
                onFinaliseSurplus: finaliseAction,
                onViewActiveRescue: activeClaim == nil ? nil : { showActiveRescue = true },
                onViewDonationHistory: donationHistoryAction
            )
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
            .navigationDestination(isPresented: $showActiveRescue) {
                if let listing = todaySurplusListing, let claim = activeClaim {
                    ActiveRescueView(
                        listing: listing,
                        claim: claim,
                        onViewPickupDetails: pickupDetailsAction
                    )
                }
            }
#if DEBUG
            .navigationDestination(isPresented: $showDonationHistory) {
                DonationHistoryView(
                    foodBusinessID: foodBusinessID,
                    viewModel: DonationHistoryViewModel(
                        useCase: LoadDonationHistoryUseCase(
                            donationRepository: developmentRepository,
                            claimRepository: developmentRepository,
                            surplusRepository: developmentRepository
                        )
                    )
                )
            }
            .navigationDestination(isPresented: $showPickupDetails) {
                if let listing = todaySurplusListing, let claim = activeClaim {
                    ClaimPickupDetailsView(
                        listing: listing,
                        claim: claim,
                        viewModel: CompleteDonationPickupViewModel(
                            useCase: CompleteDonationPickupUseCase(
                                claimRepository: developmentRepository,
                                donationRepository: developmentRepository,
                                surplusRepository: developmentRepository
                            )
                        ),
                        onCompleted: { _ in
                            var collectedListing = listing
                            collectedListing.status = .collected
                            todaySurplusListing = collectedListing

                            var collectedClaim = claim
                            collectedClaim.status = .collected
                            rescueClaim = collectedClaim

                            showPickupDetails = false
                            showActiveRescue = false
                        }
                    )
                }
            }
            .navigationDestination(isPresented: $showFinaliseSurplus) {
                if let listing = todaySurplusListing {
                    FinaliseSurplusView(
                        listing: listing,
                        viewModel: FinaliseSurplusViewModel(
                            useCase: FinaliseSurplusListingUseCase(surplusRepository: developmentRepository)
                        ),
                        onFinalised: { finalisedListing in
                            todaySurplusListing = finalisedListing
                            showFinaliseSurplus = false
                        }
                    )
                }
            }
#endif
        }
    }

    // Select matching display data for navigation; claim transitions remain in Use Cases.
    private var activeClaim: RescueClaim? {
        guard let listing = todaySurplusListing, listing.status == .claimed,
              let claim = rescueClaim, claim.status == .active,
              claim.surplusListingID == listing.id else { return nil }
        return claim
    }

    private var finaliseAction: (() -> Void)? {
#if DEBUG
        return { showFinaliseSurplus = true }
#else
        return nil
#endif
    }

    private var pickupDetailsAction: (() -> Void)? {
#if DEBUG
        return { showPickupDetails = true }
#else
        return nil
#endif
    }

    private var donationHistoryAction: (() -> Void)? {
#if DEBUG
        return { showDonationHistory = true }
#else
        return nil
#endif
    }
}

#if DEBUG

private struct EstimateSurplusDevelopmentScreen: View {
    let foodBusinessID: UUID
    let repository: DevelopmentSurplusRepository
    let onSaved: (SurplusListing) -> Void

    var body: some View {
        EstimateSurplusView(
            foodBusinessID: foodBusinessID,
            viewModel: EstimateSurplusViewModel(
                estimateSurplusUseCase: EstimateSurplusUseCase(
                    surplusRepository: repository
                )
            ),
            onSaved: onSaved
        )
    }
}

final class DevelopmentSurplusRepository:
    SurplusRepository,
    RescueClaimRepository,
    DonationRepository
{
    private var listings: [UUID: SurplusListing] = [:]
    private var claims: [UUID: RescueClaim] = [:]
    private var pickups: [UUID: DonationPickup] = [:]

    init(
        listing: SurplusListing? = nil,
        claim: RescueClaim? = nil,
        pickup: DonationPickup? = nil
    ) {
        if let listing {
            listings[listing.id] = listing
        }
        if let claim {
            claims[claim.id] = claim
        }
        if let pickup {
            pickups[pickup.id] = pickup
        }
    }

    func saveSurplusListing(
        _ listing: SurplusListing
    ) async throws {
        listings[listing.id] = listing
    }

    func surplusListing(
        id: UUID
    ) async throws -> SurplusListing? {
        listings[id]
    }

    func surplusListings(
        forFoodBusinessID foodBusinessID: UUID
    ) async throws -> [SurplusListing] {
        listings.values.filter {
            $0.foodBusinessID == foodBusinessID
        }
    }

    func availableSurplusListings(
        at date: Date
    ) async throws -> [SurplusListing] {
        listings.values.filter {
            $0.status == .available &&
            $0.pickupWindowEnd > date
        }
    }

    func saveRescueClaim(_ claim: RescueClaim) async throws {
        claims[claim.id] = claim
    }

    func rescueClaim(id: UUID) async throws -> RescueClaim? {
        claims[id]
    }

    func rescueClaims(forSurplusListingID surplusListingID: UUID) async throws -> [RescueClaim] {
        claims.values.filter { $0.surplusListingID == surplusListingID }
    }

    func donationPickup(forRescueClaimID rescueClaimID: UUID) async throws -> DonationPickup? {
        pickups.values.first { $0.rescueClaimID == rescueClaimID }
    }

    func saveDonationPickup(_ pickup: DonationPickup) async throws {
        pickups[pickup.id] = pickup
    }

    func donationPickups(forFoodBusinessID foodBusinessID: UUID) async throws -> [DonationPickup] {
        let listingIDs = Set(
            listings.values
                .filter { $0.foodBusinessID == foodBusinessID }
                .map(\.id)
        )
        let claimIDs = Set(
            claims.values
                .filter { listingIDs.contains($0.surplusListingID) }
                .map(\.id)
        )
        return pickups.values.filter { claimIDs.contains($0.rescueClaimID) }
    }
}

#endif

#Preview {
    ContentView()
}
