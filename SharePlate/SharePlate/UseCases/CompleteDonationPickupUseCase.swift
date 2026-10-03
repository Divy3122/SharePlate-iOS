import Foundation

struct CompleteDonationPickupUseCase {
    private let claimRepository: any RescueClaimRepository
    private let donationRepository: any DonationRepository
    private let surplusRepository: any SurplusRepository
    private let currentDate: () -> Date

    init(
        claimRepository: any RescueClaimRepository,
        donationRepository: any DonationRepository,
        surplusRepository: any SurplusRepository,
        currentDate: @escaping () -> Date = { Date() }
    ) {
        self.claimRepository = claimRepository
        self.donationRepository = donationRepository
        self.surplusRepository = surplusRepository
        self.currentDate = currentDate
    }

    func completeDonationPickup(
        rescueClaimID: UUID,
        handoverNotes: String? = nil
    ) async throws -> DonationPickup {
        guard var claim = try await claimRepository.rescueClaim(id: rescueClaimID) else {
            throw CompleteDonationPickupError.claimNotFound
        }
        guard try await donationRepository.donationPickup(forRescueClaimID: rescueClaimID) == nil else {
            throw CompleteDonationPickupError.pickupAlreadyCompleted
        }
        guard claim.status == .active else {
            throw CompleteDonationPickupError.claimIsNotActive
        }
        guard var listing = try await surplusRepository.surplusListing(id: claim.surplusListingID) else {
            throw CompleteDonationPickupError.listingNotFound
        }
        guard listing.status == .claimed else {
            throw CompleteDonationPickupError.surplusIsNotClaimed
        }
        let pickup = DonationPickup(
            rescueClaimID: rescueClaimID,
            collectedAt: currentDate(),
            handoverNotes: handoverNotes
        )
        try await donationRepository.saveDonationPickup(pickup)
        claim.status = .collected
        try await claimRepository.saveRescueClaim(claim)
        listing.status = .collected
        try await surplusRepository.saveSurplusListing(listing)
        return pickup
    }
}

enum CompleteDonationPickupError: LocalizedError, Equatable {
    case claimNotFound
    case claimIsNotActive
    case pickupAlreadyCompleted
    case listingNotFound
    case surplusIsNotClaimed

    var errorDescription: String? {
        switch self {
        case .claimNotFound:
            return "This rescue claim could not be found. Refresh your claims and try again."
        case .claimIsNotActive:
            return "This claim is no longer active, so its pickup cannot be completed."
        case .pickupAlreadyCompleted:
            return "Collection has already been recorded for this claim. It cannot be completed twice."
        case .listingNotFound:
            return "The surplus listing for this claim could not be found. Refresh your listings and try again."
        case .surplusIsNotClaimed:
            return "Only surplus with a claimed status can be confirmed as collected."
        }
    }
}
