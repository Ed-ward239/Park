//
//  ParkWidget.swift
//  Park
//
//  PHASE 4 PLACEHOLDER — home screen widget foundations. NOT a functional
//  widget: WidgetKit widgets must live in a separate widget extension
//  target (File ▸ New ▸ Target ▸ Widget Extension), which doesn't exist yet.
//
//  Plan:
//  - Widget shows the verdict for the last saved spot + time remaining
//  - Data flows via an App Group (shared UserDefaults or SwiftData store)
//    since extensions can't read the app's sandbox directly
//  - Tap → deep link to re-scan or extend reminder
//
//  PHASE 4 TODO:
//  1. Add widget extension target "ParkWidget"
//  2. Add App Group capability to both targets (requires paid dev account
//     for some configurations — verify with free team first)
//  3. Move WidgetSnapshot below into the shared group container
//  4. TimelineProvider reads the latest ScanRecord snapshot

import Foundation

/// The minimal data the widget needs, written by the app after each scan.
/// Kept Codable so it can serialize into App Group UserDefaults.
struct WidgetSnapshot: Codable {
    let status: String        // "safe" / "caution" / "danger"
    let summary: String       // "Free until 6 pm today."
    let timestamp: Date
    let freeUntil: Date?      // drives "time remaining" countdown
}
