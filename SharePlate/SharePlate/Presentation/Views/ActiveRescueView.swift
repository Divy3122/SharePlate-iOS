import SwiftUI

struct ActiveRescueView: View {
    let listing: SurplusListing
    let claim: RescueClaim
    var onViewPickupDetails: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A local rescue is underway").font(.title2.bold())
                    Text("Your surplus has been claimed and is waiting for collection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                card {
                    Label("Claimed", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    Text("Your surplus has been claimed and is scheduled for pickup.")
                        .font(.headline)
                    Text("Have the food ready for your collector during the pickup window.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                card {
                    heading("Pickup", icon: "clock")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Planned collection")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text(claim.plannedPickupAt, format: .dateTime.hour().minute())
                            .font(.largeTitle.bold())
                        Text(claim.plannedPickupAt, format: .dateTime.weekday(.wide).day().month(.wide).year())
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    Divider()
                    detail("Pickup window starts", value: listing.pickupWindowStart.formatted(date: .abbreviated, time: .shortened))
                    detail("Pickup window ends", value: listing.pickupWindowEnd.formatted(date: .abbreviated, time: .shortened))
                    detail("Pickup address", value: listing.pickupAddress)
                    if let instructions = listing.pickupInstructions, !instructions.isEmpty {
                        detail("Pickup instructions", value: instructions)
                    }
                }

                card {
                    heading("Collector", icon: "person")
                    detail("Collector name", value: claim.collectorName)
                    detail("Phone number", value: claim.collectorPhone)
                    if let notes = claim.collectionNotes, !notes.isEmpty {
                        detail("Collection notes", value: notes)
                    }
                }

                card {
                    heading("Surplus for collection", icon: "basket")
                    Text(listing.title).font(.title2.bold())
                    Text("\(listing.items.count) surplus food \(listing.items.count == 1 ? "type" : "types")")
                        .foregroundStyle(.secondary)
                    ForEach(listing.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.foodName).font(.headline)
                            Text("\(item.quantity.formatted()) \(unitDescription(item))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let onViewPickupDetails {
                    Button(action: onViewPickupDetails) {
                        Label("View Pickup Details", systemImage: "arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .tint(.accentColor)
                }
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Active Rescue")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func heading(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .padding(10)
                .background(Color.accentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text(title).font(.headline)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private func detail(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Text(value).font(.body.weight(.medium))
        }
    }

    private func unitDescription(_ item: SurplusItem) -> String {
        switch item.quantityUnit {
        case .pieces: item.quantity == 1 ? "piece" : "pieces"
        case .portions: item.quantity == 1 ? "portion" : "portions"
        case .packs: item.quantity == 1 ? "pack" : "packs"
        case .trays: item.quantity == 1 ? "tray" : "trays"
        case .kilograms: "kg"
        case .litres: "L"
        }
    }
}

#if DEBUG
private struct ActiveRescuePreview: View {
    var includesNotes = false

    var body: some View {
        let now = Date()
        let listing = SurplusListing(
            foodBusinessID: UUID(), title: "Bread for the community",
            items: [SurplusItem(foodName: "Sourdough loaves", quantity: 6,
                                quantityUnit: .pieces, storageRequirement: .ambient)],
            pickupAddress: "12 Example Street, Ultimo",
            pickupInstructions: includesNotes ? "Please use the side entrance beside the bakery." : nil,
            pickupWindowStart: now, pickupWindowEnd: now.addingTimeInterval(3600),
            createdAt: now, finalisedAt: now, status: .claimed
        )
        let claim = RescueClaim(
            surplusListingID: listing.id, communityOrganisationID: UUID(), claimedAt: now,
            plannedPickupAt: now.addingTimeInterval(1800), collectorName: "Alex Morgan",
            collectorPhone: "0400 000 000",
            collectionNotes: includesNotes ? "I will bring reusable crates for the bread." : nil
        )
        NavigationStack {
            ActiveRescueView(listing: listing, claim: claim)
        }
    }
}

#Preview("Active rescue") {
    ActiveRescuePreview()
}

#Preview("Pickup instructions and notes") {
    ActiveRescuePreview(includesNotes: true)
}

#endif
