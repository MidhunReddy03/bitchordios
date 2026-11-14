// SourceQualityBadge.swift
// BitChordIOS
// Android ref: sharedUi/.../ui/components/SourceQualityBadge.kt

import SwiftUI

enum SourceQuality {
    case dolbyAtmos
    case hiResLossless
    case lossless
    case highQuality

    var label: String {
        switch self {
        case .dolbyAtmos:     return "Dolby Atmos"
        case .hiResLossless:  return "Hi-Res Lossless"
        case .lossless:       return "Lossless"
        case .highQuality:    return "High Quality"
        }
    }

    var iconName: String {
        switch self {
        case .dolbyAtmos:     return "spatial"
        case .hiResLossless:  return "waveform.badge.magnifyingglass"
        case .lossless:       return "waveform"
        case .highQuality:    return "headphones"
        }
    }
}

extension Song {
    var sourceQualityBadge: SourceQuality? {
        guard let sq = sourceQuality?.uppercased() else { return nil }
        switch sq {
        case "DOLBY":
            return .dolbyAtmos
        case "HI-RES", "HIRES":
            return .hiResLossless
        case "LOSSLESS", "FLAC", "ALAC", "WAV":
            return sourceHiRes ? .hiResLossless : .lossless
        case "HIGH", "320":
            return .highQuality
        default:
            return nil
        }
    }
}

/// The player's quality glyph and label, at row or scrubber size:
/// The same lossless wave, Dolby double-D, and headphones as under the seek bar.
struct SourceQualityBadgeView: View {
    let quality: SourceQuality
    var color: Color = .white.opacity(0.7)

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: quality.iconName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)

            Text(quality.label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }
}

