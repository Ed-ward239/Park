//
//  ScanRecord.swift
//  Park

import SwiftData
import Foundation

@Model
final class ScanRecord {
    var timestamp: Date
    var latitude: Double?
    var longitude: Double?
    var city: String?
    var statusRaw: String
    var summary: String
    var breakdown: [String]
    var signText: String
    /// Photo never leaves the device — excluded from any future shared payload.
    @Attribute(.externalStorage) var photoData: Data?

    init(timestamp: Date, latitude: Double?, longitude: Double?, city: String?,
         verdict: ParkingVerdict, signText: String, photoData: Data?) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
        self.statusRaw = verdict.status.rawValue
        self.summary = verdict.summary
        self.breakdown = verdict.breakdown
        self.signText = signText
        self.photoData = photoData
    }

    var status: ParkingVerdict.Status {
        ParkingVerdict.Status(rawValue: statusRaw) ?? .caution
    }

    /// Stale scans render grey on the map — rules may have changed.
    var isStale: Bool {
        timestamp < Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    }
}

/// The ONLY fields the future community layer may upload: verdict,
/// coordinate, timestamp. No photo, no sign text, no user identifier.
struct SharedScanPayload: Codable {
    let status: String
    let summary: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date

    init?(from record: ScanRecord) {
        guard let lat = record.latitude, let lon = record.longitude else { return nil }
        status = record.statusRaw
        summary = record.summary
        latitude = lat
        longitude = lon
        timestamp = record.timestamp
    }
}
