//
//  ParkIntents.swift
//  Park
//
//  PHASE 4 PLACEHOLDER — Siri & Shortcuts foundations. Minimal compiling
//  stubs; the real behaviour lands in Phase 4.
//
//  Plan:
//  - "Hey Siri, scan this parking sign" → launch directly into CameraView
//  - Shortcuts automation support, e.g. "When I arrive at work, remind me
//    to check parking by 5:30pm"

import AppIntents

/// Launches the app into the live scanner. PHASE 4 TODO: deep-link straight
/// to CameraView (e.g. via a shared AppState or URL scheme) instead of
/// just opening the app.
struct ScanParkingSignIntent: AppIntent {
    static let title: LocalizedStringResource = "Scan Parking Sign"
    static let description = IntentDescription("Open Park and scan the parking sign in front of you.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        // PHASE 4 TODO: set a "launch to camera" flag observed by ContentView.
        .result()
    }
}

/// Registers the Siri phrase. Kept minimal until Phase 4 polish.
struct ParkShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanParkingSignIntent(),
            phrases: ["Scan this parking sign with \(.applicationName)"],
            shortTitle: "Scan Sign",
            systemImageName: "camera.viewfinder"
        )
    }
}
