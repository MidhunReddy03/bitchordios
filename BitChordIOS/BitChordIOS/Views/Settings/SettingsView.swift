// SettingsView.swift
// BitChordIOS
// Android ref: sharedUi/.../ui/screens/AppSettings.kt

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @EnvironmentObject private var playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // ── Accounts ─────────────────────────────────────────
                Section("Accounts") {
                    AccountRow(
                        icon: "music.note",
                        label: "YouTube Music",
                        status: appVM.isSignedIn ? "Connected" : "Not connected",
                        isConnected: appVM.isSignedIn
                    )
                    AccountRow(
                        icon: "music.quarternote.3",
                        label: "Spotify",
                        status: "Not connected",
                        isConnected: false
                    )
                    AccountRow(
                        icon: "gamecontroller",
                        label: "Discord",
                        status: "Not connected",
                        isConnected: false
                    )
                    AccountRow(
                        icon: "waveform",
                        label: "Last.fm",
                        status: "Not connected",
                        isConnected: false
                    )
                    AccountRow(
                        icon: "headphones",
                        label: "ListenBrainz",
                        status: "Not connected",
                        isConnected: false
                    )
                }

                // ── Playback ─────────────────────────────────────────
                Section("Playback") {
                    Toggle("Gapless playback", isOn: $appVM.gaplessEnabled)
                    // Android ref: AppSettings.kt → CrossfadeSetting
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Crossfade")
                            Spacer()
                            Text(appVM.crossfadeDuration == 0
                                 ? "Off"
                                 : "\(appVM.crossfadeDuration)s")
                                .foregroundColor(.bcOnSurfaceVariant)
                        }
                        Slider(value: Binding(
                            get: { Double(appVM.crossfadeDuration) },
                            set: { appVM.crossfadeDuration = Int($0) }
                        ), in: 0...12, step: 1)
                        .tint(.bcPrimary)
                    }
                    Toggle("Skip silence", isOn: $appVM.skipSilence)
                    // Android ref: AppSettings.kt → NormalizationSetting
                    Toggle("Normalize volume", isOn: $appVM.normalizeVolume)
                    Toggle("Autoplay", isOn: $playerVM.autoplayEnabled)
                }

                // ── Audio Quality ─────────────────────────────────────
                Section("Audio Quality") {
                    Picker("Wi-Fi quality", selection: $appVM.wifiQuality) {
                        Text("Auto").tag(AudioQuality.auto)
                        Text("Low (48kbps)").tag(AudioQuality.low)
                        Text("Medium (128kbps)").tag(AudioQuality.medium)
                        Text("High (256kbps)").tag(AudioQuality.high)
                    }
                    Picker("Cellular quality", selection: $appVM.cellularQuality) {
                        Text("Auto").tag(AudioQuality.auto)
                        Text("Low (48kbps)").tag(AudioQuality.low)
                        Text("Medium (128kbps)").tag(AudioQuality.medium)
                        Text("High (256kbps)").tag(AudioQuality.high)
                    }
                    // TODO: USB DAC bit-perfect — Android ref: AppSettings.kt → UsbDacSetting
                    // iOS equivalent would use AVAudioSession + CoreAudio routing;
                    // Lightning/USB-C audio works differently from Android USB DAC.
                    // Label shows "USB DAC" and is disabled until implemented.
                    HStack {
                        Text("USB DAC (bit-perfect)")
                        Spacer()
                        Text("Not supported on iOS")
                            .font(BCFont.caption)
                            .foregroundColor(.bcOnSurfaceVariant)
                    }
                }

                // ── Appearance ────────────────────────────────────────
                Section("Appearance") {
                    Toggle("Full-bleed artwork", isOn: $appVM.fullBleedArtwork)
                    Toggle("Reduce motion", isOn: $appVM.reduceMotion)
                }

                // ── Now Playing ───────────────────────────────────────
                Section("Now Playing") {
                    Toggle("Stats for nerds", isOn: $appVM.statsForNerds)
                    NavigationLink("Sleep timer") {
                        // Reuses SleepTimerView from NowPlayingView
                        SleepTimerSettingsView()
                    }
                }

                // ── About ─────────────────────────────────────────────
                Section("About") {
                    LabeledContent("Version", value: "1.9.1 (iOS port)")
                    LabeledContent("Original app", value: "BitChord for Android")
                    Link("GitHub", destination: URL(string: "https://github.com/music/bitchord")!)
                        .foregroundColor(.bcPrimary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.bcBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.bcPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - AccountRow
private struct AccountRow: View {
    let icon: String
    let label: String
    let status: String
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .foregroundColor(isConnected ? .bcPrimary : .bcOnSurfaceVariant)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(BCFont.bodyMedium)
                Text(status)
                    .font(BCFont.caption)
                    .foregroundColor(isConnected ? .bcPrimary : .bcOnSurfaceVariant)
            }
            Spacer()
            Image(systemName: isConnected ? "checkmark.circle.fill" : "chevron.right")
                .foregroundColor(isConnected ? .bcPrimary : .bcOnSurfaceVariant)
        }
    }
}

// MARK: - SleepTimerSettingsView
/// Standalone sleep timer settings reachable from Settings.
/// Full interactive version lives in NowPlayingView → SleepTimerView.
private struct SleepTimerSettingsView: View {
    @EnvironmentObject private var playerVM: PlayerViewModel

    private let presets: [(String, TimeInterval)] = [
        ("5 min", 300), ("10 min", 600), ("15 min", 900),
        ("20 min", 1200), ("30 min", 1800), ("45 min", 2700),
        ("60 min", 3600)
    ]

    var body: some View {
        List {
            Section {
                Button("End of track") {
                    playerVM.setSleepTimer(.endOfTrack)
                }
                .foregroundColor(.bcOnSurface)
            }
            Section("Duration") {
                ForEach(presets, id: \.0) { label, duration in
                    Button(label) {
                        playerVM.setSleepTimer(.duration(duration))
                    }
                    .foregroundColor(.bcOnSurface)
                }
            }
            if playerVM.sleepTimer != nil {
                Section {
                    Button("Cancel timer", role: .destructive) {
                        playerVM.cancelSleepTimer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bcBackground)
        .navigationTitle("Sleep Timer")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

// MARK: - AppViewModel extensions for settings
extension AppViewModel {
    // These are already declared in AppViewModel.swift; here as a reminder
    // of which properties SettingsView binds to.
    // All properties: gaplessEnabled, crossfadeDuration, skipSilence,
    // normalizeVolume, fullBleedArtwork, reduceMotion, statsForNerds,
    // wifiQuality, cellularQuality
}

