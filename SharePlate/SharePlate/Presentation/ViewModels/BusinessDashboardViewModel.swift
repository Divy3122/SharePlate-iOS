//
//  BusinessDashboardViewModel.swift
//  SharePlate
//
//  Created by Divy Patel on 6/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class BusinessDashboardViewModel {
    private let useCase: LoadBusinessSurplusUseCase

    private(set) var activities:
        [BusinessSurplusActivity] = []

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(
        useCase: LoadBusinessSurplusUseCase
    ) {
        self.useCase = useCase
    }

    func loadDashboard(
        foodBusinessID: UUID
    ) async {

        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            activities = try await useCase
                .loadActiveSurplus(
                    forFoodBusinessID:
                        foodBusinessID
                )
        } catch {
            errorMessage =
                (error as? LocalizedError)?
                    .errorDescription
                ?? "Your SharePlate activity could not be loaded."
        }
    }
}
