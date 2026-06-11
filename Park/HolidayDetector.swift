//
//  HolidayDetector.swift
//  Park

import EventKit

/// Detects whether today is a public holiday using the user's subscribed
/// holiday calendars (e.g. "US Holidays"), with a built-in fallback for
/// US federal holidays so detection works without calendar access.
struct HolidayDetector {
    func holidayToday() async -> (isHoliday: Bool, name: String?) {
        if let name = await holidayFromCalendars() {
            return (true, name)
        }
        if let name = Self.usFederalHoliday(on: Date()) {
            return (true, name)
        }
        return (false, nil)
    }

    private func holidayFromCalendars() async -> String? {
        let store = EKEventStore()
        guard (try? await store.requestFullAccessToEvents()) == true else { return nil }

        let holidayCalendars = store.calendars(for: .event).filter {
            $0.title.localizedCaseInsensitiveContains("holiday")
        }
        guard !holidayCalendars.isEmpty else { return nil }

        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: holidayCalendars)
        return store.events(matching: predicate).first?.title
    }

    /// Fixed-date and rule-based US federal holidays.
    static func usFederalHoliday(on date: Date) -> String? {
        let cal = Calendar.current
        let c = cal.dateComponents([.month, .day, .weekday, .weekdayOrdinal], from: date)
        guard let month = c.month, let day = c.day,
              let weekday = c.weekday, let ordinal = c.weekdayOrdinal else { return nil }

        let isLastWeekdayOfMonth = cal.date(byAdding: .weekOfMonth, value: 1, to: date).map {
            cal.component(.month, from: $0) != month
        } ?? false

        switch (month, day, weekday, ordinal) {
        case (1, 1, _, _): return "New Year's Day"
        case (1, _, 2, 3): return "Martin Luther King Jr. Day"   // 3rd Mon Jan
        case (2, _, 2, 3): return "Presidents' Day"              // 3rd Mon Feb
        case (5, _, 2, _) where isLastWeekdayOfMonth: return "Memorial Day"  // last Mon May
        case (6, 19, _, _): return "Juneteenth"
        case (7, 4, _, _): return "Independence Day"
        case (9, _, 2, 1): return "Labor Day"                    // 1st Mon Sep
        case (10, _, 2, 2): return "Columbus Day"                // 2nd Mon Oct
        case (11, 11, _, _): return "Veterans Day"
        case (11, _, 5, 4): return "Thanksgiving"                // 4th Thu Nov
        case (12, 25, _, _): return "Christmas Day"
        default: return nil
        }
    }
}
