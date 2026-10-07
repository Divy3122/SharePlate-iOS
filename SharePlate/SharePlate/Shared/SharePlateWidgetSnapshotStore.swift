//
//  SharePlateWidgetSnapshotStore.swift
//  SharePlate
//
//  Created by Divy Patel on 7/10/2026.
//

import Foundation

enum SharePlateWidgetConfiguration {
    static let appGroupIdentifier = "group.uts.edu.au.SharePlate"
    static let snapshotKey = "shareplate.widget.snapshot"
    static let widgetKind = "SharePlateRescueWidget"
}

enum SharePlateWidgetSnapshotStore {

    static func save(
        _ snapshot: SharePlateWidgetSnapshot
    ) throws {
        guard let defaults = UserDefaults(
            suiteName: SharePlateWidgetConfiguration.appGroupIdentifier
        ) else {
            throw SharePlateWidgetStoreError.appGroupUnavailable
        }

        let data = try JSONEncoder().encode(snapshot)

        defaults.set(
            data,
            forKey: SharePlateWidgetConfiguration.snapshotKey
        )
    }

    static func load() -> SharePlateWidgetSnapshot? {
        guard
            let defaults = UserDefaults(
                suiteName: SharePlateWidgetConfiguration.appGroupIdentifier
            ),
            let data = defaults.data(
                forKey: SharePlateWidgetConfiguration.snapshotKey
            )
        else {
            return nil
        }

        return try? JSONDecoder().decode(
            SharePlateWidgetSnapshot.self,
            from: data
        )
    }
}

enum SharePlateWidgetStoreError: LocalizedError {
    case appGroupUnavailable

    var errorDescription: String? {
        "The SharePlate App Group is unavailable."
    }
}
