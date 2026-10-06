//
//  RoleSelectionView.swift
//  SharePlate
//
//  Created by Divy Patel on 6/10/2026.
//

import SwiftUI

struct RoleSelectionView: View {
    let onSelectRole: (SharePlateRole) -> Void

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 28
            ) {

                header

                VStack(spacing: 16) {
                    roleCard(
                        role: .business
                    )

                    roleCard(
                        role: .community
                    )
                }

                Text(
                    "You can switch SharePlate profiles later from inside the app."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                .multilineTextAlignment(
                    .center
                )
                .padding(.horizontal)
            }
            .frame(maxWidth: 620)
            .padding(24)
            .frame(
                maxWidth: .infinity
            )
        }
        .background(
            Color(
                .systemGroupedBackground
            )
        )
    }

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Image(
                systemName:
                    "leaf.circle.fill"
            )
            .font(.system(size: 54))
            .foregroundStyle(
                Color.accentColor
            )

            Text("Welcome to SharePlate")
                .font(.largeTitle.bold())

            Text(
                "Choose how you use SharePlate."
            )
            .font(.title3)
            .foregroundStyle(
                .secondary
            )
        }
        .padding(.top, 24)
    }

    private func roleCard(
        role: SharePlateRole
    ) -> some View {

        Button {
            onSelectRole(role)
        } label: {

            HStack(
                alignment: .center,
                spacing: 18
            ) {

                Image(
                    systemName:
                        role.systemImage
                )
                .font(.title2)
                .foregroundStyle(
                    Color.accentColor
                )
                .frame(
                    width: 54,
                    height: 54
                )
                .background(
                    Color.accentColor
                        .opacity(0.12),
                    in: RoundedRectangle(
                        cornerRadius: 16
                    )
                )

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(role.title)
                        .font(
                            .title3.bold()
                        )
                        .foregroundStyle(
                            .primary
                        )

                    Text(role.subtitle)
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(
                            .secondary
                        )
                        .multilineTextAlignment(
                            .leading
                        )
                }

                Spacer(
                    minLength: 8
                )

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(
                    .subheadline
                        .weight(
                            .semibold
                        )
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(20)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                Color(
                    .secondarySystemGroupedBackground
                ),
                in: RoundedRectangle(
                    cornerRadius: 22
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22
                )
                .strokeBorder(
                    Color.primary
                        .opacity(0.05),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleSelectionView { role in
        print(role)
    }
}
