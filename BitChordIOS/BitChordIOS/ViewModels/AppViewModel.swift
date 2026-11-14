import Foundation
import Combine

// MARK: - AppViewModel
/// Global app state shared across all tabs.
/// Android ref: AppUiHost interface + SharedPreferences in AppSettings.kt
@MainActor
class AppViewModel: ObservableObject {
    // ── Auth ──────────────────────────────────────────────────────
    @Published var isSignedIn: Bool = false
    @Published var accountName: String? = nil

    // ── Playback settings (AppSettings.kt equivalents) ────────────
    @Published var gaplessEnabled: Bool = true          // AppSettings.kt → GaplessSetting
    @Published var crossfadeDuration: Int = 5           // AppSettings.kt → CrossfadeSetting (0–12s)
    @Published var skipSilence: Bool = false            // AppSettings.kt → SkipSilenceSetting
    @Published var normalizeVolume: Bool = false        // AppSettings.kt → NormalizationSetting
    @Published var smartFadeEnabled: Bool = true        // AppSettings.kt → SmartFadeSetting

    // ── Audio quality ─────────────────────────────────────────────
    @Published var wifiQuality: AudioQuality = .high       // AppSettings.kt → WifiQualitySetting
    @Published var cellularQuality: AudioQuality = .medium // AppSettings.kt → CellularQualitySetting

    // ── Appearance ────────────────────────────────────────────────
    @Published var fullBleedArtwork: Bool = true        // AppSettings.kt → FullBleedArtworkSetting
    @Published var reduceMotion: Bool = false           // AppSettings.kt → ReduceMotionSetting

    // ── Now Playing ───────────────────────────────────────────────
    @Published var statsForNerds: Bool = false          // AppSettings.kt → StatsForNerdsSetting
    @Published var festiveLogo: Bool = false
    @Published var pinnedPlaylists: [String] = []
    @Published var swipeToPlayNext: Bool = true         // AppSettings.kt → SwipeToPlayNextSetting

    // ── Legacy aliases (kept for backward compat with existing views) ──
    var audioQualityWifi: AudioQuality {
        get { wifiQuality }
        set { wifiQuality = newValue }
    }
    var audioQualityCellular: AudioQuality {
        get { cellularQuality }
        set { cellularQuality = newValue }
    }
    var gaplessPlayback: Bool {
        get { gaplessEnabled }
        set { gaplessEnabled = newValue }
    }
    var crossfadeDurationSec: Int {
        get { crossfadeDuration }
        set { crossfadeDuration = newValue }
    }
    var showNerdStats: Bool {
        get { statsForNerds }
        set { statsForNerds = newValue }
    }

    // ── Actions ───────────────────────────────────────────────────
    func signIn() { isSignedIn = true }
    func signOut() { isSignedIn = false; accountName = nil }
}

// MARK: - AudioQuality
enum AudioQuality: Int, CaseIterable, Identifiable {
    case auto = 0
    case low = 1
    case medium = 2
    case high = 3
    case lossless = 10

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .auto:     return "Auto"
        case .low:      return "Low (48kbps)"
        case .medium:   return "Medium (128kbps)"
        case .high:     return "High (256kbps)"
        case .lossless: return "Lossless"
        }
    }
}
