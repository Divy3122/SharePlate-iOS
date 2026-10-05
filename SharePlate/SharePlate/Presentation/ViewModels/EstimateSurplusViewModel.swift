//
//  EstimateSurplusViewModel.swift
//  SharePlate
//
//  Created by Divy Patel on 5/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class EstimateSurplusViewModel {
    private let estimateSurplusUseCase: EstimateSurplusUseCase

    var title = ""
    var pickupAddress = ""
    var pickupInstructions = ""

    var pickupWindowStart = Date()
    var pickupWindowEnd = Date().addingTimeInterval(3600)

    var surplusItems: [SurplusItem] = []

    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var estimatedListing: SurplusListing?

    init(estimateSurplusUseCase: EstimateSurplusUseCase) {
        self.estimateSurplusUseCase = estimateSurplusUseCase
    }

    func estimateSurplus(foodBusinessID: UUID) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        estimatedListing = nil

        defer {
            isLoading = false
        }

        do {
            estimatedListing = try await estimateSurplusUseCase.estimateSurplus(
                foodBusinessID: foodBusinessID,
                title: title,
                items: surplusItems,
                pickupAddress: pickupAddress,
                pickupInstructions: pickupInstructions.isEmpty ? nil : pickupInstructions,
                pickupWindowStart: pickupWindowStart,
                pickupWindowEnd: pickupWindowEnd
            )
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "The surplus estimate could not be saved."
        } catch {
            errorMessage = "The surplus estimate could not be saved."
        }
    }
}
