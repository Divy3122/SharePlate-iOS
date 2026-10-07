import Foundation
import Testing
@testable import SharePlate

@MainActor
struct LoadCommunityRescueHistoryUseCaseTests {
    @Test func completedPickupForCurrentOrganisationAppearsWithRelatedData() async throws {
        let fixture = HistoryFixture()
        let entry = fixture.makeEntry(organisationID: fixture.organisationID)
        fixture.configure(entry)

        let results = try await fixture.useCase.loadHistory(
            forCommunityOrganisationID: fixture.organisationID
        )

        #expect(results == [entry.entry])
    }

    @Test func pickupForAnotherOrganisationDoesNotAppear() async throws {
        let fixture = HistoryFixture()
        let otherEntry = fixture.makeEntry(organisationID: UUID())
        fixture.donationRepository.pickupHistoryByCommunityOrganisationID[
            fixture.organisationID
        ] = [otherEntry.pickup]
        fixture.claimRepository.claims = [otherEntry.claim]
        fixture.surplusRepository.listings = [otherEntry.listing]

        let results = try await fixture.useCase.loadHistory(
            forCommunityOrganisationID: fixture.organisationID
        )

        #expect(results.isEmpty)
    }

    @Test func historyIsSortedNewestFirst() async throws {
        let fixture = HistoryFixture()
        let older = fixture.makeEntry(
            organisationID: fixture.organisationID,
            collectedAt: fixture.now.addingTimeInterval(-3_600)
        )
        let newer = fixture.makeEntry(
            organisationID: fixture.organisationID,
            collectedAt: fixture.now
        )
        fixture.configure(older, newer)

        let results = try await fixture.useCase.loadHistory(
            forCommunityOrganisationID: fixture.organisationID
        )

        #expect(results.map(\.id) == [newer.entry.id, older.entry.id])
    }

    @Test func relatedClaimAndListingAreMappedToHistoryEntry() async throws {
        let fixture = HistoryFixture()
        let expected = fixture.makeEntry(organisationID: fixture.organisationID)
        fixture.configure(expected)

        let result = try #require(
            await fixture.useCase.loadHistory(
                forCommunityOrganisationID: fixture.organisationID
            ).first
        )

        #expect(result.id == expected.entry.id)
        #expect(result.listingTitle == expected.entry.listingTitle)
        #expect(result.collectedAt == expected.entry.collectedAt)
        #expect(result.items == expected.entry.items)
        #expect(result.pickupAddress == expected.entry.pickupAddress)
    }

    @Test func missingRelatedListingProducesTypedError() async throws {
        let fixture = HistoryFixture()
        let entry = fixture.makeEntry(organisationID: fixture.organisationID)
        fixture.donationRepository.pickupHistoryByCommunityOrganisationID[
            fixture.organisationID
        ] = [entry.pickup]
        fixture.claimRepository.claims = [entry.claim]

        await #expect(throws: LoadCommunityRescueHistoryError.surplusListingMissing) {
            try await fixture.useCase.loadHistory(
                forCommunityOrganisationID: fixture.organisationID
            )
        }
    }
}

@MainActor
private final class HistoryFixture {
    let organisationID = UUID()
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let donationRepository = MockDonationRepository()
    let claimRepository = MockRescueClaimRepository()
    let surplusRepository = MockSurplusRepository()

    var useCase: LoadCommunityRescueHistoryUseCase {
        LoadCommunityRescueHistoryUseCase(
            donationRepository: donationRepository,
            claimRepository: claimRepository,
            surplusRepository: surplusRepository
        )
    }

    func configure(_ entries: HistoryTestRecord...) {
        donationRepository.pickupHistoryByCommunityOrganisationID[organisationID] =
            entries.map(\.pickup)
        claimRepository.claims = entries.map(\.claim)
        surplusRepository.listings = entries.map(\.listing)
    }

    func makeEntry(
        organisationID: UUID,
        collectedAt: Date? = nil
    ) -> HistoryTestRecord {
        let listing = SurplusListing(
            foodBusinessID: UUID(),
            title: "Bakery rescue",
            items: [
                SurplusItem(
                    foodName: "Bread",
                    quantity: 4,
                    quantityUnit: .pieces,
                    storageRequirement: .ambient
                )
            ],
            pickupAddress: "1 Local Street, Ultimo",
            pickupWindowStart: now.addingTimeInterval(-7_200),
            pickupWindowEnd: now.addingTimeInterval(-3_600),
            createdAt: now.addingTimeInterval(-10_800),
            finalisedAt: now.addingTimeInterval(-9_000),
            status: .collected
        )
        let claim = RescueClaim(
            surplusListingID: listing.id,
            communityOrganisationID: organisationID,
            claimedAt: now.addingTimeInterval(-8_000),
            plannedPickupAt: now.addingTimeInterval(-4_000),
            collectorName: "Alex",
            collectorPhone: "0400 000 000",
            status: .collected
        )
        let pickup = DonationPickup(
            rescueClaimID: claim.id,
            collectedAt: collectedAt ?? now
        )
        return HistoryTestRecord(
            pickup: pickup,
            claim: claim,
            listing: listing,
            entry: CommunityRescueHistoryEntry(
                id: pickup.id,
                listingTitle: listing.title,
                collectedAt: pickup.collectedAt,
                items: listing.items,
                pickupAddress: listing.pickupAddress
            )
        )
    }
}

private struct HistoryTestRecord {
    let pickup: DonationPickup
    let claim: RescueClaim
    let listing: SurplusListing
    let entry: CommunityRescueHistoryEntry
}
