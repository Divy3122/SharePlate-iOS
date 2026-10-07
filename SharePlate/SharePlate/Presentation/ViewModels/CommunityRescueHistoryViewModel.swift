import Foundation
import Observation

@MainActor
@Observable
final class CommunityRescueHistoryViewModel {
    private let useCase: LoadCommunityRescueHistoryUseCase

    private(set) var historyEntries: [CommunityRescueHistoryEntry] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(useCase: LoadCommunityRescueHistoryUseCase) {
        self.useCase = useCase
    }

    func loadHistory(communityOrganisationID: UUID) async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            historyEntries = try await useCase.loadHistory(
                forCommunityOrganisationID: communityOrganisationID
            )
        } catch {
            historyEntries = []
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Your completed rescues could not be loaded. Please try again."
        }
    }
}
