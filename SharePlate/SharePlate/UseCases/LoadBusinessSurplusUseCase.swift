//
//  LoadBusinessSurplusUseCase.swift
//  SharePlate
//
//  Created by Divy Patel on 6/10/2026.
//

import Foundation

struct LoadBusinessSurplusUseCase {
    private let surplusRepository: any SurplusRepository
    private let claimRepository: any RescueClaimRepository

    init(
        surplusRepository: any SurplusRepository,
        claimRepository: any RescueClaimRepository
    ) {
        self.surplusRepository = surplusRepository
        self.claimRepository = claimRepository
    }

    func loadActiveSurplus(
        forFoodBusinessID foodBusinessID: UUID
    ) async throws -> [BusinessSurplusActivity] {

        let listings: [SurplusListing]

        do {
            listings = try await surplusRepository
                .surplusListings(
                    forFoodBusinessID: foodBusinessID
                )
        } catch {
            throw LoadBusinessSurplusError.unableToLoadSurplus
        }

        let activeListings = listings.filter { listing in
            switch listing.status {
            case .estimated, .available, .claimed:
                true

            case .collected, .expired, .cancelled:
                false
            }
        }

        var activities: [BusinessSurplusActivity] = []

        for listing in activeListings {
            let claims: [RescueClaim]

            do {
                claims = try await claimRepository
                    .rescueClaims(
                        forSurplusListingID: listing.id
                    )
            } catch {
                throw LoadBusinessSurplusError.unableToLoadRescueClaims
            }

            let activeClaim = claims.first {
                $0.status == .active
            }

            activities.append(
                BusinessSurplusActivity(
                    listing: listing,
                    activeClaim: activeClaim
                )
            )
        }

        return activities.sorted {
            $0.listing.pickupWindowEnd <
            $1.listing.pickupWindowEnd
        }
    }
}

enum LoadBusinessSurplusError:
    LocalizedError,
    Equatable {

    case unableToLoadSurplus
    case unableToLoadRescueClaims

    var errorDescription: String? {
        switch self {
        case .unableToLoadSurplus:
            "Your active surplus could not be loaded. Please try again."

        case .unableToLoadRescueClaims:
            "Pickup information for your surplus could not be loaded. Please try again."
        }
    }
}
