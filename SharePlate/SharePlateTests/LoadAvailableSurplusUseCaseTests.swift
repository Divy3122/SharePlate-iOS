import Foundation
import Testing
@testable import SharePlate

@MainActor
struct LoadAvailableSurplusUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func availableListingsLoadSuccessfully() async throws {
        let repository = MockSurplusRepository()
        let availableListing = makeListing(title: "Available food", endOffset: 3_600)
        var estimatedListing = makeListing(title: "Estimated food", endOffset: 1_800)
        estimatedListing.status = .estimated
        repository.listings = [availableListing, estimatedListing]

        let listings = try await makeUseCase(repository).loadAvailableSurplus()

        #expect(listings == [availableListing])
    }

    @Test func availableListingsAreOrderedByEarliestPickupWindowEnd() async throws {
        let repository = MockSurplusRepository()
        let later = makeListing(title: "Later collection", endOffset: 7_200)
        let urgent = makeListing(title: "Urgent collection", endOffset: 1_800)
        let middle = makeListing(title: "Middle collection", endOffset: 3_600)
        repository.listings = [later, urgent, middle]

        let listings = try await makeUseCase(repository).loadAvailableSurplus()

        #expect(listings.map(\.id) == [urgent.id, middle.id, later.id])
    }

    private func makeUseCase(_ repository: MockSurplusRepository) -> LoadAvailableSurplusUseCase {
        LoadAvailableSurplusUseCase(
            surplusRepository: repository,
            currentDate: { now }
        )
    }

    private func makeListing(title: String, endOffset: TimeInterval) -> SurplusListing {
        SurplusListing(
            foodBusinessID: UUID(),
            title: title,
            items: [
                SurplusItem(
                    foodName: "Bread",
                    quantity: 4,
                    quantityUnit: .pieces,
                    storageRequirement: .ambient
                )
            ],
            pickupAddress: "1 Test Street, Ultimo",
            pickupWindowStart: now.addingTimeInterval(600),
            pickupWindowEnd: now.addingTimeInterval(endOffset),
            createdAt: now.addingTimeInterval(-600),
            finalisedAt: now,
            status: .available
        )
    }
}
