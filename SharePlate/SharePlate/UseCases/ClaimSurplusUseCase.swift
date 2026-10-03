import Foundation

struct ClaimSurplusUseCase {
    private let surplusRepository: any SurplusRepository
    private let organisationRepository: any CommunityOrganisationRepository
    private let claimRepository: any RescueClaimRepository
    private let currentDate: () -> Date

    init(
        surplusRepository: any SurplusRepository,
        organisationRepository: any CommunityOrganisationRepository,
        claimRepository: any RescueClaimRepository,
        currentDate: @escaping () -> Date = { Date() }
    ) {
        self.surplusRepository = surplusRepository
        self.organisationRepository = organisationRepository
        self.claimRepository = claimRepository
        self.currentDate = currentDate
    }

    func claimSurplus(
        surplusListingID: UUID,
        communityOrganisationID: UUID,
        plannedPickupAt: Date,
        collectorName: String,
        collectorPhone: String,
        collectionNotes: String? = nil
    ) async throws -> RescueClaim {
        guard var listing = try await surplusRepository.surplusListing(id: surplusListingID) else {
            throw ClaimSurplusError.listingNotFound
        }
        guard let organisation = try await organisationRepository.communityOrganisation(id: communityOrganisationID) else {
            throw ClaimSurplusError.organisationNotFound
        }
        guard organisation.isVerified else {
            throw ClaimSurplusError.organisationNotVerified
        }
        guard listing.status == .available else {
            throw ClaimSurplusError.surplusNotAvailable
        }
        let claims = try await claimRepository.rescueClaims(forSurplusListingID: surplusListingID)
        guard !claims.contains(where: { $0.status == .active }) else {
            throw ClaimSurplusError.surplusAlreadyClaimed
        }
        let now = currentDate()
        guard plannedPickupAt >= now else {
            throw ClaimSurplusError.pickupTimeHasPassed
        }
        guard listing.pickupWindowEnd > now else {
            throw ClaimSurplusError.pickupWindowExpired
        }
        guard plannedPickupAt >= listing.pickupWindowStart,
              plannedPickupAt <= listing.pickupWindowEnd else {
            throw ClaimSurplusError.pickupOutsideWindow
        }
        let claim = RescueClaim(
            surplusListingID: surplusListingID,
            communityOrganisationID: communityOrganisationID,
            claimedAt: now,
            plannedPickupAt: plannedPickupAt,
            collectorName: collectorName,
            collectorPhone: collectorPhone,
            collectionNotes: collectionNotes,
            status: .active
        )
        try await claimRepository.saveRescueClaim(claim)
        listing.status = .claimed
        try await surplusRepository.saveSurplusListing(listing)
        return claim
    }
}

enum ClaimSurplusError: LocalizedError, Equatable {
    case listingNotFound
    case organisationNotFound
    case organisationNotVerified
    case surplusNotAvailable
    case pickupWindowExpired
    case pickupOutsideWindow
    case surplusAlreadyClaimed
    case pickupTimeHasPassed

    var errorDescription: String? {
        switch self {
        case .listingNotFound:
            return "This surplus listing could not be found. Refresh the available food and try again."
        case .organisationNotFound:
            return "Your community organisation could not be found. Check your organisation profile."
        case .organisationNotVerified:
            return "Your community organisation must be verified before it can claim food."
        case .surplusNotAvailable:
            return "This food is no longer available to claim. Choose another surplus listing."
        case .pickupWindowExpired:
            return "The pickup window for this food has ended. Choose another surplus listing."
        case .pickupOutsideWindow:
            return "Choose a pickup time within the business's collection window."
        case .surplusAlreadyClaimed:
            return "This food already has an active claim and cannot be claimed again."
        case .pickupTimeHasPassed:
            return "This pickup time has already passed. Please pick a time that has not passed"
        }
    }
}
