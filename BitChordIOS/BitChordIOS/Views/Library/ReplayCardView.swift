// ReplayCardView.swift
// BitChordIOS
// Android ref: sharedUi/.../ui/replay/ReplayCard.kt

import SwiftUI

/// Headline stats credit card — mirrors Android `ReplayCreditCard` composable:
/// Proportions: 1.586:1 (standard credit card 85.6 × 54mm)
/// Includes embossed cardholder line, member-since date, value, label, and mesh gradient background.
struct ReplayCreditCardView: View {
    let label: String
    let value: String
    let detail: String?
    let artworkUrl: String?
    let holder: String
    let memberSince: String?
    var onClick: (() -> Void)? = nil

    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 280 / 1.586 // ~176pt

    var body: some View {
        Button(action: { onClick?() }) {
            ZStack {
                // Card background: artwork blur / dark mesh
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "#2c3e50"), Color(hex: "#1a1a2e")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    if let url = artworkUrl, let parsed = URL(string: url) {
                        AsyncImage(url: parsed) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill().blur(radius: 20).opacity(0.35)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1)
                )

                // Card details
                VStack(alignment: .leading, spacing: 0) {
                    // Header: Label top-left, BitChord logo top-right
                    HStack {
                        Text(label.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2)
                        Spacer()
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                    Spacer()

                    // Value (e.g. "12,450 min" or top artist name)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(value)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.6), radius: 2, y: 1)

                        if let detail = detail {
                            Text(detail)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 18)

                    Spacer()

                    // Footer: Cardholder name & Member Since
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("CARDHOLDER")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1)
                            Text(holder.uppercased())
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                                .tracking(1.5)
                        }
                        Spacer()
                        if let memberSince = memberSince {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("SINCE")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(1)
                                Text(memberSince)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}

/// Horizontal scroll row of Replay credit cards for the Library header
struct ReplayCardRowView: View {
    let cards: [(label: String, value: String, detail: String?, artworkUrl: String?)]
    var onCardClick: ((Int) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(cards.enumerated()), id: \.offset) { idx, card in
                    ReplayCreditCardView(
                        label: card.label,
                        value: card.value,
                        detail: card.detail,
                        artworkUrl: card.artworkUrl,
                        holder: "BitChord Listener",
                        memberSince: "2024",
                        onClick: { onCardClick?(idx) }
                    )
                }
            }
            .padding(.horizontal, BCLayout.pageGutter)
            .padding(.vertical, 8)
        }
    }
}

private extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

