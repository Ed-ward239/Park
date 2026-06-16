//
//  ContentView.swift
//  Park

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var records: [ScanRecord]

    @State private var showCamera = false
    @State private var viewModel = ScannerViewModel()
    @State private var showResult = false
    @State private var lettersShown = [false, false, false, false]
    @State private var taglineShown = false
    @State private var buttonShown = false

    /// Home-screen list shows only scans from the last 24 hours, capped at 10.
    private var recentRecords: [ScanRecord] {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        return Array(records.filter { $0.timestamp >= cutoff }.prefix(10))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 10) {
                        HStack(spacing: 2) {
                            ForEach(Array("PARK".enumerated()), id: \.offset) { index, letter in
                                FlipInLetter(
                                    letter: String(letter),
                                    edge: Edge.allCases[index],
                                    shown: lettersShown[index]
                                )
                            }
                        }

                        Text("Street parking sign decoder")
                            .font(.system(size: 17))
                            .foregroundColor(Color(hex: "64748B"))
                            .opacity(taglineShown ? 1 : 0)
                            .offset(y: taglineShown ? 0 : 16)
                    }

                    Spacer()

                    if !recentRecords.isEmpty {
                        RecentScansList(records: recentRecords)
                            .frame(maxHeight: 220)
                            .padding(.bottom, 24)
                    }

                    Button {
                        showCamera = true
                    } label: {
                        Label("Scan a Sign", systemImage: "camera.viewfinder")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "E53935"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                    .opacity(buttonShown ? 1 : 0)
                    .offset(y: buttonShown ? 0 : 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MapView()
                    } label: {
                        Image(systemName: "map")
                            .foregroundColor(Color(hex: "F1F5F9"))
                    }
                }
            }
            .toolbarBackground(Color(hex: "0D0D0D"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(viewModel: viewModel) {
                    showResult = true
                }
            }
            .navigationDestination(isPresented: $showResult) {
                ResultView(viewModel: viewModel) {
                    showResult = false
                    showCamera = true
                }
            }
            .onAppear {
                viewModel.modelContext = modelContext
                viewModel.locationManager.start()
                runIntroAnimation()
            }
        }
    }

    /// P A R K flip in from the 4 edges over 1.5s, then the tagline
    /// fades up, then the button rises in.
    private func runIntroAnimation() {
        guard !buttonShown else { return }  // play once
        for index in lettersShown.indices {
            withAnimation(.spring(duration: 0.7, bounce: 0.35).delay(Double(index) * 0.27)) {
                lettersShown[index] = true
            }
        }
        withAnimation(.easeOut(duration: 0.45).delay(1.5)) {
            taglineShown = true
        }
        withAnimation(.spring(duration: 0.5, bounce: 0.25).delay(1.95)) {
            buttonShown = true
        }
    }
}

/// One logo letter that flips (3D) while floating in from a screen edge.
private struct FlipInLetter: View {
    let letter: String
    let edge: Edge
    let shown: Bool

    private var hiddenOffset: CGSize {
        switch edge {
        case .top: CGSize(width: 0, height: -400)
        case .leading: CGSize(width: -250, height: 0)
        case .bottom: CGSize(width: 0, height: 400)
        case .trailing: CGSize(width: 250, height: 0)
        }
    }

    private var flipAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch edge {
        case .top, .bottom: (x: 1, y: 0, z: 0)   // tumble vertically
        case .leading, .trailing: (x: 0, y: 1, z: 0)  // spin horizontally
        }
    }

    var body: some View {
        Text(letter)
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .foregroundColor(Color(hex: "E53935"))
            .rotation3DEffect(.degrees(shown ? 0 : 360), axis: flipAxis)
            .offset(shown ? .zero : hiddenOffset)
            .opacity(shown ? 1 : 0)
    }
}

private struct RecentScansList: View {
    let records: [ScanRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent scans")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: "64748B"))
                .padding(.horizontal, 32)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(records) { record in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(record.isStale ? Color(hex: "64748B") : record.status.color)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.summary)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "F1F5F9"))
                                    .lineLimit(1)
                                Text(record.timestamp.formatted(.relative(presentation: .named)))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "64748B"))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ScanRecord.self, inMemory: true)
}
