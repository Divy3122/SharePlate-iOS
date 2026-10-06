//
//  SharePlateRole.swift
//  SharePlate
//
//  Created by Divy Patel on 6/10/2026.
//

import Foundation

enum SharePlateRole: String {
    case business
    case community

    var title: String {
        switch self {
        case .business:
            "Local Business"

        case .community:
            "Community Organisation"
        }
    }

    var subtitle: String {
        switch self {
        case .business:
            "Manage surplus food, community claims and completed rescues."

        case .community:
            "Find available surplus and manage the pickups your organisation has claimed."
        }
    }

    var systemImage: String {
        switch self {
        case .business:
            "storefront.fill"

        case .community:
            "person.3.fill"
        }
    }
}
