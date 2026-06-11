//
//  ScanContext.swift
//  Park

import Foundation

/// Everything the AI needs to know about "right now" to judge a sign.
struct ScanContext {
    let date: Date
    let isHoliday: Bool
    let holidayName: String?
    let city: String?

    var formattedDateTime: String {
        date.formatted(date: .complete, time: .shortened)
    }

    var dayOfWeek: String {
        date.formatted(.dateTime.weekday(.wide))
    }

    var permitZoneNotes: String? {
        guard let city else { return nil }
        return PermitZoneLibrary.notes(for: city)
    }
}

/// City-specific permit rules the AI should factor in.
enum PermitZoneLibrary {
    private static let notes: [String: String] = [
        "New York": "NYC: street cleaning (alternate side) rules suspended on legal holidays; "
            + "commercial metered zones common in Manhattan; no permit-only residential zones citywide.",
        "Jersey City": "Jersey City: residential permit zones citywide; visitors limited to "
            + "posted time without zone permit; street cleaning days posted per block.",
        "Los Angeles": "LA: preferential parking districts require posted district permit; "
            + "street cleaning typically once weekly per side; holiday suspension applies.",
        "Chicago": "Chicago: residential permit zones marked by zone number; "
            + "snow route restrictions Dec 1–Apr 1 on arterials; street cleaning Apr–Nov.",
        "San Francisco": "SF: RPP areas marked by letter (e.g. Area Q); time limits apply to "
            + "non-permit holders; street cleaning enforced on holidays unless posted otherwise.",
        "Toronto": "Toronto: on-street permit parking by area; max 3-hour unsigned limit citywide; "
            + "statutory holidays follow Sunday rules where posted.",
        "Vancouver": "Vancouver: residential permit zones marked; 2-hour visitor limit in most "
            + "permit blocks; rush-hour no-stopping corridors strictly towed.",
        "Boston": "Boston: resident-permit-only streets by neighborhood; street cleaning "
            + "Apr 1–Nov 30 with towing; snow emergency arteries ban parking when declared.",
        "Miami": "Miami: residential zones by number; pay-by-app metered zones common; "
            + "no overnight restrictions vary by neighborhood.",
        "San Diego": "San Diego: most residential streets 72-hour limit; coastal areas have "
            + "seasonal restrictions; street sweeping enforced on posted days.",
    ]

    static func notes(for city: String) -> String? {
        notes.first { city.localizedCaseInsensitiveContains($0.key) }?.value
    }
}
