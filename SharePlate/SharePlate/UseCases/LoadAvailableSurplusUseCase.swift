import Foundation

struct LoadAvailableSurplusUseCase {
    private let surplusRepository: any SurplusRepository
    private let currentDate: () -> Date

    init(
        surplusRepository: any SurplusRepository,
        currentDate: @escaping () -> Date = { Date() }
    ) {
        self.surplusRepository = surplusRepository
        self.currentDate = currentDate
    }

    func loadAvailableSurplus() async throws -> [SurplusListing] {
        try await surplusRepository
            .availableSurplusListings(at: currentDate())
            .sorted {
                if $0.pickupWindowEnd == $1.pickupWindowEnd {
                    return $0.pickupWindowStart < $1.pickupWindowStart
                }
                return $0.pickupWindowEnd < $1.pickupWindowEnd
            }
    }
}
