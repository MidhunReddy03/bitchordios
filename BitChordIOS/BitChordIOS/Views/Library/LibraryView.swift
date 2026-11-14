import SwiftUI

// MARK: - LibraryView
/// Mirrors BitChord's LibraryScreen.kt exactly:
/// - Large "Library" heading
/// - Replay cards row (placeholder, matches ReplayCard.kt)
/// - Library links list (Downloads, Local, SMB, etc.)
/// - On-device shelf
/// - Sign-in gate for signed-out users
/// - Playlists shelf with "New playlist" leading card
/// - Albums, Artists, Subscriptions shelves (5-card max + Show all)
/// - Pull-to-refresh
struct LibraryView: View {
    @StateObject private var vm = LibraryViewModel()
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @State private var showNewPlaylistSheet = false
    @State private var showSignIn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // — Large heading (matches displayLarge typography) —
                    Text("Library")
                        .font(.bcDisplayLarge)
                        .foregroundColor(.bcOnBackground)
                        .padding(.horizontal, BCLayout.pageGutter)
                        .padding(.vertical, 8)

                    // — Replay cards row —
                    if appVM.isSignedIn {
                        ReplayCardRowView(cards: [
                            ("Minutes", "14,280", "Top 5% of listeners", nil),
                            ("Top Artist", "Hans Zimmer", "182 tracks played", nil),
                            ("Top Song", "Time", "Inception · 48 plays", nil),
                            ("Top Album", "Interstellar", "32 hours total", nil)
                        ])
                    }

                    // — Library links (Downloads, Local Music, SMB, etc.) —
                    if !vm.links.isEmpty {
                        LibraryLinkListView(links: vm.links) { item in
                            // navigate to item
                        }
                    }

                    // — On-device shelf —
                    if !vm.deviceItems.isEmpty {
                        LibraryGridShelfView(
                            title: "On Device",
                            items: vm.deviceItems,
                            onItemTap: { _ in },
                            onShowAll: nil
                        )
                    }

                    // — Not signed in —
                    if !appVM.isSignedIn {
                        EmptyPlaylistsShelfView(
                            onNewPlaylist: { showNewPlaylistSheet = true }
                        )
                        MessageStateView(
                            "Sign in to see your library",
                            actionLabel: "Sign in",
                            onAction: { showSignIn = true }
                        )
                    } else {
                        // — Signed-in library content —
                        switch vm.state {
                        case .loading:
                            LibrarySkeletonView()

                        case .error(let msg):
                            MessageStateView(msg, actionLabel: "Retry") { vm.load() }

                        case .success(let page):
                            let hasPlaylists = page.shelves.contains { $0.title == "Playlists" }
                            if !hasPlaylists {
                                EmptyPlaylistsShelfView(onNewPlaylist: { showNewPlaylistSheet = true })
                            }
                            ForEach(page.shelves) { shelf in
                                LibraryGridShelfView(
                                    title: shelf.title,
                                    items: shelf.items,
                                    isPlaylistShelf: shelf.title == "Playlists",
                                    onNewPlaylist: shelf.title == "Playlists" ? { showNewPlaylistSheet = true } : nil,
                                    onItemTap: { _ in },
                                    onShowAll: shelf.items.count > 5 ? { } : nil
                                )
                            }
                        }
                    }

                    Color.clear.frame(height: BCLayout.miniPlayerHeight + BCLayout.tabBarHeight)
                }
            }
            .background(Color.bcBackground)
            .refreshable { vm.refresh() }
            .navigationBarHidden(true)
        }
        .onAppear { if case .loading = vm.state { vm.load() } }
        .sheet(isPresented: $showNewPlaylistSheet) {
            Text("New Playlist") // placeholder; wire to actual create-playlist flow
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSignIn) {
            YTMusicLoginView()
                .environmentObject(appVM)
        }
    }
}

// MARK: - LibraryLinkList (matches LibraryLinkList.kt)
struct LibraryLinkListView: View {
    let links: [LibraryLink]
    let onTap: (ShelfItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(links.enumerated()), id: \.offset) { i, link in
                HStack(spacing: 16) {
                    // Icon (or logo)
                    Image(systemName: link.icon)
                        .font(.system(size: 22))
                        .foregroundColor(.bcPrimary)
                        .frame(width: 24)

                    Text(link.title)
                        .font(.bcBodyLarge)
                        .foregroundColor(.bcOnBackground)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color.bcOnSurfaceVar.opacity(0.6))
                }
                .frame(minHeight: 54)
                .padding(.horizontal, BCLayout.pageGutter)
                .contentShape(Rectangle())
                .onTapGesture {
                    // onTap(ShelfItem for link)
                }

                if i < links.count - 1 {
                    Divider()
                        .background(Color.bcOutline)
                        .padding(.leading, BCLayout.pageGutter + 24 + 16) // indent past icon
                }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 22)
    }
}

// MARK: - LibraryGridShelf (matches LibraryGridShelf.kt — 5-card row + Show all)
struct LibraryGridShelfView: View {
    let title: String
    let items: [ShelfItem]
    var isPlaylistShelf: Bool = false
    var onNewPlaylist: (() -> Void)? = nil
    let onItemTap: (ShelfItem) -> Void
    let onShowAll: (() -> Void)?

    // Max 5 cards, same as Android LIBRARY_ROW_MAX_ITEMS
    private var visibleItems: [ShelfItem] {
        let leadingCount = onNewPlaylist != nil ? 1 : 0
        return Array(items.prefix(max(0, 5 - leadingCount)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: title, subtitle: "", onShowAll: onShowAll)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BCLayout.shelfCardWidth == 160 ? 14 : 14) {
                    // Leading "New playlist" card
                    if let newPlaylist = onNewPlaylist {
                        NewShelfCardView(
                            icon: "plus",
                            label: "New playlist",
                            subtitle: "Saved to YouTube Music",
                            action: newPlaylist
                        )
                    }

                    ForEach(visibleItems) { item in
                        ShelfCardView(
                            item: item,
                            isCurrent: false,
                            isPlaying: false,
                            onTap: { onItemTap(item) }
                        )
                    }
                }
                .padding(.horizontal, BCLayout.pageGutter)
            }
        }
        .padding(.bottom, 26)
    }
}

// MARK: - NewShelfCard (the "New playlist" / "Import Spotify" leading card)
struct NewShelfCardView: View {
    let icon: String
    let label: String
    let subtitle: String
    let action: () -> Void
    var logoAsset: String? = nil

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    Color.bcSurfaceVar
                        .frame(width: BCLayout.shelfCardWidth, height: BCLayout.shelfCardWidth)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.bcOnSurfaceVar)
                }

                Text(label)
                    .font(.bcTitleSmall)
                    .foregroundColor(.bcOnBackground)
                    .lineLimit(2)
                    .frame(width: BCLayout.shelfCardWidth, alignment: .leading)

                Text(subtitle)
                    .font(.bcBodySmall)
                    .foregroundColor(.bcOnSurfaceVar)
                    .lineLimit(1)
                    .frame(width: BCLayout.shelfCardWidth, alignment: .leading)
            }
        }
        .frame(width: BCLayout.shelfCardWidth)
    }
}

// MARK: - EmptyPlaylistsShelf (shown for signed-out or zero playlists accounts)
private struct EmptyPlaylistsShelfView: View {
    let onNewPlaylist: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: "Playlists", subtitle: "")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    NewShelfCardView(
                        icon: "plus",
                        label: "New playlist",
                        subtitle: "Saved to YouTube Music",
                        action: onNewPlaylist
                    )
                }
                .padding(.horizontal, BCLayout.pageGutter)
            }
        }
        .padding(.bottom, 26)
    }
}

// MARK: - Library skeleton
struct LibrarySkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonView().frame(width: 120, height: 16).padding(.horizontal, BCLayout.pageGutter)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(0..<5, id: \.self) { _ in
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
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppViewModel())
        .environmentObject(PlayerViewModel())
        .preferredColorScheme(.dark)
}

