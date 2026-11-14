import SwiftUI

// MARK: - HomeView
/// Mirrors BitChord's HomeScreen.kt exactly:
/// - BitChord wordmark logo at top
/// - Top Picks row (TopPicksShelf)
/// - Recents shelf (four-to-a-column pager, ShelfLayout.LIST)
/// - Infinite-scrolling shelves of cards (Shelf)
/// - Pull-to-refresh
/// - Sign-in banner when not signed in
struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var appVM: AppViewModel
    @State private var showSettings = false
    @State private var showSignIn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // — Logo header (matches HomeTitle in Kotlin) —
                    HomeTitle(onSettingsTap: { showSettings = true })

                    // — Sign-in banner —
                    if !appVM.isSignedIn {
                        SignInBannerView(onSignIn: { showSignIn = true })
                    }

                    // — Top Picks shelf —
                    if let picks = vm.topPicks, !picks.isEmpty {
                        TopPicksShelfView(picks: picks)
                    } else if vm.topPicksLoading {
                        TopPicksSkeletonView()
                    }

                    // — Main feed —
                    switch vm.state {
                    case .loading:
                        FeedSkeletonView()

                    case .error(let msg):
                        MessageStateView(msg, actionLabel: "Retry") { vm.load() }

                    case .success(let shelves):
                        ForEach(Array(shelves.enumerated()), id: \.offset) { i, shelf in
                            if shelf.layout == .list || (i == 0 && shelf.title.lowercased() == "recents") {
                                RecentShelfView(
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
                        // Load-more trigger
                        if vm.loadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                // Extra padding so last shelf clears mini-player + tab bar
                .padding(.bottom, BCLayout.miniPlayerHeight + BCLayout.tabBarHeight)
            }
            .background(Color.bcBackground)
            .refreshable { vm.refresh() }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appVM)
                    .environmentObject(playerVM)
            }
            .sheet(isPresented: $showSignIn) {
                YTMusicLoginView()
                    .environmentObject(appVM)
            }
        }
        .onAppear { if case .loading = vm.state { vm.load() } }
    }
}

// MARK: - HomeTitle (BitChord logo wordmark, matches HomeTitle.kt)
private struct HomeTitle: View {
    var onSettingsTap: (() -> Void)? = nil

    var body: some View {
        HStack {
            Image(systemName: "music.note.list") // Replace with BitChord logo asset
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.bcOnBackground)
                .frame(height: 36)
            Spacer()
            if let onSettingsTap = onSettingsTap {
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(.bcOnBackground)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(.horizontal, BCLayout.pageGutter)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Shelf (card row, matches Shelf composable in HomeScreen.kt)
struct ShelfView: View {
    let shelf: HomeShelf
    let currentSong: Song?
    let isPlaying: Bool
    var onItemClick: ((ShelfItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: shelf.title, subtitle: shelf.subtitle)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(shelf.items) { item in
                        ShelfCardView(
                            item: item,
                            isCurrent: currentSong?.videoId == item.videoId,
                            isPlaying: isPlaying && currentSong?.videoId == item.videoId,
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

// MARK: - ShelfCard (matches ShelfCard.kt)
struct ShelfCardView: View {
    let item: ShelfItem
    let isCurrent: Bool
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .center) {
                    ArtworkImage(
                        url: item.artworkAt(ArtworkSize.cardArt),
                        cornerRadius: 10
                    )
                    .frame(width: BCLayout.shelfCardWidth, height: BCLayout.shelfCardWidth)
                    .aspectRatio(1, contentMode: .fill)

                    if isCurrent && isPlaying {
                        PlayingBarsView()
                            .frame(width: 24, height: 20)
                    }
                }

                Text(item.title)
                    .font(.bcTitleSmall)
                    .foregroundColor(.bcOnBackground)
                    .lineLimit(2)
                    .frame(width: BCLayout.shelfCardWidth, alignment: .leading)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.bcBodySmall)
                        .foregroundColor(.bcOnSurfaceVar)
                        .lineLimit(1)
                        .frame(width: BCLayout.shelfCardWidth, alignment: .leading)
                }
            }
        }
        .frame(width: BCLayout.shelfCardWidth)
    }
}

// MARK: - RecentShelf (four-to-a-column pager, matches RecentShelf.kt)
struct RecentShelfView: View {
    let shelf: HomeShelf
    let currentSong: Song?
    let isPlaying: Bool
    var onItemClick: ((ShelfItem) -> Void)?

    // 4 items per column, paged horizontally
    private var columns: [[ShelfItem]] {
        let perColumn = 4
        return stride(from: 0, to: shelf.items.count, by: perColumn).map {
            Array(shelf.items[$0..<min($0 + perColumn, shelf.items.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: shelf.title, subtitle: shelf.subtitle)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                        VStack(spacing: 0) {
                            ForEach(column) { item in
                                CompactTrackRowView(
                                    item: item,
                                    isCurrent: currentSong?.videoId == item.videoId,
                                    isPlaying: isPlaying && currentSong?.videoId == item.videoId,
                                    onTap: { onItemClick?(item) }
                                )
                            }
                        }
                        .frame(width: 200) // trackColumnWidth equivalent
                    }
                }
                .padding(.horizontal, BCLayout.pageGutter)
            }
        }
        .padding(.bottom, 26)
    }
}

// MARK: - CompactTrackRow (matches CompactTrackRow.kt)
struct CompactTrackRowView: View {
    let item: ShelfItem
    let isCurrent: Bool
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    ArtworkImage(
                        url: item.artworkAt(ArtworkSize.rowArt),
                        cornerRadius: 7
                    )
                    .frame(width: BCLayout.rowArtSize, height: BCLayout.rowArtSize)

                    if isCurrent && isPlaying {
                        PlayingBarsView()
                            .frame(width: 20, height: 16)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.bcTitleSmall)
                        .foregroundColor(.bcOnBackground)
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.bcBodySmall)
                        .foregroundColor(.bcOnSurfaceVar)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.bcOnSurfaceVar)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - SectionHeader (matches SectionHeader.kt)
struct SectionHeaderView: View {
    let title: String
    let subtitle: String
    var onShowAll: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bcTitleMedium)
                    .foregroundColor(.bcOnBackground)
                    .lineLimit(2)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.bcBodyMedium)
                        .foregroundColor(.bcOnSurfaceVar)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let onShowAll {
                Button("Show all", action: onShowAll)
                    .font(.bcTitleSmall)
                    .foregroundColor(.bcPrimary)
            }
        }
        .padding(.horizontal, BCLayout.pageGutter)
        .padding(.vertical, 10)
    }
}

// MARK: - Skeletons
struct FeedSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonView().frame(width: 150, height: 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(0..<4, id: \.self) { _ in
                                SkeletonView()
                                    .frame(width: BCLayout.shelfCardWidth, height: BCLayout.shelfCardWidth + 44)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, BCLayout.pageGutter)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

struct TopPicksSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonView().frame(width: 180, height: 16).padding(.horizontal, BCLayout.pageGutter)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonView().frame(width: 120, height: 160).cornerRadius(12)
                    }
                }
                .padding(.horizontal, BCLayout.pageGutter)
            }
        }
        .padding(.bottom, 26)
    }
}

// MARK: - TopPicksShelf (matches TopPicksShelf.kt)
struct TopPicksShelfView: View {
    let picks: [TopPick]
    var onTap: ((TopPick) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Top Picks for You")
                .font(.bcTitleMedium)
                .foregroundColor(.bcOnBackground)
                .padding(.horizontal, BCLayout.pageGutter)
                .padding(.vertical, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(picks) { pick in
                        Button(action: { onTap?(pick) }) {
                            VStack(alignment: .leading, spacing: 6) {
                                ArtworkImage(
                                    url: URL(string: pick.thumbnailUrl ?? ""),
                                    cornerRadius: 12
                                )
                                .frame(width: 120, height: 120)

                                Text(pick.title)
                                    .font(.bcLabelMedium)
                                    .foregroundColor(.bcOnBackground)
                                    .lineLimit(1)
                                    .frame(width: 120, alignment: .leading)

                                Text(pick.artist)
                                    .font(.bcBodySmall)
                                    .foregroundColor(.bcOnSurfaceVar)
                                    .lineLimit(1)
                                    .frame(width: 120, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(.horizontal, BCLayout.pageGutter)
            }
        }
        .padding(.bottom, 26)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppViewModel())
        .environmentObject(PlayerViewModel())
        .preferredColorScheme(.dark)
}

