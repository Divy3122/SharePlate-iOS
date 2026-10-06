//
//  CommunityPickupView.swift
//  SharePlate
//
//  Created by Divy Patel on 6/10/2026.
//

import SwiftUI

struct CommunityPickupView: View {
    let listing: SurplusListing
    let claim: RescueClaim
    let organisation: CommunityOrganisation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your pickup is confirmed")
                        .font(.title2.bold())

                    Text(
                        "Keep these collection details handy when your team goes to collect the surplus."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                statusCard

                pickupCard

                collectorCard

                surplusCard
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My Pickup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusCard: some View {
        card {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .padding(10)
                    .background(
                        Color.accentColor.opacity(0.12),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Claimed")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)

                    Text(
                        "This surplus is reserved for \(organisation.organisationName)."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var pickupCard: some View {
        card {
            heading(
                "Collection",
                icon: "clock.fill"
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Planned pickup")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(
                    claim.plannedPickupAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.title3.bold())
            }

            Divider()

            detail(
                "Pickup window",
                value:
                    "\(listing.pickupWindowStart.formatted(date: .abbreviated, time: .shortened)) – \(listing.pickupWindowEnd.formatted(date: .abbreviated, time: .shortened))"
            )

            detail(
                "Pickup address",
                value: listing.pickupAddress
            )

            if let instructions = listing.pickupInstructions,
               !instructions.isEmpty {
                detail(
                    "Pickup instructions",
                    value: instructions
                )
            }
        }
    }

    private var collectorCard: some View {
        card {
            heading(
                "Collector",
                icon: "person.fill"
            )

            detail(
                "Collector name",
                value: claim.collectorName
            )

            detail(
                "Collector phone",
                value: claim.collectorPhone
            )

            if let notes = claim.collectionNotes,
               !notes.isEmpty {
                detail(
                    "Collection notes",
                    value: notes
                )
            }
        }
    }

    private var surplusCard: some View {
        card {
            heading(
                "Surplus",
                icon: "basket.fill"
            )

            Text(listing.title)
                .font(.title3.bold())

            Text(
                "\(listing.items.count) surplus food \(listing.items.count == 1 ? "type" : "types")"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Divider()

            ForEach(listing.items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.foodName)
                        .font(.headline)

                    Text(
                        "\(item.quantity.formatted()) \(unitDescription(item))"
                    )
                    .font(.subheadline)

                    Text(
                        storageDescription(
                            item.storageRequirement
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
        }
    }

    private func card<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 16,
            content: content
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(20)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private func heading(
        _ title: String,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .padding(10)
                .background(
                    Color.accentColor.opacity(0.12),
                    in: Circle()
                )

            Text(title)
                .font(.headline)
        }
    }

    private func detail(
        _ title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body.weight(.medium))
        }
    }

    private func unitDescription(
        _ item: SurplusItem
    ) -> String {
        switch item.quantityUnit {
        case .pieces:
            item.quantity == 1 ? "piece" : "pieces"

        case .portions:
            item.quantity == 1 ? "portion" : "portions"

        case .packs:
            item.quantity == 1 ? "pack" : "packs"

        case .trays:
            item.quantity == 1 ? "tray" : "trays"

        case .kilograms:
            "kg"

        case .litres:
            "L"
        }
    }

    private func storageDescription(
        _ requirement: SurplusItem.StorageRequirement
    ) -> String {
        switch requirement {
        case .ambient:
            "Room temperature"

        case .refrigerated:
            "Refrigerated"

        case .frozen:
            "Frozen"
        }
    }
}
