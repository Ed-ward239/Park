//
//  ParkApp.swift
//  Park

import SwiftUI
import SwiftData

@main
struct ParkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ScanRecord.self)
    }
}
