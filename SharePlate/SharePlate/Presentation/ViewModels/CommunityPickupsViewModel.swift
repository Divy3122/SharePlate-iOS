import Foundation
import Observation

@MainActor
@Observable
final class CommunityPickupsViewModel {
    private let useCase: LoadCommunityPickupsUseCase

    private(set) var activities: [CommunityPickupActivity] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(useCase: LoadCommunityPickupsUseCase) {
        self.useCase = useCase
    }

    func loadPickups(communityOrganisationID: UUID) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            activities = try await useCase.loadActivePickups(
                forCommunityOrganisationID: communityOrganisationID
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Your claimed pickups could not be loaded. Please try again."
        }
    }
}
