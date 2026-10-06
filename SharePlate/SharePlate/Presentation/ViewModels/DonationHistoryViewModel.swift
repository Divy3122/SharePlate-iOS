import Foundation
import Observation

@MainActor
@Observable
final class DonationHistoryViewModel {
    private let useCase: LoadDonationHistoryUseCase

    private(set) var historyEntries: [DonationHistoryEntry] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(useCase: LoadDonationHistoryUseCase) {
        self.useCase = useCase
    }

    func loadDonationHistory(foodBusinessID: UUID) async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            historyEntries = try await useCase.loadDonationHistory(
                foodBusinessID: foodBusinessID
            )
        } catch {
            historyEntries = []
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "We could not load your donation history. Please try again."
        }
    }
}
