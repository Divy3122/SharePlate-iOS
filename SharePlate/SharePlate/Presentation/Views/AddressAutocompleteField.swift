import SwiftUI
import MapKit
import Combine

struct AddressAutocompleteField: View {
    @Binding var address: String

    @StateObject private var searchModel = AddressSearchModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Color.accentColor)

                TextField(
                    "Start typing pickup address",
                    text: $address
                )
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)

                if searchModel.isResolving {
                    ProgressView()
                        .controlSize(.small)
                } else if !address.isEmpty {
                    Button {
                        address = ""
                        searchModel.clear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(
                Color(.tertiarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14)
            )

            if isFocused && !searchModel.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(
                        Array(searchModel.suggestions.enumerated()),
                        id: \.offset
                    ) { index, suggestion in

                        Button {
                            select(suggestion)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.top, 2)

                                VStack(
                                    alignment: .leading,
                                    spacing: 3
                                ) {
                                    Text(suggestion.title)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)

                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                }

                                Spacer()

                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index <
                            searchModel.suggestions.count - 1 {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            Color.secondary.opacity(0.15),
                            lineWidth: 1
                        )
                )
            }

            Text(
                "Choose an Apple Maps suggestion so the community can navigate to the correct pickup location."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .onChange(of: address) { _, newValue in
            searchModel.updateQuery(newValue)
        }
    }

    private func select(
        _ suggestion: MKLocalSearchCompletion
    ) {
        Task {
            let resolvedAddress =
                await searchModel.resolve(
                    suggestion
                )

            await MainActor.run {
                if let resolvedAddress {
                    address = resolvedAddress
                } else {
                    let fallback = [
                        suggestion.title,
                        suggestion.subtitle
                    ]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")

                    address = fallback
                }

                searchModel.clear()
                isFocused = false
            }
        }
    }
}

// MARK: - Address Search Model

final class AddressSearchModel:
    NSObject,
    ObservableObject,
    MKLocalSearchCompleterDelegate {

    @Published var suggestions:
        [MKLocalSearchCompletion] = []

    @Published var isResolving = false

    private let completer =
        MKLocalSearchCompleter()

    override init() {
        super.init()

        completer.delegate = self

        // Only return address-style results.
        completer.resultTypes = .address

        // Bias results toward Sydney / NSW.
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: -33.8688,
                longitude: 151.2093
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 1.5,
                longitudeDelta: 1.5
            )
        )
    }

    func updateQuery(
        _ query: String
    ) {
        let trimmed = query
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard trimmed.count >= 3 else {
            suggestions = []
            completer.queryFragment = ""
            return
        }

        completer.queryFragment = trimmed
    }

    func clear() {
        suggestions = []
        completer.queryFragment = ""
    }

    func resolve(
        _ completion: MKLocalSearchCompletion
    ) async -> String? {
        await MainActor.run {
            isResolving = true
        }

        defer {
            Task { @MainActor in
                self.isResolving = false
            }
        }

        let request =
            MKLocalSearch.Request(
                completion: completion
            )

        request.resultTypes = .address

        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: -33.8688,
                longitude: 151.2093
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 1.5,
                longitudeDelta: 1.5
            )
        )

        do {
            let response =
                try await MKLocalSearch(
                    request: request
                )
                .start()

            guard let item =
                response.mapItems.first
            else {
                return nil
            }

            if let fullAddress =
                item.address?.fullAddress,
               !fullAddress.isEmpty {
                return fullAddress
            }

            if let fullAddress =
                item.addressRepresentations?
                    .fullAddress(
                        includingRegion: false,
                        singleLine: true
                    ),
               !fullAddress.isEmpty {
                return fullAddress
            }

            return [
                completion.title,
                completion.subtitle
            ]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        } catch {
            return nil
        }
    }

    func completerDidUpdateResults(
        _ completer: MKLocalSearchCompleter
    ) {
        suggestions =
            Array(
                completer.results.prefix(6)
            )
    }

    func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        suggestions = []
    }
}

#Preview {
    @Previewable @State
    var address = ""

    Form {
        Section("Pickup location") {
            AddressAutocompleteField(
                address: $address
            )
        }
    }
}
