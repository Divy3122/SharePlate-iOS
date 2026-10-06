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

    init(
        useCase: ClaimSurplusUseCase,
        plannedPickupAt: Date? = nil
    ) {
        self.useCase = useCase
        self.plannedPickupAt = plannedPickupAt ?? Self.nextAvailableMinute()
    }

    func claimSurplus(
        listingID: UUID,
        organisationID: UUID
    ) async {
        guard !isLoading else { return }

        errorMessage = nil
        createdClaim = nil
        isLoading = true

        defer {
            isLoading = false
        }

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
            errorMessage =
                (error as? LocalizedError)?.errorDescription
                ?? "We could not confirm your food claim. Refresh your claims to check whether it was recorded."
        }
    }

    private static func nextAvailableMinute() -> Date {
        let now = Date()
        let calendar = Calendar.current

        let startOfMinute = calendar.date(
            bySetting: .second,
            value: 0,
            of: now
        ) ?? now

        return calendar.date(
            byAdding: .minute,
            value: 1,
            to: startOfMinute
        ) ?? now.addingTimeInterval(60)
    }
}
