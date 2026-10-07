import CoreData
import Foundation

final class CoreDataSharePlateRepository:
    SharePlateRepository {

    private enum Entity {
        static let foodBusiness = "FoodBusinessEntity"
        static let communityOrganisation = "CommunityOrganisationEntity"
        static let surplusListing = "SurplusListingEntity"
        static let surplusItem = "SurplusItemEntity"
        static let rescueClaim = "RescueClaimEntity"
        static let donationPickup = "DonationPickupEntity"
    }

    private let context: NSManagedObjectContext

    init(stack: CoreDataStack) {
        context = stack.container.viewContext
    }

    // MARK: - FoodBusinessRepository

    func saveFoodBusiness(_ business: FoodBusiness) async throws {
        try await context.perform {
            let object = try self.upsert(Entity.foodBusiness, id: business.id)
            object.setValue(business.id, forKey: "id")
            object.setValue(business.businessName, forKey: "businessName")
            object.setValue(business.suburb, forKey: "suburb")
            object.setValue(business.contactName, forKey: "contactName")
            object.setValue(business.contactPhone, forKey: "contactPhone")
            object.setValue(business.contactEmail, forKey: "contactEmail")
            object.setValue(business.pickupAddress, forKey: "pickupAddress")
            object.setValue(business.pickupInstructions, forKey: "pickupInstructions")
            try self.saveIfNeeded()
        }
    }

    func foodBusiness(id: UUID) async throws -> FoodBusiness? {
        try await context.perform {
            guard let object = try self.fetchOne(Entity.foodBusiness, key: "id", id: id) else {
                return nil
            }
            return try self.foodBusiness(from: object)
        }
    }

    // MARK: - CommunityOrganisationRepository

    func saveCommunityOrganisation(_ organisation: CommunityOrganisation) async throws {
        try await context.perform {
            let object = try self.upsert(Entity.communityOrganisation, id: organisation.id)
            object.setValue(organisation.id, forKey: "id")
            object.setValue(organisation.organisationName, forKey: "organisationName")
            object.setValue(organisation.suburb, forKey: "suburb")
            object.setValue(organisation.isVerified, forKey: "isVerified")
            object.setValue(organisation.contactName, forKey: "contactName")
            object.setValue(organisation.contactPhone, forKey: "contactPhone")
            object.setValue(organisation.contactEmail, forKey: "contactEmail")
            object.setValue(organisation.serviceArea, forKey: "serviceArea")
            object.setValue(organisation.foodHandlingNotes, forKey: "foodHandlingNotes")
            try self.saveIfNeeded()
        }
    }

    func communityOrganisation(id: UUID) async throws -> CommunityOrganisation? {
        try await context.perform {
            guard let object = try self.fetchOne(
                Entity.communityOrganisation,
                key: "id",
                id: id
            ) else {
                return nil
            }
            return try self.communityOrganisation(from: object)
        }
    }

    // MARK: - SurplusRepository

    func saveSurplusListing(_ listing: SurplusListing) async throws {
        try await context.perform {
            guard let business = try self.fetchOne(
                Entity.foodBusiness,
                key: "id",
                id: listing.foodBusinessID
            ) else {
                throw CoreDataSharePlateRepositoryError.missingRequiredRelationship(
                    entity: Entity.surplusListing,
                    relationship: "foodBusiness"
                )
            }

            let object = try self.upsert(Entity.surplusListing, id: listing.id)
            object.setValue(listing.id, forKey: "id")
            object.setValue(listing.foodBusinessID, forKey: "foodBusinessID")
            object.setValue(listing.title, forKey: "title")
            object.setValue(listing.pickupAddress, forKey: "pickupAddress")
            object.setValue(listing.pickupInstructions, forKey: "pickupInstructions")
            object.setValue(listing.pickupWindowStart, forKey: "pickupWindowStart")
            object.setValue(listing.pickupWindowEnd, forKey: "pickupWindowEnd")
            object.setValue(listing.createdAt, forKey: "createdAt")
            object.setValue(listing.finalisedAt, forKey: "finalisedAt")
            object.setValue(listing.status.rawValue, forKey: "status")
            object.setValue(business, forKey: "foodBusiness")

            let existingItems = object.value(forKey: "items") as? Set<NSManagedObject> ?? []
            existingItems.forEach(self.context.delete)

            for (index, item) in listing.items.enumerated() {
                let itemObject = NSEntityDescription.insertNewObject(
                    forEntityName: Entity.surplusItem,
                    into: self.context
                )
                itemObject.setValue(item.id, forKey: "id")
                itemObject.setValue(item.foodName, forKey: "foodName")
                itemObject.setValue(item.foodDescription, forKey: "foodDescription")
                itemObject.setValue(NSDecimalNumber(decimal: item.quantity), forKey: "quantity")
                itemObject.setValue(item.quantityUnit.rawValue, forKey: "quantityUnit")
                itemObject.setValue(item.storageRequirement.rawValue, forKey: "storageRequirement")
                itemObject.setValue(item.allergenInformation, forKey: "allergenInformation")
                itemObject.setValue(item.useByDate, forKey: "useByDate")
                itemObject.setValue(Int32(index), forKey: "sortIndex")
                itemObject.setValue(object, forKey: "listing")
            }

            try self.saveIfNeeded()
        }
    }

    func surplusListing(id: UUID) async throws -> SurplusListing? {
        try await context.perform {
            guard let object = try self.fetchOne(Entity.surplusListing, key: "id", id: id) else {
                return nil
            }
            return try self.surplusListing(from: object)
        }
    }

    func surplusListings(forFoodBusinessID foodBusinessID: UUID) async throws -> [SurplusListing] {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.surplusListing)
            request.predicate = NSPredicate(format: "foodBusinessID == %@", foodBusinessID as NSUUID)
            request.sortDescriptors = [NSSortDescriptor(key: "pickupWindowEnd", ascending: true)]
            return try self.context.fetch(request).map(self.surplusListing(from:))
        }
    }

    func availableSurplusListings(at date: Date) async throws -> [SurplusListing] {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.surplusListing)
            request.predicate = NSPredicate(
                format: "status == %@ AND pickupWindowEnd > %@",
                SurplusListing.Status.available.rawValue,
                date as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "pickupWindowEnd", ascending: true)]
            return try self.context.fetch(request).map(self.surplusListing(from:))
        }
    }

    // MARK: - RescueClaimRepository

    func saveRescueClaim(_ claim: RescueClaim) async throws {
        try await context.perform {
            guard let listing = try self.fetchOne(
                Entity.surplusListing,
                key: "id",
                id: claim.surplusListingID
            ) else {
                throw CoreDataSharePlateRepositoryError.missingRequiredRelationship(
                    entity: Entity.rescueClaim,
                    relationship: "surplusListing"
                )
            }
            guard let organisation = try self.fetchOne(
                Entity.communityOrganisation,
                key: "id",
                id: claim.communityOrganisationID
            ) else {
                throw CoreDataSharePlateRepositoryError.missingRequiredRelationship(
                    entity: Entity.rescueClaim,
                    relationship: "communityOrganisation"
                )
            }

            let object = try self.upsert(Entity.rescueClaim, id: claim.id)
            object.setValue(claim.id, forKey: "id")
            object.setValue(claim.surplusListingID, forKey: "surplusListingID")
            object.setValue(claim.communityOrganisationID, forKey: "communityOrganisationID")
            object.setValue(claim.claimedAt, forKey: "claimedAt")
            object.setValue(claim.plannedPickupAt, forKey: "plannedPickupAt")
            object.setValue(claim.collectorName, forKey: "collectorName")
            object.setValue(claim.collectorPhone, forKey: "collectorPhone")
            object.setValue(claim.collectionNotes, forKey: "collectionNotes")
            object.setValue(claim.status.rawValue, forKey: "status")
            object.setValue(listing, forKey: "surplusListing")
            object.setValue(organisation, forKey: "communityOrganisation")
            try self.saveIfNeeded()
        }
    }

    func rescueClaim(id: UUID) async throws -> RescueClaim? {
        try await context.perform {
            guard let object = try self.fetchOne(Entity.rescueClaim, key: "id", id: id) else {
                return nil
            }
            return try self.rescueClaim(from: object)
        }
    }

    func rescueClaims(forSurplusListingID surplusListingID: UUID) async throws -> [RescueClaim] {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.rescueClaim)
            request.predicate = NSPredicate(
                format: "surplusListingID == %@",
                surplusListingID as NSUUID
            )
            request.sortDescriptors = [NSSortDescriptor(key: "claimedAt", ascending: false)]
            return try self.context.fetch(request).map(self.rescueClaim(from:))
        }
    }

    func rescueClaims(
        forCommunityOrganisationID communityOrganisationID: UUID
    ) async throws -> [RescueClaim] {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.rescueClaim)
            request.predicate = NSPredicate(
                format: "communityOrganisationID == %@",
                communityOrganisationID as NSUUID
            )
            request.sortDescriptors = [NSSortDescriptor(key: "plannedPickupAt", ascending: true)]
            return try self.context.fetch(request).map(self.rescueClaim(from:))
        }
    }

    // MARK: - DonationRepository

    func donationPickup(forRescueClaimID rescueClaimID: UUID) async throws -> DonationPickup? {
        try await context.perform {
            guard let object = try self.fetchOne(
                Entity.donationPickup,
                key: "rescueClaimID",
                id: rescueClaimID
            ) else {
                return nil
            }
            return try self.donationPickup(from: object)
        }
    }

    func saveDonationPickup(_ pickup: DonationPickup) async throws {
        try await context.perform {
            guard let claim = try self.fetchOne(
                Entity.rescueClaim,
                key: "id",
                id: pickup.rescueClaimID
            ) else {
                throw CoreDataSharePlateRepositoryError.missingRequiredRelationship(
                    entity: Entity.donationPickup,
                    relationship: "rescueClaim"
                )
            }

            let object = try self.upsert(Entity.donationPickup, id: pickup.id)
            object.setValue(pickup.id, forKey: "id")
            object.setValue(pickup.rescueClaimID, forKey: "rescueClaimID")
            object.setValue(pickup.collectedAt, forKey: "collectedAt")
            object.setValue(pickup.handoverNotes, forKey: "handoverNotes")
            object.setValue(claim, forKey: "rescueClaim")
            try self.saveIfNeeded()
        }
    }

    func donationPickups(forFoodBusinessID foodBusinessID: UUID) async throws -> [DonationPickup] {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.donationPickup)
            request.predicate = NSPredicate(
                format: "rescueClaim.surplusListing.foodBusiness.id == %@",
                foodBusinessID as NSUUID
            )
            request.sortDescriptors = [NSSortDescriptor(key: "collectedAt", ascending: false)]
            return try self.context.fetch(request).map(self.donationPickup(from:))
        }
    }

    func donationPickups(
        forCommunityOrganisationID communityOrganisationID: UUID
    ) async throws -> [DonationPickup] {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.donationPickup)
            request.predicate = NSPredicate(
                format: "rescueClaim.communityOrganisation.id == %@",
                communityOrganisationID as NSUUID
            )
            request.sortDescriptors = [NSSortDescriptor(key: "collectedAt", ascending: false)]
            return try self.context.fetch(request).map(self.donationPickup(from:))
        }
    }

    // MARK: - Fetch and Save Helpers

    private func fetchOne(
        _ entityName: String,
        key: String,
        id: UUID
    ) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K == %@", key, id as NSUUID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func upsert(_ entityName: String, id: UUID) throws -> NSManagedObject {
        if let existing = try fetchOne(entityName, key: "id", id: id) {
            return existing
        }
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
    }

    private func saveIfNeeded() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    // MARK: - Domain Mapping

    private func foodBusiness(from object: NSManagedObject) throws -> FoodBusiness {
        FoodBusiness(
            id: try required("id", from: object),
            businessName: try required("businessName", from: object),
            suburb: try required("suburb", from: object),
            contactName: try required("contactName", from: object),
            contactPhone: try required("contactPhone", from: object),
            contactEmail: object.value(forKey: "contactEmail") as? String,
            pickupAddress: try required("pickupAddress", from: object),
            pickupInstructions: object.value(forKey: "pickupInstructions") as? String
        )
    }

    private func communityOrganisation(from object: NSManagedObject) throws -> CommunityOrganisation {
        CommunityOrganisation(
            id: try required("id", from: object),
            organisationName: try required("organisationName", from: object),
            suburb: try required("suburb", from: object),
            isVerified: try required("isVerified", from: object),
            contactName: try required("contactName", from: object),
            contactPhone: try required("contactPhone", from: object),
            contactEmail: object.value(forKey: "contactEmail") as? String,
            serviceArea: try required("serviceArea", from: object),
            foodHandlingNotes: object.value(forKey: "foodHandlingNotes") as? String
        )
    }

    private func surplusListing(from object: NSManagedObject) throws -> SurplusListing {
        guard object.value(forKey: "foodBusiness") is NSManagedObject else {
            throw missingRelationship(object, "foodBusiness")
        }
        let statusValue: String = try required("status", from: object)
        guard let status = SurplusListing.Status(rawValue: statusValue) else {
            throw malformed(object, "status")
        }
        let itemObjects = object.value(forKey: "items") as? Set<NSManagedObject> ?? []
        let sortedItems = itemObjects.sorted {
            ($0.value(forKey: "sortIndex") as? Int32 ?? 0)
                < ($1.value(forKey: "sortIndex") as? Int32 ?? 0)
        }

        return SurplusListing(
            id: try required("id", from: object),
            foodBusinessID: try required("foodBusinessID", from: object),
            title: try required("title", from: object),
            items: try sortedItems.map(surplusItem(from:)),
            pickupAddress: try required("pickupAddress", from: object),
            pickupInstructions: object.value(forKey: "pickupInstructions") as? String,
            pickupWindowStart: try required("pickupWindowStart", from: object),
            pickupWindowEnd: try required("pickupWindowEnd", from: object),
            createdAt: try required("createdAt", from: object),
            finalisedAt: object.value(forKey: "finalisedAt") as? Date,
            status: status
        )
    }

    private func surplusItem(from object: NSManagedObject) throws -> SurplusItem {
        let unitValue: String = try required("quantityUnit", from: object)
        let storageValue: String = try required("storageRequirement", from: object)
        guard let unit = SurplusItem.QuantityUnit(rawValue: unitValue) else {
            throw malformed(object, "quantityUnit")
        }
        guard let storage = SurplusItem.StorageRequirement(rawValue: storageValue) else {
            throw malformed(object, "storageRequirement")
        }
        let quantityNumber: NSDecimalNumber = try required("quantity", from: object)

        return SurplusItem(
            id: try required("id", from: object),
            foodName: try required("foodName", from: object),
            foodDescription: object.value(forKey: "foodDescription") as? String,
            quantity: quantityNumber.decimalValue,
            quantityUnit: unit,
            storageRequirement: storage,
            allergenInformation: object.value(forKey: "allergenInformation") as? String,
            useByDate: object.value(forKey: "useByDate") as? Date
        )
    }

    private func rescueClaim(from object: NSManagedObject) throws -> RescueClaim {
        guard object.value(forKey: "surplusListing") is NSManagedObject else {
            throw missingRelationship(object, "surplusListing")
        }
        guard object.value(forKey: "communityOrganisation") is NSManagedObject else {
            throw missingRelationship(object, "communityOrganisation")
        }
        let statusValue: String = try required("status", from: object)
        guard let status = RescueClaim.Status(rawValue: statusValue) else {
            throw malformed(object, "status")
        }

        return RescueClaim(
            id: try required("id", from: object),
            surplusListingID: try required("surplusListingID", from: object),
            communityOrganisationID: try required("communityOrganisationID", from: object),
            claimedAt: try required("claimedAt", from: object),
            plannedPickupAt: try required("plannedPickupAt", from: object),
            collectorName: try required("collectorName", from: object),
            collectorPhone: try required("collectorPhone", from: object),
            collectionNotes: object.value(forKey: "collectionNotes") as? String,
            status: status
        )
    }

    private func donationPickup(from object: NSManagedObject) throws -> DonationPickup {
        guard object.value(forKey: "rescueClaim") is NSManagedObject else {
            throw missingRelationship(object, "rescueClaim")
        }
        return DonationPickup(
            id: try required("id", from: object),
            rescueClaimID: try required("rescueClaimID", from: object),
            collectedAt: try required("collectedAt", from: object),
            handoverNotes: object.value(forKey: "handoverNotes") as? String
        )
    }

    private func required<Value>(_ key: String, from object: NSManagedObject) throws -> Value {
        guard let value = object.value(forKey: key) as? Value else {
            throw malformed(object, key)
        }
        return value
    }

    private func malformed(
        _ object: NSManagedObject,
        _ field: String
    ) -> CoreDataSharePlateRepositoryError {
        .malformedStoredRecord(entity: object.entity.name ?? "UnknownEntity", field: field)
    }

    private func missingRelationship(
        _ object: NSManagedObject,
        _ relationship: String
    ) -> CoreDataSharePlateRepositoryError {
        .missingRequiredRelationship(
            entity: object.entity.name ?? "UnknownEntity",
            relationship: relationship
        )
    }
}

enum CoreDataSharePlateRepositoryError: LocalizedError, Equatable {
    case persistentStoreUnavailable
    case persistentStoreLoadFailed(reason: String)
    case malformedStoredRecord(entity: String, field: String)
    case missingRequiredRelationship(entity: String, relationship: String)

    var errorDescription: String? {
        switch self {
        case .persistentStoreUnavailable:
            return "SharePlate could not open its local data store."
        case let .persistentStoreLoadFailed(reason):
            return "SharePlate could not load its local data store: \(reason)"
        case let .malformedStoredRecord(entity, field):
            return "The stored \(entity) record has invalid or missing \(field) data."
        case let .missingRequiredRelationship(entity, relationship):
            return "The stored \(entity) record is missing its required \(relationship) relationship."
        }
    }
}
