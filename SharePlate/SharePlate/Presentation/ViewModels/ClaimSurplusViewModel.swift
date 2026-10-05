import Foundation
import Observation

@MainActor
@Observable
final class ClaimSurplusViewModel {
    private let useCase: ClaimSurplusUseCase

    var plannedPickupAt: Date
    var collectorName = ""
    var collectorPhone = ""
    var collectionNotes: String?

    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var createdClaim: RescueClaim?

    init(useCase: ClaimSurplusUseCase, plannedPickupAt: Date = Date()) {
        self.useCase = useCase
        self.plannedPickupAt = plannedPickupAt
    }

    func claimSurplus(listingID: UUID, organisationID: UUID) async {
        guard !isLoading else { return }
        errorMessage = nil
        createdClaim = nil
        isLoading = true
        defer { isLoading = false }

        do {
            createdClaim = try await useCase.claimSurplus(
                surplusListingID: listingID,
                communityOrganisationID: organisationID,
                plannedPickupAt: plannedPickupAt,
                collectorName: collectorName,
                collectorPhone: collectorPhone,
                collectionNotes: collectionNotes
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "We could not confirm your food claim. Refresh your claims to check whether it was recorded."
        }
    }
}
