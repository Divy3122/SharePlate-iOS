import Foundation

struct LoadCommunityPickupsUseCase {
    private let claimRepository: any RescueClaimRepository
    private let surplusRepository: any SurplusRepository

    init(
        claimRepository: any RescueClaimRepository,
        surplusRepository: any SurplusRepository
    ) {
        self.claimRepository = claimRepository
        self.surplusRepository = surplusRepository
    }

    func loadActivePickups(
        forCommunityOrganisationID communityOrganisationID: UUID
    ) async throws -> [CommunityPickupActivity] {
        let claims: [RescueClaim]
        do {
            claims = try await claimRepository.rescueClaims(
                forCommunityOrganisationID: communityOrganisationID
            )
        } catch {
            throw LoadCommunityPickupsError.unableToLoadClaims
        }

        var activities: [CommunityPickupActivity] = []
        for claim in claims where claim.status == .active {
            let listing: SurplusListing?
            do {
                listing = try await surplusRepository.surplusListing(
                    id: claim.surplusListingID
                )
            } catch {
                throw LoadCommunityPickupsError.unableToLoadSurplus
            }
            guard let listing else {
                throw LoadCommunityPickupsError.surplusListingMissing
            }
            activities.append(CommunityPickupActivity(listing: listing, claim: claim))
        }

        return activities.sorted { $0.claim.plannedPickupAt < $1.claim.plannedPickupAt }
    }
}

enum LoadCommunityPickupsError: LocalizedError, Equatable {
    case unableToLoadClaims
    case unableToLoadSurplus
    case surplusListingMissing

    var errorDescription: String? {
        switch self {
        case .unableToLoadClaims:
            return "Your claimed pickups could not be loaded. Please try again."
        case .unableToLoadSurplus:
            return "Surplus details for your pickups could not be loaded. Please try again."
        case .surplusListingMissing:
            return "A claimed pickup is missing its surplus listing. Refresh your pickups and try again."
        }
    }
}
