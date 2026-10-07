import Foundation
import Observation

@MainActor
@Observable
final class FinaliseSurplusViewModel {

    private let useCase:
        FinaliseSurplusListingUseCase

    var finalisedListing:
        SurplusListing?

    var isLoading =
        false

    var errorMessage:
        String?

    init(
        useCase:
            FinaliseSurplusListingUseCase
    ) {
        self.useCase =
            useCase
    }

    func finaliseSurplusListing(
        id: UUID,
        pickupAddress: String
    ) async {

        guard !isLoading else {
            return
        }

        isLoading =
            true

        errorMessage =
            nil

        finalisedListing =
            nil

        defer {
            isLoading =
                false
        }

        do {
            finalisedListing =
                try await useCase
                    .finaliseSurplusListing(
                        id: id,
                        pickupAddress:
                            pickupAddress
                    )

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }
}
