import SwiftUI

struct TodayDashboardView: View {
    var businessName: String? = nil
    var surplusListing: SurplusListing? = nil
    var rescueClaim: RescueClaim? = nil
    var onEstimateSurplus: (() -> Void)? = nil
    var onFinaliseSurplus: (() -> Void)? = nil
    var onViewActiveRescue: (() -> Void)? = nil
    var onViewDonationHistory: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("SharePlate", systemImage: "leaf")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text("Today").font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    if let businessName {
                        Text(businessName).font(.headline)
                    }
                    Text("See where today's surplus is up to.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                card {
                    Text("Today's Surplus").font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    if let listing = surplusListing {
                        badge(listing.status)
                        Text(listing.title).font(.title2.bold())
                        Label("\(listing.items.count) surplus food \(listing.items.count == 1 ? "type" : "types")", systemImage: "basket")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Divider()
                        pickupTime(start: listing.pickupWindowStart, end: listing.pickupWindowEnd)
                        nextAction(for: listing.status)
                    } else {
                        Image(systemName: "basket")
                            .font(.title)
                            .foregroundStyle(Color.accentColor)
                            .padding(16)
                            .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                            .accessibilityHidden(true)
                        Text("No surplus estimated yet").font(.title2.bold())
                        Text("Start with what you expect to have left. Help good food find a place in your community.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        primaryAction("Estimate Today's Surplus", icon: "plus", perform: onEstimateSurplus)
                    }
                }

                if let claim = rescueClaim, claim.status == .active {
                    card {
                        Label("Active Rescue", systemImage: "person.2")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        badge(.claimed)
                        Text("Your surplus has a collection arranged.")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Collector").font(.subheadline).foregroundStyle(.secondary)
                            Text(claim.collectorName).font(.headline)
                        }
                        pickupTime(start: claim.plannedPickupAt)
                        if let onViewActiveRescue {
                            Button(action: onViewActiveRescue) {
                                Label("View Pickup Details", systemImage: "arrow.right")
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .tint(.accentColor)
                        }
                    }
                }

                if let onViewDonationHistory {
                    Button(action: onViewDonationHistory) {
                        historyCard(showDisclosure: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View Donation History")
                } else {
                    historyCard(showDisclosure: false)
                }
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
            }
    }

    private func historyCard(showDisclosure: Bool) -> some View {
        card {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Donation History").font(.headline)
                    Text("Look back on completed rescues.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if showDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func pickupTime(start: Date, end: Date? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(end == nil ? "Planned pickup" : "Pickup window", systemImage: "clock")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(start, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.headline)
            if let end {
                Text("to \(end.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                    .font(.subheadline)
            }
        }
    }

    private func badge(_ status: SurplusListing.Status) -> some View {
        Label(statusTitle(status), systemImage: statusIcon(status))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(statusColor(status).opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }

    private func statusColor(_ status: SurplusListing.Status) -> Color {
        switch status {
        case .estimated: .secondary
        case .available, .collected: .accentColor
        case .claimed: .accentColor
        case .expired, .cancelled: .secondary
        }
    }

    @ViewBuilder
    private func nextAction(for status: SurplusListing.Status) -> some View {
        switch status {
        case .estimated:
            primaryAction("Finalise Surplus", icon: "checkmark.circle", perform: onFinaliseSurplus)
        case .available:
            Text("Waiting for a community organisation to claim your surplus.")
                .foregroundStyle(.secondary)
        case .claimed:
            primaryAction("View Active Rescue", icon: "person.2", perform: onViewActiveRescue)
        case .collected:
            Label("Collection completed. Thank you for sharing your surplus.", systemImage: "checkmark.circle")
        case .expired:
            Text("The pickup window has ended.").foregroundStyle(.secondary)
        case .cancelled:
            Text("This surplus listing has been cancelled.").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func primaryAction(_ title: String, icon: String, perform: (() -> Void)?) -> some View {
        if let perform {
            Button(action: perform) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .buttonBorderShape(.roundedRectangle(radius: 16))
        }
    }

    private func statusTitle(_ status: SurplusListing.Status) -> String {
        switch status {
        case .estimated: "Estimated"
        case .available: "Available for Collection"
        case .claimed: "Claimed"
        case .collected: "Collected"
        case .expired: "Expired"
        case .cancelled: "Cancelled"
        }
    }

    private func statusIcon(_ status: SurplusListing.Status) -> String {
        switch status {
        case .estimated: "pencil.circle"
        case .available: "shippingbox"
        case .claimed: "person.2"
        case .collected: "checkmark.circle"
        case .expired: "clock.badge.exclamationmark"
        case .cancelled: "xmark.circle"
        }
    }
}

#if DEBUG
private enum DashboardPreview {
    static func listing(status: SurplusListing.Status) -> SurplusListing {
        let now = Date()
        return SurplusListing(
            foodBusinessID: UUID(), title: "Bread and pastries",
            items: [SurplusItem(foodName: "Bread", quantity: 6, quantityUnit: .pieces,
                                storageRequirement: .ambient)],
            pickupAddress: "1 Example Street",
            pickupWindowStart: now, pickupWindowEnd: now.addingTimeInterval(3600),
            createdAt: now, status: status
        )
    }
}

#Preview("No surplus yet") {
    NavigationStack {
        TodayDashboardView(onEstimateSurplus: {}, onViewDonationHistory: {})
    }
}

#Preview("Estimated surplus") {
    NavigationStack {
        TodayDashboardView(
            businessName: "Neighbourhood Bakery",
            surplusListing: DashboardPreview.listing(status: .estimated),
            onFinaliseSurplus: {}, onViewDonationHistory: {}
        )
    }
}

#Preview("Claimed surplus") {
    let listing = DashboardPreview.listing(status: .claimed)
    let claim = RescueClaim(
        surplusListingID: listing.id, communityOrganisationID: UUID(),
        claimedAt: listing.createdAt, plannedPickupAt: listing.pickupWindowEnd,
        collectorName: "Alex", collectorPhone: "0400000000"
    )
    NavigationStack {
        TodayDashboardView(
            businessName: "Neighbourhood Bakery", surplusListing: listing, rescueClaim: claim,
            onViewActiveRescue: {}, onViewDonationHistory: {}
        )
    }
}
#Preview("Collected surplus") {
    NavigationStack {
        TodayDashboardView(
            businessName: "Neighbourhood Bakery",
            surplusListing: DashboardPreview.listing(status: .collected),
            onViewDonationHistory: {}
        )
    }
}
#endif
