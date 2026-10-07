import Foundation
import Observation

@MainActor
@Observable
final class ClaimSurplusViewModel {

    private let useCase:
        ClaimSurplusUseCase

    var claimedClaim:
        RescueClaim?

    var isLoading = false

    var errorMessage:
        String?

    init(
        useCase:
            ClaimSurplusUseCase
    ) {
        self.useCase =
            useCase
    }

    func claimSurplus(
        surplusListingID: UUID,
        communityOrganisationID: UUID,
        plannedPickupAt: Date,
        collectorName: String,
        collectorPhone: String,
        collectionNotes: String?
    ) async {

        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil
        claimedClaim = nil

        defer {
            isLoading = false
        }

        do {
            claimedClaim =
                try await useCase
                    .claimSurplus(
                        surplusListingID:
                            surplusListingID,
                        communityOrganisationID:
                            communityOrganisationID,
                        plannedPickupAt:
                            plannedPickupAt,
                        collectorName:
                            collectorName,
                        collectorPhone:
                            collectorPhone,
                        collectionNotes:
                            collectionNotes
                    )

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }
}
