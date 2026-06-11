//
//  ParkLiveActivity.swift
//  Park
//
//  PHASE 4 PLACEHOLDER — Live Activity foundations. Not wired up yet.
//
//  Plan:
//  - Start an Activity when a verdict has a known expiry ("free until 6 pm")
//  - Lock screen / Dynamic Island shows street + countdown, e.g.
//    "You parked at 3rd Ave — free until 6 pm (2h 14m remaining)"
//  - Requires NSSupportsLiveActivities in Info.plist and a widget extension
//    target for the Activity UI (ActivityConfiguration lives there).

import ActivityKit
import Foundation

/// Shared attributes for the parking Live Activity. The widget extension
/// (Phase 4) will render these; the app will start/stop the activity.
struct ParkingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the current parking permission ends (drives the countdown).
        var freeUntil: Date
        /// Verdict status raw value for tinting ("safe"/"caution"/"danger").
        var status: String
    }

    /// Human-readable location, e.g. "3rd Ave".
    var locationName: String
}

/// PHASE 4 TODO: ActivityLifecycle helper.
/// - start(record:) — request Activity when a scan has a time-bound verdict
/// - update/end as the window closes
enum ParkingActivityManager {
    // Intentionally empty until Phase 4.
}
