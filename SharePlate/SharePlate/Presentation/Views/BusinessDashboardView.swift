//
//  BusinessDashboardView.swift
//  SharePlate
//
//  Created by Divy Patel on 6/10/2026.
//

import SwiftUI

struct BusinessDashboardView: View {
    let foodBusinessID: UUID
    let businessName: String?

    @State private var viewModel:
        BusinessDashboardViewModel

    let refreshID: UUID

    let onCreateSurplus: () -> Void
    let onFinaliseSurplus: (SurplusListing) -> Void
    let onViewActiveRescue:
        (SurplusListing, RescueClaim) -> Void

    let onViewDonationHistory: () -> Void

    init(
        foodBusinessID: UUID,
        businessName: String? = nil,
        viewModel: BusinessDashboardViewModel,
        refreshID: UUID = UUID(),
        onCreateSurplus: @escaping () -> Void,
        onFinaliseSurplus:
            @escaping (SurplusListing) -> Void,
        onViewActiveRescue:
            @escaping (SurplusListing, RescueClaim) -> Void,
        onViewDonationHistory:
            @escaping () -> Void
    ) {
        self.foodBusinessID =
            foodBusinessID

        self.businessName =
            businessName

        _viewModel = State(
            initialValue: viewModel
        )

        self.refreshID =
            refreshID

        self.onCreateSurplus =
            onCreateSurplus

        self.onFinaliseSurplus =
            onFinaliseSurplus

        self.onViewActiveRescue =
            onViewActiveRescue

        self.onViewDonationHistory =
            onViewDonationHistory
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 22
            ) {

                header

                createSurplusCard

                activeSurplusSection

                donationHistoryCard
            }
            .frame(maxWidth: 620)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await viewModel.loadDashboard(
                foodBusinessID:
                    foodBusinessID
            )
        }
        .background(
            Color(.systemGroupedBackground)
        )
        .toolbar(
            .hidden,
            for: .navigationBar
        )
        .task(id: refreshID) {
            await viewModel.loadDashboard(
                foodBusinessID:
                    foodBusinessID
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Label(
                "SharePlate",
                systemImage: "leaf"
            )
            .font(
                .subheadline.weight(
                    .semibold
                )
            )
            .foregroundStyle(
                Color.accentColor
            )

            Text("Business Home")
                .font(.largeTitle.bold())

            if let businessName {
                Text(businessName)
                    .font(.headline)
            }

            Text(
                "Manage today's surplus and active community collections."
            )
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Create Surplus

    private var createSurplusCard:
        some View {

        Button(
            action: onCreateSurplus
        ) {
            HStack(spacing: 16) {

                Image(
                    systemName:
                        "plus.circle.fill"
                )
                .font(.title2)
                .foregroundStyle(
                    Color.accentColor
                )
                .padding(12)
                .background(
                    Color.accentColor
                        .opacity(0.12),
                    in: Circle()
                )

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {
                    Text("Add Surplus")
                        .font(.headline)
                        .foregroundStyle(
                            .primary
                        )

                    Text(
                        "Estimate another batch of food that may be available today."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .leading
                    )
                }

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(
                    .caption.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(20)
            .background(
                Color(
                    .secondarySystemGroupedBackground
                ),
                in: RoundedRectangle(
                    cornerRadius: 20
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active Surplus

    @ViewBuilder
    private var activeSurplusSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Text("Active Surplus")
                .font(.title2.bold())

            if viewModel.isLoading &&
                viewModel.activities.isEmpty {

                loadingCard

            } else if let error =
                viewModel.errorMessage,
                viewModel.activities.isEmpty {

                errorCard(error)

            } else if
                viewModel.activities.isEmpty {

                emptyCard

            } else {

                ForEach(
                    viewModel.activities
                ) { activity in

                    surplusCard(
                        activity
                    )
                }
            }
        }
    }

    private var loadingCard:
        some View {

        card {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(
                        .accentColor
                    )

                Text(
                    "Loading active surplus…"
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }

    private var emptyCard:
        some View {

        card {
            Image(
                systemName: "basket"
            )
            .font(.title)
            .foregroundStyle(
                Color.accentColor
            )
            .padding(14)
            .background(
                Color.accentColor
                    .opacity(0.12),
                in: Circle()
            )

            Text(
                "No active surplus"
            )
            .font(.title3.bold())

            Text(
                "Create a surplus estimate whenever you expect food to be left at the end of the day."
            )
            .foregroundStyle(
                .secondary
            )
        }
    }

    private func errorCard(
        _ message: String
    ) -> some View {

        card {
            Label(
                "Unable to load active surplus",
                systemImage:
                    "exclamationmark.circle.fill"
            )
            .font(.headline)
            .foregroundStyle(.red)

            Text(message)
                .foregroundStyle(
                    .secondary
                )

            Button("Try Again") {
                Task {
                    await viewModel
                        .loadDashboard(
                            foodBusinessID:
                                foodBusinessID
                        )
                }
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
    }

    // MARK: - Listing Card

    private func surplusCard(
        _ activity:
            BusinessSurplusActivity
    ) -> some View {

        let listing =
            activity.listing

        return card {
            HStack(
                alignment: .top,
                spacing: 12
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    statusBadge(
                        listing.status
                    )

                    Text(listing.title)
                        .font(
                            .title3.bold()
                        )
                }

                Spacer()
            }

            Label(
                "\(listing.items.count) surplus food \(listing.items.count == 1 ? "type" : "types")",
                systemImage: "basket"
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )

            Divider()

            detail(
                title: "Pickup window",
                value:
                    "\(listing.pickupWindowStart.formatted(date: .abbreviated, time: .shortened)) – \(listing.pickupWindowEnd.formatted(date: .abbreviated, time: .shortened))",
                icon: "clock"
            )

            detail(
                title: "Pickup address",
                value:
                    listing.pickupAddress,
                icon:
                    "mappin.and.ellipse"
            )

            listingAction(
                activity
            )
        }
    }

    @ViewBuilder
    private func listingAction(
        _ activity:
            BusinessSurplusActivity
    ) -> some View {

        switch activity.listing.status {

        case .estimated:

            Button {
                onFinaliseSurplus(
                    activity.listing
                )
            } label: {
                Label(
                    "Finalise Surplus",
                    systemImage:
                        "checkmark.circle"
                )
                .font(.headline)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 44
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .buttonBorderShape(
                .roundedRectangle(
                    radius: 16
                )
            )
            .tint(.accentColor)

        case .available:

            Label(
                "Waiting for a community organisation to claim this surplus.",
                systemImage:
                    "hourglass"
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )

        case .claimed:

            if let claim =
                activity.activeClaim {

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Label(
                        "Collection arranged with \(claim.collectorName)",
                        systemImage:
                            "person.2.fill"
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Button {
                        onViewActiveRescue(
                            activity.listing,
                            claim
                        )
                    } label: {
                        Label(
                            "View Active Rescue",
                            systemImage:
                                "arrow.right"
                        )
                        .font(.headline)
                        .frame(
                            maxWidth:
                                .infinity,
                            minHeight: 44
                        )
                    }
                    .buttonStyle(
                        .borderedProminent
                    )
                    .buttonBorderShape(
                        .roundedRectangle(
                            radius: 16
                        )
                    )
                    .tint(
                        .accentColor
                    )
                }

            } else {

                Text(
                    "This surplus is claimed. Pickup details are being loaded."
                )
                .font(.subheadline)
                .foregroundStyle(
                    .secondary
                )
            }

        case .collected,
             .expired,
             .cancelled:

            EmptyView()
        }
    }

    // MARK: - Donation History

    private var donationHistoryCard:
        some View {

        Button(
            action:
                onViewDonationHistory
        ) {
            card {
                HStack(
                    alignment: .top,
                    spacing: 14
                ) {

                    Image(
                        systemName:
                            "clock.arrow.circlepath"
                    )
                    .font(.title2)
                    .foregroundStyle(
                        Color.accentColor
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text(
                            "Donation History"
                        )
                        .font(.headline)

                        Text(
                            "Look back on completed rescues."
                        )
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Spacer()

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(
                        .caption.weight(
                            .semibold
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - UI Helpers

    private func card<
        Content: View
    >(
        @ViewBuilder
        content: () -> Content
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
            Color(
                .secondarySystemGroupedBackground
            ),
            in: RoundedRectangle(
                cornerRadius: 20
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 20
            )
            .strokeBorder(
                Color.primary
                    .opacity(0.05),
                lineWidth: 1
            )
        }
    }

    private func detail(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            Image(
                systemName: icon
            )
            .foregroundStyle(
                Color.accentColor
            )
            .frame(width: 20)

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                Text(value)
                    .font(
                        .subheadline
                            .weight(
                                .medium
                            )
                    )
            }
        }
    }

    private func statusBadge(
        _ status:
            SurplusListing.Status
    ) -> some View {

        Label(
            statusTitle(status),
            systemImage:
                statusIcon(status)
        )
        .font(
            .subheadline.weight(
                .semibold
            )
        )
        .foregroundStyle(
            status == .estimated
            ? .secondary
            : Color.accentColor
        )
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            7
        )
        .background(
            (
                status == .estimated
                ? Color.secondary
                : Color.accentColor
            )
            .opacity(0.10),
            in:
                RoundedRectangle(
                    cornerRadius: 12
                )
        )
    }

    private func statusTitle(
        _ status:
            SurplusListing.Status
    ) -> String {

        switch status {
        case .estimated:
            "Estimated"

        case .available:
            "Available for Collection"

        case .claimed:
            "Claimed"

        case .collected:
            "Collected"

        case .expired:
            "Expired"

        case .cancelled:
            "Cancelled"
        }
    }

    private func statusIcon(
        _ status:
            SurplusListing.Status
    ) -> String {

        switch status {
        case .estimated:
            "pencil.circle"

        case .available:
            "shippingbox"

        case .claimed:
            "person.2"

        case .collected:
            "checkmark.circle"

        case .expired:
            "clock.badge.exclamationmark"

        case .cancelled:
            "xmark.circle"
        }
    }
}
