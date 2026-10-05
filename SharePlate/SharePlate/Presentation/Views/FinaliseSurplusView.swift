import SwiftUI

struct FinaliseSurplusView: View {
    let listing: SurplusListing
    let onFinalised: ((SurplusListing) -> Void)?
    @State private var viewModel: FinaliseSurplusViewModel

    init(
        listing: SurplusListing,
        viewModel: FinaliseSurplusViewModel,
        onFinalised: ((SurplusListing) -> Void)? = nil
    ) {
        self.listing = listing
        self.onFinalised = onFinalised
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ready to share today's surplus?").font(.title2.bold())
                    Text("Review your estimate before making the food available for collection.")
                        .foregroundStyle(.secondary)
                }

                card {
                    Text(listing.title).font(.title2.bold())
                    Label("Estimated", systemImage: "pencil.circle")
                        .foregroundStyle(Color.accentColor)
                        .font(.subheadline.weight(.semibold))
                        .padding(10)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    let itemCount = listing.items.count

                    Text(
                        "\(itemCount) surplus food \(itemCount == 1 ? "type" : "types")"
                    )
                }

                card {
                    heading("Food available", icon: "basket")
                    ForEach(listing.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.foodName).font(.headline)
                            Text("\(item.quantity.formatted()) \(unitDescription(item))")
                            Text(storageDescription(item.storageRequirement))
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                }

                card {
                    heading("Collection details", icon: "mappin.and.ellipse")
                    detail("Pickup address", value: listing.pickupAddress)
                    if let instructions = listing.pickupInstructions, !instructions.isEmpty {
                        detail("Pickup instructions", value: instructions)
                    }
                    Divider()
                    detail("Pickup from", value: listing.pickupWindowStart.formatted(date: .abbreviated, time: .shortened))
                    detail("Pickup until", value: listing.pickupWindowEnd.formatted(date: .abbreviated, time: .shortened))
                }

                Text("Once you confirm, a verified community organisation can claim this surplus and arrange collection.")
                    .font(.subheadline).foregroundStyle(.secondary)

                if let errorMessage = viewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("Unable to finalise surplus. \(errorMessage)")
                }

                Button {
                    Task {
                        await viewModel.finaliseSurplusListing(id: listing.id)
                        if let finalisedListing = viewModel.finalisedListing {
                            onFinalised?(finalisedListing)
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        }
                        Text(viewModel.isLoading ? "Making Surplus Available…" : "Make Surplus Available")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .tint(.accentColor)
                .disabled(viewModel.isLoading)
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Finalise Surplus")
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
            Text(value)
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

    private func storageDescription(_ storage: SurplusItem.StorageRequirement) -> String {
        switch storage {
        case .ambient: "Room temperature"
        case .refrigerated: "Refrigerated"
        case .frozen: "Frozen"
        }
    }
}
