//
//  ResultView.swift
//  Park

import SwiftUI

struct ResultView: View {
    let viewModel: ScannerViewModel
    let onScanAgain: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            if viewModel.isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(Color(hex: "F1F5F9"))
                        .scaleEffect(1.4)
                    Text("Reading sign…")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "64748B"))
                }
            } else {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if let verdict = viewModel.verdict {
                                VerdictCard(verdict: verdict)
                            } else if let error = viewModel.errorMessage {
                                ErrorCard(message: error)
                            }

                            if !viewModel.recognizedText.isEmpty {
                                DetectedTextSection(text: viewModel.recognizedText)
                            }
                        }
                        .padding(24)
                    }

                    Button(action: onScanAgain) {
                        Label("Scan Another", systemImage: "camera.viewfinder")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "E53935"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle("Scan Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "161616"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct VerdictCard: View {
    let verdict: ParkingVerdict

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(verdict.status.headline)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text(verdict.summary)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.95))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(verdict.status.color)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if !verdict.breakdown.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(verdict.breakdown, id: \.self) { line in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(verdict.status.color)
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)
                            Text(line)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "F1F5F9"))
                        }
                    }
                }
            }
        }
    }
}

private struct ErrorCard: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 15))
            .foregroundColor(Color(hex: "F1F5F9"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(hex: "F59E0B").opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct DetectedTextSection: View {
    let text: String
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                expanded.toggle()
            } label: {
                HStack {
                    Text("Detected text")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.4)
                        .textCase(.uppercase)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(Color(hex: "64748B"))
            }

            if expanded {
                Text(text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Color(hex: "94A3B8"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
