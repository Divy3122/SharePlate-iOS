import SwiftUI

struct ContentView: View {
    @State private var showEstimateSurplus = false
    @State private var todaySurplusListing: SurplusListing?

    @State private var foodBusinessID = UUID()
#if DEBUG
    @State private var showFinaliseSurplus = false
    @State private var developmentRepository = DevelopmentSurplusRepository()
#endif

    var body: some View {
        NavigationStack {
            TodayDashboardView(
                surplusListing: todaySurplusListing,
                onEstimateSurplus: {
                    showEstimateSurplus = true
                },
                onFinaliseSurplus: finaliseAction
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
                        showEstimateSurplus = false
                    }
                )
#endif
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
