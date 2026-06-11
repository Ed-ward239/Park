//
//  ScannerViewModel.swift
//  Park

import SwiftUI
import SwiftData
import CoreLocation
import Observation

@MainActor
@Observable
class ScannerViewModel {
    var recognizedText: String = ""
    var verdict: ParkingVerdict?
    var errorMessage: String?
    var isProcessing: Bool = false

    /// Injected from the view layer so scans can be persisted.
    var modelContext: ModelContext?

    let locationManager = LocationManager()
    private let gemini = GeminiClient()
    private let holidayDetector = HolidayDetector()

    /// City the verdict should use: manual pick wins, otherwise GPS.
    private var effectiveCity: String? {
        let selected = UserDefaults.standard.string(forKey: "selectedCity")
        if let selected, selected != City.auto.rawValue {
            return selected
        }
        return locationManager.city
    }

    /// Interpret already-recognized sign text (live scanner path).
    /// The photo stays on-device only — see SharedScanPayload.
    func processText(_ text: String, photo: UIImage? = nil) {
        recognizedText = text
        verdict = nil
        errorMessage = nil

        guard !text.isEmpty else {
            errorMessage = "No text detected. Try scanning again with better lighting."
            return
        }

        isProcessing = true
        locationManager.refresh()

        Task {
            let holiday = await holidayDetector.holidayToday()
            let context = ScanContext(
                date: Date(),
                isHoliday: holiday.isHoliday,
                holidayName: holiday.name,
                city: effectiveCity
            )

            do {
                let verdict = try await gemini.interpretSign(text: recognizedText, context: context)
                self.verdict = verdict
                saveScan(verdict: verdict, photo: photo)
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }

    private func saveScan(verdict: ParkingVerdict, photo: UIImage?) {
        guard let modelContext else { return }
        let record = ScanRecord(
            timestamp: Date(),
            latitude: locationManager.coordinate?.latitude,
            longitude: locationManager.coordinate?.longitude,
            city: effectiveCity,
            verdict: verdict,
            signText: recognizedText,
            photoData: photo?.jpegData(compressionQuality: 0.7)
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}
