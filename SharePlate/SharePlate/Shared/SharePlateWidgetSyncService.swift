import Foundation
import WidgetKit

struct SharePlateWidgetSyncService {
    private let surplusRepository: any SurplusRepository
    private let claimRepository: any RescueClaimRepository

    init(
        surplusRepository: any SurplusRepository,
        claimRepository: any RescueClaimRepository
    ) {
        self.surplusRepository = surplusRepository
        self.claimRepository = claimRepository
    }

    func refresh(
        role: SharePlateRole,
        foodBusinessID: UUID,
        communityOrganisationID: UUID
    ) async {
        do {
            let snapshot: SharePlateWidgetSnapshot

            switch role {
            case .business:
                snapshot = try await businessSnapshot(
                    foodBusinessID: foodBusinessID
                )

            case .community:
                snapshot = try await communitySnapshot(
                    communityOrganisationID: communityOrganisationID
                )
            }

            try SharePlateWidgetSnapshotStore.save(snapshot)

            WidgetCenter.shared.reloadTimelines(
                ofKind: SharePlateWidgetConfiguration.widgetKind
            )

        } catch {
            print("Widget sync failed: \(error)")
        }
    }

    private func businessSnapshot(
        foodBusinessID: UUID
    ) async throws -> SharePlateWidgetSnapshot {

        let listings = try await surplusRepository
            .surplusListings(
                forFoodBusinessID: foodBusinessID
            )

        let activeListings = listings.filter {
            $0.status == .estimated ||
            $0.status == .available ||
            $0.status == .claimed
        }

        let claimedListings = activeListings.filter {
            $0.status == .claimed
        }

        var nextListing: SurplusListing?
        var nextClaim: RescueClaim?

        for listing in claimedListings {
            let claims = try await claimRepository
                .rescueClaims(
                    forSurplusListingID: listing.id
                )

            guard let activeClaim = claims
                .filter({ $0.status == .active })
                .min(by: {
                    $0.plannedPickupAt < $1.plannedPickupAt
                })
            else {
                continue
            }

            if nextClaim == nil ||
                activeClaim.plannedPickupAt < nextClaim!.plannedPickupAt {

                nextClaim = activeClaim
                nextListing = listing
            }
        }

        return SharePlateWidgetSnapshot(
            role: "business",
            activeListingCount: activeListings.count,
            claimedListingCount: claimedListings.count,
            activePickupCount: 0,
            nextTitle: nextListing?.title,
            nextPickupAt: nextClaim?.plannedPickupAt,
            nextPickupAddress: nextListing?.pickupAddress,
            updatedAt: Date()
        )
    }

    private func communitySnapshot(
        communityOrganisationID: UUID
    ) async throws -> SharePlateWidgetSnapshot {

        let claims = try await claimRepository
            .rescueClaims(
                forCommunityOrganisationID: communityOrganisationID
            )

        let activeClaims = claims.filter {
            $0.status == .active
        }

        var nextListing: SurplusListing?
        var nextClaim: RescueClaim?

        for claim in activeClaims {
            guard let listing = try await surplusRepository
                .surplusListing(id: claim.surplusListingID)
            else {
                continue
            }

            if nextClaim == nil ||
                claim.plannedPickupAt < nextClaim!.plannedPickupAt {

                nextClaim = claim
                nextListing = listing
            }
        }

        return SharePlateWidgetSnapshot(
            role: "community",
            activeListingCount: 0,
            claimedListingCount: 0,
            activePickupCount: activeClaims.count,
            nextTitle: nextListing?.title,
            nextPickupAt: nextClaim?.plannedPickupAt,
            nextPickupAddress: nextListing?.pickupAddress,
            updatedAt: Date()
        )
    }
}
