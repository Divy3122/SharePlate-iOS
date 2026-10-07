//
//  SharePlateWidgetSnapshot.swift
//  SharePlate
//
//  Created by Divy Patel on 7/10/2026.
//

import Foundation

struct SharePlateWidgetSnapshot: Codable, Equatable {
    let role: String
    let activeListingCount: Int
    let claimedListingCount: Int
    let activePickupCount: Int
    let nextTitle: String?
    let nextPickupAt: Date?
    let nextPickupAddress: String?
    let updatedAt: Date

    static let empty = SharePlateWidgetSnapshot(
        role: "business",
        activeListingCount: 0,
        claimedListingCount: 0,
        activePickupCount: 0,
        nextTitle: nil,
        nextPickupAt: nil,
        nextPickupAddress: nil,
        updatedAt: Date()
    )
}
