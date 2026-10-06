//
//  BusinessSurplusActivity.swift
//  SharePlate
//
//  Created by Divy Patel on 6/10/2026.
//

import Foundation

struct BusinessSurplusActivity: Identifiable {
    let listing: SurplusListing
    let activeClaim: RescueClaim?

    var id: UUID {
        listing.id
    }
}
