//
//  CameraView.swift
//  Park

import SwiftUI
import VisionKit

/// Full-screen scanning UI: live VisionKit text recognition (no shutter,
/// no filters) with a city picker on top and a single decode button below.
struct CameraView: View {
    let viewModel: ScannerViewModel
    let onDecode: () -> Void
    @Environment(\.dismiss) private var dismiss

    @AppStorage("selectedCity") private var selectedCity = City.auto.rawValue
    @State private var liveText = ""
    @State private var scannerHolder = ScannerHolder()

    var body: some View {
        ZStack {
            LiveTextScanner(liveText: $liveText, holder: scannerHolder)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.black.opacity(0.5), in: Circle())
                    }

                    Spacer()

                    Menu {
                        ForEach(City.allCases) { city in
                            Button {
                                selectedCity = city.rawValue
                            } label: {
                                if city.rawValue == selectedCity {
                                    Label(city.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(city.rawValue)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(selectedCity)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.5), in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                Button {
                    let text = liveText
                    Task {
                        let photo = try? await scannerHolder.scanner?.capturePhoto()
                        viewModel.processText(text, photo: photo)
                        onDecode()
                        dismiss()
                    }
                } label: {
                    Label("Decode Sign", systemImage: "text.viewfinder")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(liveText.isEmpty ? Color(hex: "64748B") : Color(hex: "E53935"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(liveText.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

/// Cities with permit-zone awareness. `.auto` falls back to CoreLocation.
enum City: String, CaseIterable, Identifiable {
    case auto = "Auto (GPS)"
    case nyc = "New York(NYC)"
    case jerseyCity = "Jersey City"
    case losAngeles = "Los Angeles"
    case sanFrancisco = "San Francisco"
    case toronto = "Toronto"
    case vancouver = "Vancouver"
    case boston = "Boston"
    case chicago = "Chicago"
    case miami = "Miami"
    case sanDiego = "San Diego"

    var id: String { rawValue }
}

/// Keeps a handle to the live scanner so the decode button can grab a still
/// frame for the local (never shared) scan record.
@MainActor
@Observable
class ScannerHolder {
    weak var scanner: DataScannerViewController?
}

/// Wraps DataScannerViewController — continuous on-device text recognition
/// with built-in highlighting, no capture step.
private struct LiveTextScanner: UIViewControllerRepresentable {
    @Binding var liveText: String
    let holder: ScannerHolder

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighlightingEnabled: true
        )
        try? scanner.startScanning()
        holder.scanner = scanner
        context.coordinator.observe(scanner) { text in
            liveText = text
        }
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    class Coordinator {
        private var task: Task<Void, Never>?

        func observe(_ scanner: DataScannerViewController, onText: @escaping (String) -> Void) {
            task = Task {
                for await items in scanner.recognizedItems {
                    let text = items.compactMap { item in
                        if case .text(let t) = item { return t.transcript }
                        return nil
                    }.joined(separator: "\n")
                    onText(text)
                }
            }
        }

        deinit { task?.cancel() }
    }
}
