import Foundation
import Observation

@MainActor
@Observable
final class CompleteDonationPickupViewModel {
    private let useCase: CompleteDonationPickupUseCase

    var handoverNotes: String?

    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var completedPickup: DonationPickup?

    init(useCase: CompleteDonationPickupUseCase) {
        self.useCase = useCase
    }

    func completeDonationPickup(rescueClaimID: UUID) async {
        guard !isLoading else { return }
        errorMessage = nil
        completedPickup = nil
        isLoading = true
        defer { isLoading = false }

        do {
            completedPickup = try await useCase.completeDonationPickup(
                rescueClaimID: rescueClaimID,
                handoverNotes: handoverNotes
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "We could not confirm that collection was recorded. Refresh the pickup details to check its status."
        }
    }
}
