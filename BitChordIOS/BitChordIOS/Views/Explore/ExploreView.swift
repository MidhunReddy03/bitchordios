import SwiftUI

// MARK: - ExploreView
/// Mirrors BitChord's ExploreScreen.kt:
/// - Same feed/shelf layout as HomeScreen
/// - No "Listen now" heading (matches Android: Explore has no title)
/// - Pull-to-refresh
struct ExploreView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Explore has no heading — start directly with the feed
                    switch vm.state {
                    case .loading:
                        FeedSkeletonView()

                    case .error(let msg):
                        MessageStateView(msg, actionLabel: "Retry") { vm.load() }

                    case .success(let shelves):
                        ForEach(Array(shelves.enumerated()), id: \.offset) { i, shelf in
                            if shelf.layout == .video {
                                VideoShelfView(
                                    shelf: shelf,
                                    currentSong: playerVM.currentSong,
                                    isPlaying: playerVM.isPlaying
                                )
                            } else {
                                ShelfView(
                                    shelf: shelf,
                                    currentSong: playerVM.currentSong,
                                    isPlaying: playerVM.isPlaying
                                )
                            }
                        }
                        if vm.loadingMore {
                            ProgressView().frame(maxWidth: .infinity).padding()
                        }
                    }

                    Color.clear.frame(height: BCLayout.miniPlayerHeight + BCLayout.tabBarHeight)
                }
                .padding(.top, 8)
            }
            .background(Color.bcBackground)
            .refreshable { vm.refresh() }
            .navigationBarHidden(true)
        }
        .onAppear {
            if case .loading = vm.state { vm.load() }
        }
    }
}

// MARK: - VideoShelf (matches VideoShelfCard.kt — 16:9 thumbnails)
struct VideoShelfView: View {
    let shelf: HomeShelf
    let currentSong: Song?
    let isPlaying: Bool
    var onItemClick: ((ShelfItem) -> Void)?

    // 16:9 aspect, ~220pt wide to match Android VIDEO_CARD_WIDTH
    private let cardWidth: CGFloat = BCLayout.videoCardWidth
    private let aspectRatio: CGFloat = 16.0 / 9.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: shelf.title, subtitle: shelf.subtitle)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(shelf.items) { item in
                        VideoShelfCardView(
                            item: item,
                            isCurrent: currentSong?.videoId == item.videoId,
                            isPlaying: isPlaying && currentSong?.videoId == item.videoId,
                            cardWidth: cardWidth,
                            aspectRatio: aspectRatio,
                            onTap: { onItemClick?(item) }
                        )
                    }
                }
                .padding(.horizontal, BCLayout.pageGutter)
            }
        }
        .padding(.bottom, 26)
    }
}

struct VideoShelfCardView: View {
    let item: ShelfItem
    let isCurrent: Bool
    let isPlaying: Bool
    let cardWidth: CGFloat
    let aspectRatio: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    ArtworkImage(
                        url: item.artworkAt(ArtworkSize.cardArt),
                        cornerRadius: 12
                    )
                    .frame(width: cardWidth, height: cardWidth / aspectRatio)
                    .clipped()

                    if isCurrent && isPlaying {
                        PlayingBarsView()
                            .frame(width: 24, height: 20)
                    }
                }

                Text(item.title)
                    .font(.bcTitleSmall)
                    .foregroundColor(.bcOnBackground)
                    .lineLimit(2)
                    .frame(width: cardWidth, alignment: .leading)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.bcBodySmall)
                        .foregroundColor(.bcOnSurfaceVar)
                        .lineLimit(1)
                        .frame(width: cardWidth, alignment: .leading)
                }
            }
        }
        .frame(width: cardWidth)
    }
}

#Preview {
    ExploreView()
        .environmentObject(AppViewModel())
        .environmentObject(PlayerViewModel())
        .preferredColorScheme(.dark)
}

