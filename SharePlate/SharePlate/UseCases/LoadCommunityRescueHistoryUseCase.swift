import Foundation

struct LoadCommunityRescueHistoryUseCase {
    private let donationRepository: any DonationRepository
    private let claimRepository: any RescueClaimRepository
    private let surplusRepository: any SurplusRepository

    init(
        donationRepository: any DonationRepository,
        claimRepository: any RescueClaimRepository,
        surplusRepository: any SurplusRepository
    ) {
        self.donationRepository = donationRepository
        self.claimRepository = claimRepository
        self.surplusRepository = surplusRepository
    }

    func loadHistory(
        forCommunityOrganisationID communityOrganisationID: UUID
    ) async throws -> [CommunityRescueHistoryEntry] {
        let pickups: [DonationPickup]
        do {
            pickups = try await donationRepository.donationPickups(
                forCommunityOrganisationID: communityOrganisationID
            )
        } catch {
            throw LoadCommunityRescueHistoryError.unableToLoadPickups
        }

        var entries: [CommunityRescueHistoryEntry] = []
        for pickup in pickups {
            let claim: RescueClaim
            do {
                guard let loadedClaim = try await claimRepository.rescueClaim(
                    id: pickup.rescueClaimID
                ) else {
                    throw LoadCommunityRescueHistoryError.rescueClaimMissing
                }
                claim = loadedClaim
            } catch let error as LoadCommunityRescueHistoryError {
                throw error
            } catch {
                throw LoadCommunityRescueHistoryError.unableToLoadClaim
            }

            guard claim.communityOrganisationID == communityOrganisationID else {
                continue
            }

            let listing: SurplusListing
            do {
                guard let loadedListing = try await surplusRepository.surplusListing(
                    id: claim.surplusListingID
                ) else {
                    throw LoadCommunityRescueHistoryError.surplusListingMissing
                }
                listing = loadedListing
            } catch let error as LoadCommunityRescueHistoryError {
                throw error
            } catch {
                throw LoadCommunityRescueHistoryError.unableToLoadSurplus
            }

            entries.append(
                CommunityRescueHistoryEntry(
                    id: pickup.id,
                    listingTitle: listing.title,
                    collectedAt: pickup.collectedAt,
                    items: listing.items,
                    pickupAddress: listing.pickupAddress
                )
            )
        }

        return entries.sorted { $0.collectedAt > $1.collectedAt }
    }
}

enum LoadCommunityRescueHistoryError: LocalizedError, Equatable {
    case unableToLoadPickups
    case unableToLoadClaim
    case rescueClaimMissing
    case unableToLoadSurplus
    case surplusListingMissing

    var errorDescription: String? {
        switch self {
        case .unableToLoadPickups:
            return "Your completed rescues could not be loaded. Please try again."
        case .unableToLoadClaim:
            return "Claim details for a completed rescue could not be loaded. Please try again."
        case .rescueClaimMissing:
            return "A completed rescue is missing its claim details."
        case .unableToLoadSurplus:
            return "Surplus details for a completed rescue could not be loaded. Please try again."
        case .surplusListingMissing:
            return "A completed rescue is missing its surplus details."
        }
    }
}
