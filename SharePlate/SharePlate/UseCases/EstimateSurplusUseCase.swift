//
//  EstimateSurplusUseCase.swift
//  SharePlate
//
//  Created by Divy Patel on 5/10/2026.
//

import Foundation

struct EstimateSurplusUseCase {
    private let surplusRepository: any SurplusRepository
    private let currentDate: () -> Date

    init(
        surplusRepository: any SurplusRepository,
        currentDate: @escaping () -> Date = { Date() }
    ) {
        self.surplusRepository = surplusRepository
        self.currentDate = currentDate
    }

    func estimateSurplus(
        foodBusinessID: UUID,
        title: String,
        items: [SurplusItem],
        pickupAddress: String,
        pickupInstructions: String?,
        pickupWindowStart: Date,
        pickupWindowEnd: Date
    ) async throws -> SurplusListing {

        guard !items.isEmpty else {
            throw EstimateSurplusError.noSurplusItems
        }

        for item in items {
            guard item.quantity > 0 else {
                throw EstimateSurplusError.invalidQuantity(foodName: item.foodName)
            }
        }

        guard pickupWindowStart < pickupWindowEnd else {
            throw EstimateSurplusError.invalidPickupWindow
        }

        guard pickupWindowEnd > currentDate() else {
            throw EstimateSurplusError.pickupWindowHasEnded
        }

        let listing = SurplusListing(
            foodBusinessID: foodBusinessID,
            title: title,
            items: items,
            pickupAddress: pickupAddress,
            pickupInstructions: pickupInstructions,
            pickupWindowStart: pickupWindowStart,
            pickupWindowEnd: pickupWindowEnd,
            createdAt: currentDate(),
            finalisedAt: nil,
            status: .estimated
        )

        try await surplusRepository.saveSurplusListing(listing)

        return listing
    }
}

enum EstimateSurplusError: LocalizedError, Equatable {
    case noSurplusItems
    case invalidQuantity(foodName: String)
    case invalidPickupWindow
    case pickupWindowHasEnded

    var errorDescription: String? {
        switch self {
        case .noSurplusItems:
            return "Add at least one surplus food item before saving your estimate."

        case .invalidQuantity(let foodName):
            return "Enter a quantity greater than zero for \(foodName)."

        case .invalidPickupWindow:
            return "The pickup window must start before it ends."

        case .pickupWindowHasEnded:
            return "Choose a pickup window that has not already ended."
        }
    }
}
