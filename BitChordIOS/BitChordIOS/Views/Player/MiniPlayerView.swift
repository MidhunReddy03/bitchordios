import SwiftUI

// MARK: - MiniPlayerView
/// Collapsed player dock — sits just above the tab bar.
/// Mirrors BitChord's PlayerDock.kt: album art, title/artist (marquee),
/// play/pause button, next button. Tap → open full player.
struct MiniPlayerView: View {
    @Binding var showFullPlayer: Bool
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        if let song = playerVM.currentSong {
            HStack(spacing: 12) {
                // Artwork
                ArtworkImage(url: song.artworkAt(ArtworkSize.rowArt), cornerRadius: 8)
                    .frame(width: 46, height: 46)
                    .padding(.leading, 8)

                // Title + artist (marquee scroll)
                VStack(alignment: .leading, spacing: 2) {
                    MarqueeText(text: song.title, font: .bcTitleSmall, color: .bcOnBackground)
                    Text(song.artist)
                        .font(.bcBodySmall)
                        .foregroundColor(.bcOnSurfaceVariant)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Play / Pause
                Button(action: { playerVM.playPause() }) {
                    Image(systemName: playerVM.isLoading
                          ? "arrow.triangle.2.circlepath"
                          : (playerVM.isPlaying ? "pause.fill" : "play.fill"))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.bcOnBackground)
                        .frame(width: 44, height: 44)
                }

                // Next
                Button(action: { playerVM.next() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(playerVM.hasNext ? .bcOnBackground : .bcOnSurfaceVariant)
                        .frame(width: 44, height: 44)
                }
                .disabled(!playerVM.hasNext)
                .padding(.trailing, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: BCLayout.miniPlayerHeight)
            .contentShape(Rectangle())
            .onTapGesture { showFullPlayer = true }
        }
    }
}

// MARK: - MarqueeText (scrolling text for long song titles)
struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let containerW = geo.size.width
            ZStack(alignment: .leading) {
                // Measure text width
                Text(text)
                    .font(font)
                    .foregroundColor(.clear)
                    .lineLimit(1)
                    .background(GeometryReader { tg in
                        Color.clear.preference(key: TextWidthKey.self, value: tg.size.width)
                    })
                    .onPreferenceChange(TextWidthKey.self) { w in
                        textWidth = w
                        containerWidth = containerW
                        startMarqueeIfNeeded()
                    }

                Text(text + (textWidth > containerW ? "        " + text : ""))
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize()
                    .offset(x: offset)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
        }
        .frame(height: 20)
    }

    private func startMarqueeIfNeeded() {
        guard textWidth > containerWidth else { offset = 0; return }
        let gap = textWidth + 32
        withAnimation(.linear(duration: Double(gap) / 50).repeatForever(autoreverses: false)) {
            offset = -gap
        }
    }
}

private struct TextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
