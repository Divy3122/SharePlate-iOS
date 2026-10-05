import SwiftUI

struct ContentView: View {
    @State private var showEstimateSurplus = false
    @State private var todaySurplusListing: SurplusListing?

    private let foodBusinessID = UUID()

    var body: some View {
        NavigationStack {
            TodayDashboardView(
                surplusListing: todaySurplusListing,
                onEstimateSurplus: {
                    showEstimateSurplus = true
                }
            )
            .navigationDestination(
                isPresented: $showEstimateSurplus
            ) {
#if DEBUG
                EstimateSurplusDevelopmentScreen(
                    foodBusinessID: foodBusinessID,
                    onSaved: { listing in
                        todaySurplusListing = listing
                        showEstimateSurplus = false
                    }
                )
#endif
            }
        }
    }
}

#if DEBUG

private struct EstimateSurplusDevelopmentScreen: View {
    let foodBusinessID: UUID
    let onSaved: (SurplusListing) -> Void

    var body: some View {
        EstimateSurplusView(
            foodBusinessID: foodBusinessID,
            viewModel: EstimateSurplusViewModel(
                estimateSurplusUseCase: EstimateSurplusUseCase(
                    surplusRepository: DevelopmentSurplusRepository()
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
