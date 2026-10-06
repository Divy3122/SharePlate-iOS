import SwiftUI

struct AvailableSurplusView: View {
    @State private var viewModel: AvailableSurplusViewModel
    let refreshID: UUID
    var onSelectListing: (SurplusListing) -> Void

    init(
        viewModel: AvailableSurplusViewModel,
        refreshID: UUID = UUID(),
        onSelectListing: @escaping (SurplusListing) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.refreshID = refreshID
        self.onSelectListing = onSelectListing
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("SharePlate", systemImage: "leaf")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text("Food ready to rescue")
                        .font(.title2.bold())
                    Text("Find local surplus that can still be collected and shared with your community.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.isLoading && viewModel.listings.isEmpty {
                    loadingCard
                } else if let errorMessage = viewModel.errorMessage,
                          viewModel.listings.isEmpty {
                    errorCard(errorMessage)
                } else if viewModel.listings.isEmpty {
                    emptyCard
                } else {
                    ForEach(viewModel.listings) { listing in
                        Button {
                            onSelectListing(listing)
                        } label: {
                            listingCard(listing)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens surplus details and claim form")
                    }
                }
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await viewModel.loadAvailableSurplus()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Available Surplus")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: refreshID) {
            await viewModel.loadAvailableSurplus()
        }
    }

    private var loadingCard: some View {
        card {
            HStack(spacing: 12) {
                ProgressView().tint(.accentColor)
                Text("Finding available surplus…")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyCard: some View {
        card {
            Image(systemName: "basket")
                .font(.title)
                .foregroundStyle(Color.accentColor)
                .padding(14)
                .background(Color.accentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text("No surplus available nearby right now")
                .font(.title2.bold())
            Text("Newly finalised surplus will appear here when a local business makes food available for collection.")
                .foregroundStyle(.secondary)
        }
    }

    private func errorCard(_ message: String) -> some View {
        card {
            Label("Unable to load available surplus", systemImage: "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await viewModel.loadAvailableSurplus() }
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
    }

    private func listingCard(_ listing: SurplusListing) -> some View {
        card {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "shippingbox.fill")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                    .padding(11)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Available for Collection")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text(listing.title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Label(
                "\(listing.items.count) surplus food \(listing.items.count == 1 ? "type" : "types")",
                systemImage: "basket"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            detail(
                "Pickup window",
                value: "\(listing.pickupWindowStart.formatted(date: .abbreviated, time: .shortened)) – \(listing.pickupWindowEnd.formatted(date: .abbreviated, time: .shortened))",
                icon: "clock"
            )
            detail("Pickup address", value: listing.pickupAddress, icon: "mappin.and.ellipse")
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func detail(_ title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
    }
}
