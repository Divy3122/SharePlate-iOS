import SwiftUI

struct CommunityRescueHistoryView: View {
    let communityOrganisationID: UUID
    @State private var viewModel: CommunityRescueHistoryViewModel

    init(
        communityOrganisationID: UUID,
        viewModel: CommunityRescueHistoryViewModel
    ) {
        self.communityOrganisationID = communityOrganisationID
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed food rescues")
                        .font(.title2.bold())
                    Text("Review the surplus your organisation has collected for the community.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.isLoading && viewModel.historyEntries.isEmpty {
                    card {
                        HStack(spacing: 12) {
                            ProgressView().tint(.accentColor)
                            Text("Loading completed rescues…")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    errorCard(errorMessage)
                } else if viewModel.historyEntries.isEmpty {
                    emptyCard
                } else {
                    ForEach(viewModel.historyEntries) { entry in
                        historyCard(entry)
                    }
                }
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Rescue History")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadHistory(
                communityOrganisationID: communityOrganisationID
            )
        }
        .task(id: communityOrganisationID) {
            await viewModel.loadHistory(
                communityOrganisationID: communityOrganisationID
            )
        }
    }

    private var emptyCard: some View {
        card {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title)
                .foregroundStyle(Color.accentColor)
                .padding(14)
                .background(Color.accentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text("No completed rescues yet")
                .font(.title2.bold())
            Text("Completed pickups will appear here after food has been collected.")
                .foregroundStyle(.secondary)
        }
    }

    private func errorCard(_ message: String) -> some View {
        card {
            Label("Unable to load rescue history", systemImage: "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task {
                    await viewModel.loadHistory(
                        communityOrganisationID: communityOrganisationID
                    )
                }
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
    }

    private func historyCard(_ entry: CommunityRescueHistoryEntry) -> some View {
        card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Collected")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text(entry.listingTitle)
                        .font(.title3.bold())
                    Text(entry.collectedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                }
            }

            Divider()

            detail("Food rescued", value: foodSummary(entry.items), icon: "basket.fill")
            detail("Quantities", value: quantitySummary(entry.items), icon: "scalemass.fill")
            detail("Pickup location", value: entry.pickupAddress, icon: "mappin.and.ellipse")
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20)
            )
    }

    private func detail(_ title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.medium))
            }
        }
    }

    private func foodSummary(_ items: [SurplusItem]) -> String {
        let visibleNames = items.prefix(3).map(\.foodName)
        let remainingCount = items.count - visibleNames.count
        return remainingCount > 0
            ? "\(visibleNames.joined(separator: ", ")) and \(remainingCount) more"
            : visibleNames.joined(separator: ", ")
    }

    private func quantitySummary(_ items: [SurplusItem]) -> String {
        items.map {
            "\($0.quantity.formatted()) \($0.quantityUnit.rawValue) \($0.foodName)"
        }
        .joined(separator: ", ")
    }
}
