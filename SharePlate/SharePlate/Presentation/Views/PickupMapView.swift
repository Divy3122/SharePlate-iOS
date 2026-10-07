import SwiftUI
import MapKit
import UIKit

struct PickupMapView: View {
    let title: String
    let address: String

    @State private var mapItem: MKMapItem?

    @State private var position:
        MapCameraPosition = .automatic

    @State private var isLoading = true

    @State private var errorMessage:
        String?

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Label(
                "Pickup Location",
                systemImage: "mappin.and.ellipse"
            )
            .font(.headline)
            .foregroundStyle(Color.accentColor)

            if let mapItem {
                Map(position: $position) {
                    Marker(
                        title,
                        coordinate:
                            mapItem.location.coordinate
                    )
                    .tint(Color.accentColor)
                }
                .frame(height: 220)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )

            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()

                    Text(
                        "Finding pickup location…"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 160
                )
                .background(
                    Color(
                        .tertiarySystemGroupedBackground
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 16
                    )
                )

            } else {
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Label(
                        "Map preview unavailable",
                        systemImage: "mappin.slash"
                    )
                    .font(
                        .subheadline
                            .weight(.semibold)
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                    }

                    Button {
                        Task {
                            await loadLocation()
                        }
                    } label: {
                        Label(
                            "Try Again",
                            systemImage:
                                "arrow.clockwise"
                        )
                    }
                    .buttonStyle(.bordered)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(
                    Color(
                        .tertiarySystemGroupedBackground
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 16
                    )
                )
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text("Pickup address")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(address)
                    .font(
                        .body.weight(.medium)
                    )
            }

            Button {
                openInMaps()
            } label: {
                Label(
                    "Open in Maps",
                    systemImage:
                        "arrow.triangle.turn.up.right.diamond.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
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
        .task(id: address) {
            await loadLocation()
        }
    }

    // MARK: - Search

    @MainActor
    private func loadLocation() async {
        isLoading = true
        errorMessage = nil
        mapItem = nil

        let trimmed =
            address.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            isLoading = false

            errorMessage =
                "No pickup address was provided."

            return
        }

        let request =
            MKLocalSearch.Request()

        request.naturalLanguageQuery =
            trimmed

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

            guard let result =
                response.mapItems.first
            else {
                isLoading = false

                errorMessage =
                    "Apple Maps could not find this pickup address."

                return
            }

            mapItem = result

            position = .region(
                MKCoordinateRegion(
                    center:
                        result.location.coordinate,
                    span:
                        MKCoordinateSpan(
                            latitudeDelta: 0.008,
                            longitudeDelta: 0.008
                        )
                )
            )

            isLoading = false

        } catch {
            isLoading = false

            errorMessage =
                "The pickup map could not be loaded."
        }
    }

    // MARK: - Directions

    private func openInMaps() {
        if let mapItem {
            mapItem.name = title

            mapItem.openInMaps(
                launchOptions: [
                    MKLaunchOptionsDirectionsModeKey:
                        MKLaunchOptionsDirectionsModeDriving
                ]
            )

            return
        }

        var components =
            URLComponents(
                string:
                    "https://maps.apple.com/"
            )

        components?.queryItems = [
            URLQueryItem(
                name: "daddr",
                value: address
            ),
            URLQueryItem(
                name: "dirflg",
                value: "d"
            )
        ]

        guard let url =
            components?.url
        else {
            return
        }

        UIApplication.shared.open(url)
    }
}

#Preview {
    PickupMapView(
        title: "Bread rescue pickup",
        address:
            "15 Broadway, Ultimo NSW 2007, Australia"
    )
    .padding()
    .background(
        Color(.systemGroupedBackground)
    )
}
