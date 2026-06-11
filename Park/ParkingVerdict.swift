//
//  ParkingVerdict.swift
//  Park

import SwiftUI

struct ParkingVerdict: Codable, Equatable {
    enum Status: String, Codable {
        case safe       // park freely
        case caution    // conditions apply
        case danger     // do not park

        var color: Color {
            switch self {
            case .safe: Color(hex: "10B981")
            case .caution: Color(hex: "F59E0B")
            case .danger: Color(hex: "EF4444")
            }
        }

        var headline: String {
            switch self {
            case .safe: "You can park here"
            case .caution: "Conditions apply"
            case .danger: "Do not park here"
            }
        }
    }

    let status: Status
    /// One-sentence plain-English answer, e.g. "Free until 6 pm today."
    let summary: String
    /// Rule-by-rule breakdown, e.g. "Mon–Fri 8am–6pm: No parking."
    let breakdown: [String]
}
