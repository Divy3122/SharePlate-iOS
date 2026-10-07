//
//  LoadBusinessSurplusUseCaseTests.swift
//  SharePlate
//
//  Created by Divy Patel on 6/10/2026.
//

import Foundation
import XCTest
@testable import SharePlate

final class LoadBusinessSurplusUseCaseTests: XCTestCase {

    func testLoadActiveSurplusReturnsOnlyActiveBusinessListings() async throws {
        let businessID = UUID()
        let now = Date()

        let estimated = makeListing(
            businessID: businessID,
            title: "Estimated bread",
            status: .estimated,
            pickupEnd: now.addingTimeInterval(3600)
        )

        let available = makeListing(
            businessID: businessID,
            title: "Available pastries",
            status: .available,
            pickupEnd: now.addingTimeInterval(7200)
        )

        let collected = makeListing(
            businessID: businessID,
            title: "Collected sandwiches",
            status: .collected,
            pickupEnd: now.addingTimeInterval(10_800)
        )

        let surplusRepository =
            BusinessDashboardSurplusRepositoryMock(
                listings: [
                    estimated,
                    available,
                    collected
                ]
            )

        let claimRepository =
            BusinessDashboardClaimRepositoryMock()

        let useCase =
            LoadBusinessSurplusUseCase(
                surplusRepository:
                    surplusRepository,
                claimRepository:
                    claimRepository
            )

        let activities =
            try await useCase.loadActiveSurplus(
                forFoodBusinessID:
                    businessID
            )

        XCTAssertEqual(
            activities.count,
            2
        )

        XCTAssertTrue(
            activities.contains {
                $0.listing.id ==
                    estimated.id
            }
        )

        XCTAssertTrue(
            activities.contains {
                $0.listing.id ==
                    available.id
            }
        )

        XCTAssertFalse(
            activities.contains {
                $0.listing.id ==
                    collected.id
            }
        )
    }

    func testLoadActiveSurplusOrdersSoonestPickupFirst() async throws {
        let businessID = UUID()
        let now = Date()

        let laterListing =
            makeListing(
                businessID: businessID,
                title: "Later pickup",
                status: .available,
                pickupEnd:
                    now.addingTimeInterval(
                        7200
                    )
            )

        let soonerListing =
            makeListing(
                businessID: businessID,
                title: "Sooner pickup",
                status: .available,
                pickupEnd:
                    now.addingTimeInterval(
                        3600
                    )
            )

        let surplusRepository =
            BusinessDashboardSurplusRepositoryMock(
                listings: [
                    laterListing,
                    soonerListing
                ]
            )

        let claimRepository =
            BusinessDashboardClaimRepositoryMock()

        let useCase =
            LoadBusinessSurplusUseCase(
                surplusRepository:
                    surplusRepository,
                claimRepository:
                    claimRepository
            )

        let activities =
            try await useCase.loadActiveSurplus(
                forFoodBusinessID:
                    businessID
            )

        XCTAssertEqual(
            activities.map {
                $0.listing.id
            },
            [
                soonerListing.id,
                laterListing.id
            ]
        )
    }

    func testClaimedListingIncludesItsActiveRescueClaim() async throws {
        let businessID = UUID()
        let organisationID = UUID()
        let now = Date()

        let listing =
            makeListing(
                businessID: businessID,
                title: "Claimed bakery surplus",
                status: .claimed,
                pickupEnd:
                    now.addingTimeInterval(
                        3600
                    )
            )

        let claim =
            RescueClaim(
                surplusListingID:
                    listing.id,
                communityOrganisationID:
                    organisationID,
                claimedAt:
                    now,
                plannedPickupAt:
                    now.addingTimeInterval(
                        1800
                    ),
                collectorName:
                    "Alex Morgan",
                collectorPhone:
                    "0400 123 456",
                status:
                    .active
            )

        let surplusRepository =
            BusinessDashboardSurplusRepositoryMock(
                listings: [listing]
            )

        let claimRepository =
            BusinessDashboardClaimRepositoryMock(
                claims: [claim]
            )

        let useCase =
            LoadBusinessSurplusUseCase(
                surplusRepository:
                    surplusRepository,
                claimRepository:
                    claimRepository
            )

        let activities =
            try await useCase.loadActiveSurplus(
                forFoodBusinessID:
                    businessID
            )

        XCTAssertEqual(
            activities.count,
            1
        )

        XCTAssertEqual(
            activities.first?
                .activeClaim?
                .id,
            claim.id
        )
    }

    // MARK: - Helpers

    private func makeListing(
        businessID: UUID,
        title: String,
        status:
            SurplusListing.Status,
        pickupEnd: Date
    ) -> SurplusListing {

        let pickupStart =
            pickupEnd
                .addingTimeInterval(
                    -1800
                )

        return SurplusListing(
            foodBusinessID:
                businessID,
            title:
                title,
            items: [
                SurplusItem(
                    foodName:
                        "Bread",
                    quantity:
                        4,
                    quantityUnit:
                        .pieces,
                    storageRequirement:
                        .ambient
                )
            ],
            pickupAddress:
                "1 Example Street",
            pickupWindowStart:
                pickupStart,
            pickupWindowEnd:
                pickupEnd,
            createdAt:
                Date(),
            status:
                status
        )
    }
}

// MARK: - Surplus Repository Mock

private final class
BusinessDashboardSurplusRepositoryMock:
    SurplusRepository {

    private var listings:
        [SurplusListing]

    init(
        listings:
            [SurplusListing] = []
    ) {
        self.listings =
            listings
    }

    func saveSurplusListing(
        _ listing:
            SurplusListing
    ) async throws {

        if let index =
            listings.firstIndex(
                where: {
                    $0.id ==
                        listing.id
                }
            ) {

            listings[index] =
                listing

        } else {

            listings.append(
                listing
            )
        }
    }

    func surplusListing(
        id: UUID
    ) async throws
        -> SurplusListing? {

        listings.first {
            $0.id == id
        }
    }

    func surplusListings(
        forFoodBusinessID
            foodBusinessID:
                UUID
    ) async throws
        -> [SurplusListing] {

        listings.filter {
            $0.foodBusinessID ==
                foodBusinessID
        }
    }

    func availableSurplusListings(
        at date: Date
    ) async throws
        -> [SurplusListing] {

        listings.filter {
            $0.status ==
                .available &&
            $0.pickupWindowEnd >
                date
        }
    }
}

// MARK: - Claim Repository Mock

private final class
BusinessDashboardClaimRepositoryMock:
    RescueClaimRepository {

    private var claims:
        [RescueClaim]

    init(
        claims:
            [RescueClaim] = []
    ) {
        self.claims =
            claims
    }

    func saveRescueClaim(
        _ claim:
            RescueClaim
    ) async throws {

        if let index =
            claims.firstIndex(
                where: {
                    $0.id ==
                        claim.id
                }
            ) {

            claims[index] =
                claim

        } else {

            claims.append(
                claim
            )
        }
    }

    func rescueClaim(
        id: UUID
    ) async throws
        -> RescueClaim? {

        claims.first {
            $0.id == id
        }
    }

    func rescueClaims(
        forSurplusListingID
            surplusListingID:
                UUID
    ) async throws
        -> [RescueClaim] {

        claims.filter {
            $0.surplusListingID ==
                surplusListingID
            }
    }

    func rescueClaims(
        forCommunityOrganisationID communityOrganisationID: UUID
    ) async throws -> [RescueClaim] {
        claims.filter { $0.communityOrganisationID == communityOrganisationID }
    }
}
