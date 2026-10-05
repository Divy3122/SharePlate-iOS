//
//  EstimateSurplusView.swift
//  SharePlate
//
//  Created by Divy Patel on 5/10/2026.
//

import SwiftUI

struct EstimateSurplusView: View {
    let foodBusinessID: UUID
    let onSaved: ((SurplusListing) -> Void)?

    @State private var viewModel: EstimateSurplusViewModel

    @State private var foodName = ""
    @State private var quantityText = ""
    @State private var quantityUnit: QuantityUnitOption = .pieces
    @State private var storageRequirement: StorageOption = .ambient
    @State private var itemInputMessage: String?

    init(
        foodBusinessID: UUID,
        viewModel: EstimateSurplusViewModel,
        onSaved: ((SurplusListing) -> Void)? = nil
    ) {
        self.foodBusinessID = foodBusinessID
        self.onSaved = onSaved
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 20) {

                introduction

                dashboardCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeading(
                            title: "Today's Surplus",
                            subtitle: "Give this estimate a short name so it is easy to recognise later.",
                            icon: "basket"
                        )

                        TextField(
                            "e.g. Bread and pastries",
                            text: $viewModel.title
                        )
                        .textFieldStyle(.roundedBorder)
                    }
                }

                dashboardCard {
                    VStack(alignment: .leading, spacing: 18) {
                        sectionHeading(
                            title: "Surplus Food",
                            subtitle: "Add the food you expect to have left today.",
                            icon: "fork.knife"
                        )

                        if !viewModel.surplusItems.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(viewModel.surplusItems) { item in
                                    surplusItemRow(item)
                                }
                            }

                            Divider()
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add food")
                                .font(.headline)

                            TextField(
                                "Food name",
                                text: $foodName
                            )
                            .textFieldStyle(.roundedBorder)

                            HStack {
                                TextField(
                                    "Quantity",
                                    text: $quantityText
                                )
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)

                                Picker("Unit", selection: $quantityUnit) {
                                    ForEach(QuantityUnitOption.allCases) { unit in
                                        Text(unit.rawValue)
                                            .tag(unit)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            Picker(
                                "Storage",
                                selection: $storageRequirement
                            ) {
                                ForEach(StorageOption.allCases) { option in
                                    Label(option.rawValue, systemImage: option.icon)
                                        .tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            if let itemInputMessage {
                                Text(itemInputMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }

                            Button {
                                addSurplusItem()
                            } label: {
                                Label("Add Food", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                }

                dashboardCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeading(
                            title: "Collection Details",
                            subtitle: "Let the community organisation know where and when the food can be collected.",
                            icon: "clock.badge.checkmark"
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pickup address")
                                .font(.subheadline.weight(.semibold))

                            TextField(
                                "Enter pickup address",
                                text: $viewModel.pickupAddress
                            )
                            .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pickup instructions")
                                .font(.subheadline.weight(.semibold))

                            TextField(
                                "Optional instructions",
                                text: $viewModel.pickupInstructions,
                                axis: .vertical
                            )
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pickup window")
                                .font(.headline)

                            DatePicker(
                                "From",
                                selection: $viewModel.pickupWindowStart
                            )

                            DatePicker(
                                "Until",
                                selection: $viewModel.pickupWindowEnd
                            )
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    errorCard(errorMessage)
                }

                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Estimate Surplus")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Plan today's rescue")
                .font(.title2.bold())

            Text(
                "Estimate what may be left near closing time. You can finalise the surplus before it becomes available for collection."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.estimateSurplus(
                    foodBusinessID: foodBusinessID
                )

                if let listing = viewModel.estimatedListing {
                    onSaved?(listing)
                }
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }

                Text(
                    viewModel.isLoading
                    ? "Saving Estimate..."
                    : "Save Surplus Estimate"
                )
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.accentColor)
        .disabled(viewModel.isLoading)
        .padding(.bottom, 24)
    }

    private func addSurplusItem() {
        itemInputMessage = nil

        let trimmedName = foodName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty else {
            itemInputMessage = "Enter the name of the surplus food."
            return
        }

        guard let quantity = Decimal(string: quantityText) else {
            itemInputMessage = "Enter a numeric quantity."
            return
        }

        guard quantity > 0 else {
            itemInputMessage = "Enter a quantity greater than zero."
            return
        }

        var item = SurplusItem(
            foodName: trimmedName,
            quantity: quantity,
            quantityUnit: .pieces,
            storageRequirement: .ambient
        )

        switch quantityUnit {
        case .pieces:
            item.quantityUnit = .pieces
        case .portions:
            item.quantityUnit = .portions
        case .packs:
            item.quantityUnit = .packs
        case .trays:
            item.quantityUnit = .trays
        case .kilograms:
            item.quantityUnit = .kilograms
        case .litres:
            item.quantityUnit = .litres
        }

        switch storageRequirement {
        case .ambient:
            item.storageRequirement = .ambient
        case .refrigerated:
            item.storageRequirement = .refrigerated
        case .frozen:
            item.storageRequirement = .frozen
        }

        viewModel.surplusItems.append(item)

        foodName = ""
        quantityText = ""
        quantityUnit = .pieces
        storageRequirement = .ambient
    }

    @ViewBuilder
    private func surplusItemRow(
        _ item: SurplusItem
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "takeoutbag.and.cup.and.straw")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(item.foodName)
                    .font(.headline)

                Text(
                    verbatim: "\(NSDecimalNumber(decimal: item.quantity).stringValue) \(quantityDescription(for: item))"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text(storageDescription(for: item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                removeItem(item)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(item.foodName)")
        }
        .padding(.vertical, 4)
    }

    private func removeItem(_ item: SurplusItem) {
        viewModel.surplusItems.removeAll {
            $0.id == item.id
        }
    }

    private func quantityDescription(
        for item: SurplusItem
    ) -> String {
        switch item.quantityUnit {
        case .pieces:
            "pieces"
        case .portions:
            "portions"
        case .packs:
            "packs"
        case .trays:
            "trays"
        case .kilograms:
            "kg"
        case .litres:
            "L"
        }
    }

    private func storageDescription(
        for item: SurplusItem
    ) -> String {
        switch item.storageRequirement {
        case .ambient:
            "Room temperature"
        case .refrigerated:
            "Refrigerated"
        case .frozen:
            "Frozen"
        }
    }

    private func sectionHeading(
        title: String,
        subtitle: String,
        icon: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.green)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dashboardCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }

    private func errorCard(
        _ message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.08))
        )
    }
}

private enum QuantityUnitOption: String, CaseIterable, Identifiable {
    case pieces = "Pieces"
    case portions = "Portions"
    case packs = "Packs"
    case trays = "Trays"
    case kilograms = "Kilograms"
    case litres = "Litres"

    var id: Self { self }
}

private enum StorageOption: String, CaseIterable, Identifiable {
    case ambient = "Ambient"
    case refrigerated = "Chilled"
    case frozen = "Frozen"

    var id: Self { self }

    var icon: String {
        switch self {
        case .ambient:
            "thermometer.medium"
        case .refrigerated:
            "snowflake"
        case .frozen:
            "snowflake.circle"
        }
    }
}
