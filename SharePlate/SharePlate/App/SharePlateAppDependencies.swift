import Foundation
import Observation

@MainActor
@Observable
final class SharePlateAppDependencies {
    let stack: CoreDataStack
    let repository: CoreDataSharePlateRepository
    let widgetSyncService: SharePlateWidgetSyncService
    let notificationService: SharePlateNotificationService
    let foodBusiness: FoodBusiness
    let communityOrganisation: CommunityOrganisation

    private(set) var isReady = false
    private(set) var bootstrapErrorMessage: String?

    init(stack: CoreDataStack? = nil) {
        let resolvedStack = stack ?? CoreDataStack()

        self.stack = resolvedStack

        repository = CoreDataSharePlateRepository(
            stack: resolvedStack
        )

        widgetSyncService = SharePlateWidgetSyncService(
            surplusRepository: repository,
            claimRepository: repository
        )

        notificationService = SharePlateNotificationService()

        foodBusiness = FoodBusiness(
            id: SharePlateProfileStore.foodBusinessID,
            businessName: "SharePlate Business",
            suburb: "Ultimo",
            contactName: "Business Manager",
            contactPhone: "0400 000 000",
            contactEmail: nil,
            pickupAddress: "1 Local Street, Ultimo",
            pickupInstructions: nil
        )

        communityOrganisation = CommunityOrganisation(
            id: SharePlateProfileStore.communityOrganisationID,
            organisationName: "Inner Sydney Food Relief",
            suburb: "Ultimo",
            isVerified: true,
            contactName: "Alex Morgan",
            contactPhone: "0400 123 456",
            contactEmail: "alex@innersydneyfoodrelief.org.au",
            serviceArea: "Inner Sydney",
            foodHandlingNotes: "Trained volunteers collect and transport donated food safely."
        )
    }

    func bootstrapProfiles() async {
        guard !isReady else {
            return
        }

        bootstrapErrorMessage = nil

        do {
            try await stack.load()

            try await repository.saveFoodBusiness(
                foodBusiness
            )

            try await repository.saveCommunityOrganisation(
                communityOrganisation
            )

            let persistedRole = SharePlateRole(
                rawValue: UserDefaults.standard.string(
                    forKey: "shareplate.selectedRole"
                ) ?? ""
            ) ?? .business

            await widgetSyncService.refresh(
                role: persistedRole,
                foodBusinessID: foodBusiness.id,
                communityOrganisationID: communityOrganisation.id
            )

            await notificationService.prepare()

            isReady = true

        } catch {
            bootstrapErrorMessage =
                (error as? LocalizedError)?.errorDescription
                ?? "SharePlate could not open its local data store. Please try again."
        }
    }
}
