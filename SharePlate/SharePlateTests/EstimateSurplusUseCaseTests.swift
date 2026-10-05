//
//  EstimateSurplusUseCaseTests.swift
//  SharePlate
//
//  Created by Divy Patel on 6/10/2026.
//

import XCTest
@testable import SharePlate

final class EstimateSurplusUseCaseTests: XCTestCase {

    private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    func testEstimateSucceedsWhenSurplusDetailsAreValid() async throws {
        let repository = EstimateSurplusRepositorySpy()

        let useCase = EstimateSurplusUseCase(
            surplusRepository: repository,
            currentDate: { self.fixedDate }
        )

        let businessID = UUID()

        let item = SurplusItem(
            foodName: "Bread",
            quantity: 6,
            quantityUnit: .pieces,
            storageRequirement: .ambient
        )

        let listing = try await useCase.estimateSurplus(
            foodBusinessID: businessID,
            title: "Bread and pastries",
            items: [item],
            pickupAddress: "1 Example Street",
            pickupInstructions: "Collect from the rear entrance",
            pickupWindowStart: fixedDate.addingTimeInterval(3600),
            pickupWindowEnd: fixedDate.addingTimeInterval(7200)
        )

        XCTAssertEqual(listing.foodBusinessID, businessID)
        XCTAssertEqual(listing.title, "Bread and pastries")
        XCTAssertEqual(listing.items, [item])
        XCTAssertEqual(listing.status, .estimated)
        XCTAssertEqual(listing.createdAt, fixedDate)
        XCTAssertNil(listing.finalisedAt)

        XCTAssertEqual(repository.savedListings.count, 1)
        XCTAssertEqual(repository.savedListings.first, listing)
    }

    func testEstimateFailsWhenNoSurplusItemsExist() async {
        let repository = EstimateSurplusRepositorySpy()

        let useCase = EstimateSurplusUseCase(
            surplusRepository: repository,
            currentDate: { self.fixedDate }
        )

        do {
            _ = try await useCase.estimateSurplus(
                foodBusinessID: UUID(),
                title: "Today's surplus",
                items: [],
                pickupAddress: "1 Example Street",
                pickupInstructions: nil,
                pickupWindowStart: fixedDate.addingTimeInterval(3600),
                pickupWindowEnd: fixedDate.addingTimeInterval(7200)
            )

            XCTFail("Expected noSurplusItems error.")
        } catch let error as EstimateSurplusError {
            XCTAssertEqual(error, .noSurplusItems)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(repository.savedListings.isEmpty)
    }

    func testEstimateFailsWhenSurplusQuantityIsNotPositive() async {
        let repository = EstimateSurplusRepositorySpy()

        let useCase = EstimateSurplusUseCase(
            surplusRepository: repository,
            currentDate: { self.fixedDate }
        )

        let item = SurplusItem(
            foodName: "Pastries",
            quantity: -2,
            quantityUnit: .pieces,
            storageRequirement: .ambient
        )

        do {
            _ = try await useCase.estimateSurplus(
                foodBusinessID: UUID(),
                title: "Pastries",
                items: [item],
                pickupAddress: "1 Example Street",
                pickupInstructions: nil,
                pickupWindowStart: fixedDate.addingTimeInterval(3600),
                pickupWindowEnd: fixedDate.addingTimeInterval(7200)
            )

            XCTFail("Expected invalidQuantity error.")
        } catch let error as EstimateSurplusError {
            XCTAssertEqual(
                error,
                .invalidQuantity(foodName: "Pastries")
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(repository.savedListings.isEmpty)
    }

    func testEstimateFailsWhenPickupWindowIsInvalid() async {
        let repository = EstimateSurplusRepositorySpy()

        let useCase = EstimateSurplusUseCase(
            surplusRepository: repository,
            currentDate: { self.fixedDate }
        )

        let item = SurplusItem(
            foodName: "Bread",
            quantity: 4,
            quantityUnit: .pieces,
            storageRequirement: .ambient
        )

        do {
            _ = try await useCase.estimateSurplus(
                foodBusinessID: UUID(),
                title: "Bread",
                items: [item],
                pickupAddress: "1 Example Street",
                pickupInstructions: nil,
                pickupWindowStart: fixedDate.addingTimeInterval(7200),
                pickupWindowEnd: fixedDate.addingTimeInterval(3600)
            )

            XCTFail("Expected invalidPickupWindow error.")
        } catch let error as EstimateSurplusError {
            XCTAssertEqual(error, .invalidPickupWindow)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(repository.savedListings.isEmpty)
    }

    func testEstimateFailsWhenPickupWindowHasAlreadyEnded() async {
        let repository = EstimateSurplusRepositorySpy()

        let useCase = EstimateSurplusUseCase(
            surplusRepository: repository,
            currentDate: { self.fixedDate }
        )

        let item = SurplusItem(
            foodName: "Sandwiches",
            quantity: 3,
            quantityUnit: .packs,
            storageRequirement: .refrigerated
        )

        do {
            _ = try await useCase.estimateSurplus(
                foodBusinessID: UUID(),
                title: "Sandwiches",
                items: [item],
                pickupAddress: "1 Example Street",
                pickupInstructions: nil,
                pickupWindowStart: fixedDate.addingTimeInterval(-7200),
                pickupWindowEnd: fixedDate.addingTimeInterval(-3600)
            )

            XCTFail("Expected pickupWindowHasEnded error.")
        } catch let error as EstimateSurplusError {
            XCTAssertEqual(error, .pickupWindowHasEnded)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(repository.savedListings.isEmpty)
    }
}

private final class EstimateSurplusRepositorySpy: SurplusRepository {

    private(set) var savedListings: [SurplusListing] = []

    func saveSurplusListing(
        _ listing: SurplusListing
    ) async throws {
        savedListings.append(listing)
    }

    func surplusListing(
        id: UUID
    ) async throws -> SurplusListing? {
        savedListings.first { $0.id == id }
    }

    func surplusListings(
        forFoodBusinessID foodBusinessID: UUID
    ) async throws -> [SurplusListing] {
        savedListings.filter {
            $0.foodBusinessID == foodBusinessID
        }
    }

    func availableSurplusListings(
        at date: Date
    ) async throws -> [SurplusListing] {
        savedListings.filter {
            $0.status == .available &&
            $0.pickupWindowEnd > date
        }
    }
}
