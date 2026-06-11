//
//  MapView.swift
//  Park

import SwiftUI
import SwiftData
import MapKit

struct MapView: View {
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var records: [ScanRecord]
    @State private var selected: ScanRecord?

    private var pinnedRecords: [ScanRecord] {
        records.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        Map {
            ForEach(pinnedRecords) { record in
                Annotation(
                    record.summary,
                    coordinate: CLLocationCoordinate2D(
                        latitude: record.latitude!,
                        longitude: record.longitude!
                    )
                ) {
                    // Stale pins go grey — the rules may have changed since.
                    Circle()
                        .fill(record.isStale ? Color(hex: "64748B") : record.status.color)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: record.isStale ? "questionmark" : "parkingsign")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .onTapGesture { selected = record }
                }
            }
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .flat))
        .navigationTitle("Scanned Spots")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { record in
            ScanDetailSheet(record: record)
                .presentationDetents([.medium, .large])
        }
        .overlay {
            if pinnedRecords.isEmpty {
                ContentUnavailableView(
                    "No scanned spots yet",
                    systemImage: "mappin.slash",
                    description: Text("Scans with location appear here as colour-coded pins.")
                )
            }
        }
    }
}

private struct ScanDetailSheet: View {
    let record: ScanRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(record.status.headline)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if record.isStale {
                        Label("Stale", systemImage: "clock.badge.exclamationmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(16)
                .background(record.isStale ? Color(hex: "64748B") : record.status.color)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Text(record.summary)
                    .font(.system(size: 17, weight: .medium))

                Text("Scanned \(record.timestamp.formatted(.relative(presentation: .named)))"
                     + (record.city.map { " in \($0)" } ?? ""))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                ForEach(record.breakdown, id: \.self) { line in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(record.status.color)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)
                        Text(line)
                            .font(.system(size: 15))
                    }
                }

                if let data = record.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
    }
}
