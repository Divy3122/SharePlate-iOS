//
//  SharePlateApp.swift
//  SharePlate
//
//  Created by Divy Patel on 2/10/2026.
//

import SwiftUI

@main
struct SharePlateApp: App {
    var body: some Scene {
        WindowGroup {
            if isRunningUnitTests {
                Color.clear
            } else {
                SharePlateRuntimeView()
            }
        }
    }

    private var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

private struct SharePlateRuntimeView: View {
    @State private var dependencies = SharePlateAppDependencies()

    var body: some View {
        Group {
            if dependencies.isReady {
                ContentView(dependencies: dependencies)
            } else if let message = dependencies.bootstrapErrorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "externaldrive.badge.xmark")
                        .font(.largeTitle)
                        .foregroundStyle(Color.accentColor)
                    Text("Unable to connect to SharePlate")
                        .font(.title2.bold())
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await dependencies.bootstrapProfiles() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                }
                .padding(24)
            } else {
                ProgressView("Connecting to SharePlate…")
                    .tint(.accentColor)
            }
        }
        .task {
            await dependencies.bootstrapProfiles()
        }
    }
}
