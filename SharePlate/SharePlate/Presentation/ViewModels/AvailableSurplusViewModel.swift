import Foundation
import Observation

@MainActor
@Observable
final class AvailableSurplusViewModel {
    private let useCase: LoadAvailableSurplusUseCase

    private(set) var listings: [SurplusListing] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(useCase: LoadAvailableSurplusUseCase) {
        self.useCase = useCase
    }

    func loadAvailableSurplus() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            listings = try await useCase.loadAvailableSurplus()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "We could not load available surplus. Please try again."
        }
    }
}
