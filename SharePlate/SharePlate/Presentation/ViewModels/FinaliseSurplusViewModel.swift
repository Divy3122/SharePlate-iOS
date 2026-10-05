import Foundation
import Observation

@MainActor
@Observable
final class FinaliseSurplusViewModel {
    private let useCase: FinaliseSurplusListingUseCase

    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var finalisedListing: SurplusListing?

    init(useCase: FinaliseSurplusListingUseCase) {
        self.useCase = useCase
    }

    func finaliseSurplusListing(id: UUID) async {
        guard !isLoading else { return }
        errorMessage = nil
        finalisedListing = nil
        isLoading = true
        defer { isLoading = false }

        do {
            finalisedListing = try await useCase.finaliseSurplusListing(id: id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "We could not confirm that your surplus was finalised. Refresh your listings to check its status."
        }
    }
}
