import SwiftUI

struct ContentView: View {
    @State private var showEstimateSurplus = false
    @State private var todaySurplusListing: SurplusListing?
    @State private var rescueClaim: RescueClaim?
    @State private var showActiveRescue = false

    init(surplusListing: SurplusListing? = nil, rescueClaim: RescueClaim? = nil) {
        _todaySurplusListing = State(initialValue: surplusListing)
        _rescueClaim = State(initialValue: rescueClaim)
    }

    @State private var foodBusinessID = UUID()
#if DEBUG
    @State private var showFinaliseSurplus = false
    @State private var developmentRepository = DevelopmentSurplusRepository()
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
                onViewActiveRescue: activeClaim == nil ? nil : { showActiveRescue = true }
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
                    ActiveRescueView(listing: listing, claim: claim)
                }
            }
#if DEBUG
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

private final class DevelopmentSurplusRepository: SurplusRepository {
    private var listings: [UUID: SurplusListing] = [:]

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
}

#endif

#Preview {
    ContentView()
}
