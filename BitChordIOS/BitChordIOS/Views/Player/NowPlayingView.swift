import SwiftUI

// MARK: - NowPlayingView
/// Full-screen player — mirrors BitChord's NowPlayingScreen.kt exactly:
///
/// Layout (portrait, iPhone 13 390pt wide):
///   ┌─────────────────────────────────┐
///   │ ▽  drag handle                  │  ← 32pt dismiss strip
///   │                                 │
///   │  [Playing from: playlist]        │  ← origin caption, tappable
///   │                                 │
///   │  ╔══════════════════════════╗  │
///   │  ║                          ║  │
///   │  ║      Album Artwork        ║  │  ← shrinks when paused (0.88×)
///   │  ║                          ║  │
///   │  ╚══════════════════════════╝  │
///   │  [Stats for Nerds]              │  ← optional, labelSmall
///   │                                 │
///   │  Song Title (marquee)  ♥  ⋯   │  ← like + menu
///   │  Artist                         │
///   │                                 │
///   │  ━━━━━━━━━━━━━━━━━━━━━━━━━━   │  ← ThinSlider scrubber
///   │  0:32           [Lossless]  -3:28│
///   │                                 │
///   │     ⏮   ⏵/⏸   ⏭           │  ← transport (74dp play)
///   │                                 │
///   │  🔈 ━━━━━━━━━━━━━━━━━━━━ 🔊  │  ← volume row
///   │                                 │
///   │   ♪       [AirPlay]      ≡    │  ← lyrics / output / queue row
///   └─────────────────────────────────┘
///                 ▬  (home indicator safe area)
struct NowPlayingView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var dragOffset: CGFloat = 0
    @State private var showLyrics: Bool = false
    @State private var showQueue: Bool = false
    @State private var showOutputSheet: Bool = false
    @State private var showMenu: Bool = false
    @State private var showLyricsProviderSheet: Bool = false
    @State private var showLyricsOffsetSheet: Bool = false

    // Artwork scale: 1.0 playing, 0.88 paused (matches ARTWORK_PAUSE_SHRINK_SCALE)
    private var artworkScale: CGFloat { playerVM.isPlaying ? 1.0 : 0.88 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // — Artwork mesh / blurred backdrop —
                artworkBackdrop

                // — Main content column —
                VStack(spacing: 0) {
                    // Drag handle + dismiss strip (32pt, matches DISMISS_STRIP_HEIGHT)
                    dragHandle

                    if showLyrics {
                        // — Lyrics panel (swaps in for artwork+controls) —
                        LyricsPanelView()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if showQueue {
                        // — Queue panel —
                        QueuePanelView()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        mainPlayerContent(geo: geo)
                    }
                }
                .frame(maxWidth: min(geo.size.width, BCLayout.playerMaxWidth))
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .gesture(
            DragGesture()
                .onChanged { v in dragOffset = max(0, v.translation.height) }
                .onEnded { v in
                    if v.translation.height > 100 || v.predictedEndTranslation.height > 300 {
                        dismiss()
                    } else {
                        withAnimation(.spring()) { dragOffset = 0 }
                    }
                }
        )
        .offset(y: dragOffset)
        .animation(.interactiveSpring(), value: dragOffset)
        .sheet(isPresented: $showOutputSheet) {
            AudioOutputSheetView()
                .environmentObject(playerVM)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Options", isPresented: $showMenu, titleVisibility: .visible) {
            Button("Lyrics Provider") { showLyricsProviderSheet = true }
            Button("Adjust Lyric Timing") { showLyricsOffsetSheet = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showLyricsProviderSheet) {
            LyricsProviderSheet()
                .environmentObject(playerVM)
        }
        .sheet(isPresented: $showLyricsOffsetSheet) {
            LyricsOffsetSheet()
                .environmentObject(playerVM)
        }
    }

    // MARK: - Artwork backdrop (ArtworkMeshBackdrop equivalent)
    @ViewBuilder private var artworkBackdrop: some View {
        if let song = playerVM.currentSong,
           let url = song.artworkAt(ArtworkSize.playerArt) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 60)
                        .scaleEffect(1.3)
                        .saturation(1.4)
                        .overlay(Color.black.opacity(0.55))
                }
            }
        } else {
            Color.black
        }
    }

    // MARK: - Drag handle
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.white.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 12)
            .frame(height: 32) // DISMISS_STRIP_HEIGHT
            .frame(maxWidth: .infinity)
    }

    // MARK: - Main player content
    @ViewBuilder private func mainPlayerContent(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            if let song = playerVM.currentSong {
                // Origin caption ("Playing from: Album Name")
                originCaption(song: song)

                // — Artwork —
                artworkSection(song: song, width: geo.size.width)

                // — Stats for nerds —
                if let stats = playerVM.nerdStats {
                    Text(stats.describe() ?? "")
                        .font(.bcLabelSmall)
                        .foregroundColor(.white.opacity(0.65))
                        .shadow(color: .black.opacity(0.55), radius: 4, y: 1)
                        .lineLimit(1)
                        .padding(.top, 8)
                }

                // Space expands to push controls toward bottom
                Spacer(minLength: 0)

                // — Song title + like + menu —
                songTitleRow(song: song)

                Spacer(minLength: 16)

                // — Scrubber —
                PlayerScrubberView()
                    .padding(.horizontal, BCLayout.playerGutter)

                // — Control gap spread (matches lastControlSpread logic) —
                Spacer(minLength: 8).frame(maxHeight: 24) // CONTROL_GAP_SPREAD_MAX

                // — Transport row —
                TransportRowView()
                    .padding(.horizontal, BCLayout.playerGutter)

                Spacer(minLength: 8).frame(maxHeight: 24)

                // — Volume row —
                VolumeRowView()
                    .padding(.horizontal, BCLayout.playerGutter)

                Spacer(minLength: 16)

                // — Action row: Lyrics / Output / Queue —
                PlayerActionRowView(
                    lyricsOpen: showLyrics,
                    queueOpen: showQueue,
                    onToggleLyrics: { withAnimation(.spring(response: 0.35)) { showLyrics.toggle(); showQueue = false } },
                    onToggleQueue:  { withAnimation(.spring(response: 0.35)) { showQueue.toggle(); showLyrics = false } },
                    onOpenOutput:   { showOutputSheet = true }
                )
                .padding(.horizontal, BCLayout.playerGutter)

                // Home indicator safe area
                Spacer().frame(height: BCLayout.homeIndicator + 8)
            }
        }
    }

    // MARK: - Origin caption
    @ViewBuilder private func originCaption(song: Song) -> some View {
        Text(song.playbackSource.map { "Playing from: \($0)" } ?? "")
            .font(.bcLabelSmall.weight(.semibold))
            .foregroundColor(.white.opacity(0.9))
            .shadow(color: .black.opacity(0.55), radius: 4, y: 1)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, BCLayout.playerGutter)
            .padding(.top, 4)
    }

    // MARK: - Artwork section
    @ViewBuilder private func artworkSection(song: Song, width: CGFloat) -> some View {
        let gutter = BCLayout.playerGutter
        let size = min(width - gutter * 2, BCLayout.playerMaxWidth - gutter * 2)
        ArtworkImage(url: song.artworkAt(ArtworkSize.playerArt), cornerRadius: 12)
            .frame(width: size, height: size)
            .scaleEffect(artworkScale)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: artworkScale)
            .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            .frame(maxWidth: .infinity)
            .padding(.top, BCLayout.artBoxTopPad)
            .frame(height: size + BCLayout.artBoxTopPad)
    }

    // MARK: - Song title row
    @ViewBuilder private func songTitleRow(song: Song) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.bcHeadlineLarge)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(song.artist)
                    .font(.bcBodyLarge)
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Like button (matches CircleGlyph with StarFilled / Star)
            LikeButton()
                .environmentObject(playerVM)

            // Menu button (MoreHoriz)
            Button(action: { showMenu = true }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, BCLayout.playerGutter)
    }
}

// MARK: - Like Button
private struct LikeButton: View {
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        Button(action: { playerVM.toggleLike() }) {
            Image(systemName: playerVM.likeStatus == .liked ? "star.fill" : "star")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(playerVM.likeStatus == .liked ? 0.25 : 0.15))
                .clipShape(Circle())
        }
    }
}

// MARK: - PlayerScrubberView (matches PlayerScrubber.kt)
/// Thin hairline scrub bar + elapsed/remaining timestamps + quality badge
struct PlayerScrubberView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @State private var isDragging = false
    @State private var dragValue: Float = 0

    private var fraction: Float {
        guard playerVM.durationMs > 0 else { return 0 }
        return Float(playerVM.positionMs) / Float(playerVM.durationMs)
    }

    private var displayFraction: Float { isDragging ? dragValue : fraction }

    var body: some View {
        VStack(spacing: 0) {
            // ThinSlider
            ThinSliderView(
                value: displayFraction,
                onDragChanged: { v in isDragging = true; dragValue = v },
                onDragEnded: { v in
                    playerVM.seek(toFraction: v)
                    isDragging = false
                }
            )

            // Timestamps + quality badge
            HStack {
                Text(formatTime(ms: Int64(displayFraction * Float(playerVM.durationMs))))
                    .font(.bcLabelMedium)
                    .foregroundColor(.white.opacity(0.55))

                Spacer()

                // Quality badge (Lossless / Hi-Res / Dolby Atmos)
                if let song = playerVM.currentSong, let badge = song.sourceQualityBadge {
                    SourceQualityBadgeView(quality: badge)
                }

                Spacer()

                Text("-" + formatTime(ms: playerVM.durationMs - Int64(displayFraction * Float(playerVM.durationMs))))
                    .font(.bcLabelMedium)
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.top, 4)
        }
    }

    private func formatTime(ms: Int64) -> String {
        let total = Int(ms / 1000)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - ThinSlider (matches ThinSlider.kt: hairline that expands on drag)
struct ThinSliderView: View {
    let value: Float
    let onDragChanged: (Float) -> Void
    let onDragEnded: (Float) -> Void

    @State private var isDragging = false
    @GestureState private var dragLocation: CGFloat = 0

    private let idleHeight: CGFloat = 4
    private let activeHeight: CGFloat = 10
    private let thumbSize: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let filledW = CGFloat(value) * w

            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: isDragging ? activeHeight : idleHeight)

                // Filled portion
                Capsule()
                    .fill(Color.white)
                    .frame(width: max(0, filledW), height: isDragging ? activeHeight : idleHeight)

                // Thumb (only while dragging, matches ThinSlider)
                if isDragging {
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(radius: 4)
                        .offset(x: max(0, filledW - thumbSize / 2))
                }
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        isDragging = true
                        let fraction = Float(max(0, min(v.location.x, w)) / w)
                        onDragChanged(fraction)
                    }
                    .onEnded { v in
                        isDragging = false
                        let fraction = Float(max(0, min(v.location.x, w)) / w)
                        onDragEnded(fraction)
                    }
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isDragging)
        }
        .frame(height: thumbSize)
    }
}

// MARK: - TransportRowView (matches TransportRow.kt)
/// Previous / Play-Pause (74pt) / Next row
struct TransportRowView: View {
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        HStack {
            // Previous
            Button(action: { playerVM.previous() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(playerVM.hasPrevious ? .white : .white.opacity(0.4))
                    .frame(width: 60, height: 60)
            }
            .disabled(!playerVM.hasPrevious)

            Spacer()

            // Play / Pause (74pt touch, matches PLAYER_SKIP_ICON_SIZE logic)
            Button(action: { playerVM.playPause() }) {
                if playerVM.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.3)
                        .frame(width: 92, height: 92)
                } else {
                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 92, height: 92)
                }
            }

            Spacer()

            // Next
            Button(action: { playerVM.next() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(playerVM.hasNext ? .white : .white.opacity(0.4))
                    .frame(width: 60, height: 60)
            }
            .disabled(!playerVM.hasNext)
        }
    }
}

// MARK: - VolumeRowView (matches VolumeRow.kt: speaker icons + ThinSlider)
struct VolumeRowView: View {
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))

            ThinSliderView(
                value: playerVM.volumeLevel,
                onDragChanged: { v in playerVM.setVolume(v) },
                onDragEnded: { v in playerVM.setVolume(v) }
            )
            .frame(maxWidth: .infinity)

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(height: 32) // VOLUME_ROW_HEIGHT 32dp
    }
}

// MARK: - PlayerActionRowView (matches PlayerActionRow.kt)
/// Lyrics / Output-Party pill / Queue row at the bottom
struct PlayerActionRowView: View {
    let lyricsOpen: Bool
    let queueOpen: Bool
    let onToggleLyrics: () -> Void
    let onToggleQueue: () -> Void
    let onOpenOutput: () -> Void
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        HStack {
            // Lyrics glyph (BitChordIcons.LyricsQuote → quotation bubble)
            BottomGlyphButton(
                icon: "text.bubble.fill",
                highlighted: lyricsOpen,
                action: onToggleLyrics
            )

            Spacer()

            // Centre pill (Output / queue modes)
            if queueOpen {
                // Queue-open pill: shuffle | repeat | autoplay
                QueueModesPillView()
            } else {
                // Normal pill: AirPlay / output
                OutputPillView(onTap: onOpenOutput)
            }

            Spacer()

            // Queue glyph
            BottomGlyphButton(
                icon: "list.bullet",
                highlighted: queueOpen,
                action: onToggleQueue
            )
        }
    }
}

private struct BottomGlyphButton: View {
    let icon: String
    let highlighted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(highlighted ? .white : .white.opacity(0.65))
                .frame(width: 44, height: 44)
        }
    }
}

private struct OutputPillView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "airplayaudio")
                    .font(.system(size: 16))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

private struct QueueModesPillView: View {
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Shuffle
            PillSegmentButton(
                icon: playerVM.shuffleEnabled ? "shuffle" : "shuffle",
                highlighted: playerVM.shuffleEnabled,
                action: { playerVM.toggleShuffle() }
            )
            Divider().frame(height: 20).background(Color.white.opacity(0.2))
            // Repeat
            PillSegmentButton(
                icon: playerVM.repeatMode == .one ? "repeat.1" : "repeat",
                highlighted: playerVM.repeatMode != .off,
                action: { playerVM.cycleRepeat() }
            )
            Divider().frame(height: 20).background(Color.white.opacity(0.2))
            // Autoplay (infinity)
            PillSegmentButton(
                icon: "infinity",
                highlighted: playerVM.autoplayEnabled,
                action: { playerVM.toggleAutoplay() }
            )
        }
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
    }
}

private struct PillSegmentButton: View {
    let icon: String
    let highlighted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(highlighted ? .white : .white.opacity(0.5))
                .frame(width: 52, height: 36)
        }
    }
}

// MARK: - LyricsPanelView (matches SyncedLyricsPanel.kt + PlayerLyrics.kt)
struct LyricsPanelView: View {
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(playerVM.syncedLyrics.enumerated()), id: \.offset) { i, line in
                        Text(line.text)
                            .font(.system(size: i == playerVM.currentLyricIndex ? 26 : 20,
                                         weight: i == playerVM.currentLyricIndex ? .bold : .regular))
                            .foregroundColor(i == playerVM.currentLyricIndex ? .white : .white.opacity(0.4))
                            .padding(.horizontal, BCLayout.playerGutter)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(i)
                            .animation(.spring(response: 0.4), value: playerVM.currentLyricIndex)
                    }
                    if playerVM.syncedLyrics.isEmpty {
                        MessageStateView("No lyrics available")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Color.clear.frame(height: BCLayout.homeIndicator + 80)
                }
            }
            .onChange(of: playerVM.currentLyricIndex) { idx in
                withAnimation(.spring(response: 0.5)) {
                    proxy.scrollTo(max(0, idx - 1), anchor: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - QueuePanelView (matches PlayerQueue.kt)
struct QueuePanelView: View {
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Up Next")
                .font(.bcHeadlineLarge)
                .foregroundColor(.white)
                .padding(.horizontal, BCLayout.playerGutter)
                .padding(.top, 8)
                .padding(.bottom, 12)

            List {
                ForEach(Array(playerVM.queue.enumerated()), id: \.offset) { i, song in
                    QueueRowView(
                        song: song,
                        isCurrent: i == playerVM.queueIndex,
                        onTap: {
                            playerVM.queueIndex = i
                            // playerVM.loadCurrentSong() — hook after connecting
                        }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .background(Color.clear)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct QueueRowView: View {
    let song: Song
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ArtworkImage(url: song.artworkAt(ArtworkSize.rowArt), cornerRadius: 7)
                .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.bcTitleSmall)
                    .foregroundColor(isCurrent ? .bcPrimary : .white)
                    .lineLimit(1)
                Text(song.artist)
                    .font(.bcBodySmall)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if isCurrent {
                PlayingBarsView(color: .bcPrimary)
                    .frame(width: 20, height: 16)
            }
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, BCLayout.playerGutter)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - AudioOutputSheet (matches AudioOutputSheet.kt)
struct AudioOutputSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Output") {
                    AudioOutputRow(icon: "iphone", label: "iPhone", selected: true)
                    AudioOutputRow(icon: "airplayaudio", label: "AirPlay", selected: false)
                    AudioOutputRow(icon: "headphones", label: "Bluetooth", selected: false)
                }
                Section("Playback") {
                    // Playback speed (matches PlayerControls.kt speed slider)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Speed: \(String(format: "%.2f", playerVM.playbackSpeed))×")
                            .font(.bcBodyMedium)
                            .foregroundColor(.bcOnBackground)
                        Slider(value: Binding(
                            get: { Double(playerVM.playbackSpeed) },
                            set: { playerVM.setSpeed(Float($0)) }
                        ), in: 0.5...2.0, step: 0.25)
                    }
                    .listRowBackground(Color.bcSurface)

                    // Sleep timer
                    NavigationLink("Sleep Timer") {
                        SleepTimerView()
                            .environmentObject(playerVM)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.bcBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct AudioOutputRow: View {
    let icon: String
    let label: String
    let selected: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.bcPrimary)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.bcOnBackground)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .foregroundColor(.bcPrimary)
            }
        }
        .listRowBackground(Color.bcSurface)
    }
}

// MARK: - SleepTimerView (matches BitChord's sleep-timer sheet)
struct SleepTimerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.dismiss) var dismiss
    private let presets = [5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        List {
            Section {
                Button("End of track") {
                    playerVM.setSleepTimerAfterTrack()
                    dismiss()
                }
                .foregroundColor(.bcOnBackground)
                .listRowBackground(Color.bcSurface)
            }

            Section("Minutes") {
                ForEach(presets, id: \.self) { mins in
                    Button("\(mins) minutes") {
                        playerVM.setSleepTimer(minutes: mins)
                        dismiss()
                    }
                    .foregroundColor(.bcOnBackground)
                    .listRowBackground(Color.bcSurface)
                }
            }

            if playerVM.sleepTimerActive {
                Section {
                    Button("Cancel timer", role: .destructive) {
                        playerVM.cancelSleepTimer()
                        dismiss()
                    }
                    .listRowBackground(Color.bcSurface)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.bcBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Sleep Timer")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NowPlayingView()
        .environmentObject(PlayerViewModel())
        .preferredColorScheme(.dark)
}

