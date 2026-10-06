import SwiftUI

struct DonationHistoryView: View {
    let foodBusinessID: UUID
    @State private var viewModel: DonationHistoryViewModel

    init(foodBusinessID: UUID, viewModel: DonationHistoryViewModel) {
        self.foodBusinessID = foodBusinessID
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed food rescues")
                        .font(.title2.bold())
                    Text("Review the surplus your business has shared with the local community.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.isLoading && viewModel.historyEntries.isEmpty {
                    loadingCard
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
        .navigationTitle("Donation History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .task(id: foodBusinessID) {
            await viewModel.loadDonationHistory(foodBusinessID: foodBusinessID)
        }
    }

    private var loadingCard: some View {
        card {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.accentColor)
                Text("Loading completed rescues…")
                    .foregroundStyle(.secondary)
            }
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
            Text("Completed pickups will appear here after food has been handed over.")
                .foregroundStyle(.secondary)
        }
    }

    private func errorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            Label(message, systemImage: "exclamationmark.circle.fill")
                .font(.subheadline)
                .labelStyle(.titleOnly)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    private func historyCard(_ entry: DonationHistoryEntry) -> some View {
        card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.listing.title)
                        .font(.title3.bold())
                    Text(entry.pickup.collectedAt, format: .dateTime.day().month(.wide).year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(entry.pickup.collectedAt, format: .dateTime.hour().minute())
                        .font(.headline)
                }
            }

            Divider()

            Label(
                "\(entry.listing.items.count) surplus food \(entry.listing.items.count == 1 ? "type" : "types")",
                systemImage: "basket"
            )
            .foregroundStyle(.secondary)

            Text(foodSummary(entry.listing.items))
                .font(.subheadline)

            detail("Collected by", value: entry.claim.collectorName)

            if let notes = entry.pickup.handoverNotes, !notes.isEmpty {
                detail("Handover notes", value: notes)
            }
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

    private func detail(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.medium))
        }
    }

    private func foodSummary(_ items: [SurplusItem]) -> String {
        let visibleNames = items.prefix(3).map(\.foodName)
        let remainingCount = items.count - visibleNames.count
        if remainingCount > 0 {
            return "\(visibleNames.joined(separator: ", ")) and \(remainingCount) more"
        }
        return visibleNames.joined(separator: ", ")
    }
}
