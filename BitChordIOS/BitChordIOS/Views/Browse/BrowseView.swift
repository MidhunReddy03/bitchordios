// BrowseView.swift
// BitChordIOS
// Android ref: sharedUi/.../ui/screens/ (Album/Artist/Playlist detail pages)

import SwiftUI

// MARK: - Browse Destination
enum BrowseDestination: Hashable {
    case album(id: String, title: String, thumbnail: String?)
    case artist(id: String, name: String, thumbnail: String?)
    case playlist(id: String, title: String, thumbnail: String?)
}

// MARK: - BrowseView (master router)
struct BrowseView: View {
    let destination: BrowseDestination
    @EnvironmentObject private var playerVM: PlayerViewModel

    var body: some View {
        switch destination {
        case .album(let id, let title, let thumb):
            AlbumDetailView(id: id, title: title, thumbnailUrl: thumb)
        case .artist(let id, let name, let thumb):
            ArtistDetailView(id: id, name: name, thumbnailUrl: thumb)
        case .playlist(let id, let title, let thumb):
            PlaylistDetailView(id: id, title: title, thumbnailUrl: thumb)
        }
    }
}

// MARK: - AlbumDetailView
/// Mirrors Android AlbumBrowse screen: header + track list.
struct AlbumDetailView: View {
    let id: String
    let title: String
    let thumbnailUrl: String?

    @StateObject private var vm = BrowseViewModel()
    @EnvironmentObject private var playerVM: PlayerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrowseHeaderView(
                    title: title,
                    subtitle: vm.subtitle,
                    thumbnailUrl: thumbnailUrl,
                    type: "Album"
                )
                // Track list
                if vm.isLoading {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonView()
                            .frame(height: 56)
                            .padding(.horizontal, BCLayout.pageGutter)
                    }
                } else {
                    ForEach(Array(vm.songs.enumerated()), id: \.element.id) { idx, song in
                        SwipeToQueueBox(song: song) {
                            SongRowView(
                                song: song,
                                isPlaying: playerVM.currentSong?.id == song.id,
                                showIndex: idx + 1,
                                onTap: { playerVM.playSong(song, queue: vm.songs) },
                                onMore: {}
                            )
                        }
                        .environmentObject(playerVM)
                        Divider().padding(.leading, BCLayout.pageGutter + 52)
                    }
                }
            }
        }
        .background(Color.bcBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(id: id, type: .album) }
    }
}

// MARK: - ArtistDetailView
/// Mirrors Android ArtistBrowse: header + shelves (songs, albums, singles, videos).
struct ArtistDetailView: View {
    let id: String
    let name: String
    let thumbnailUrl: String?

    @StateObject private var vm = BrowseViewModel()
    @EnvironmentObject private var playerVM: PlayerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrowseHeaderView(
                    title: name,
                    subtitle: vm.subtitle,
                    thumbnailUrl: thumbnailUrl,
                    type: "Artist"
                )
                if vm.isLoading {
                    SkeletonView().frame(height: 200).padding(BCLayout.pageGutter)
                } else {
                    ForEach(vm.shelves) { shelf in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(shelf.title)
                                .font(BCFont.titleMedium)
                                .foregroundColor(.bcOnSurface)
                                .padding(.horizontal, BCLayout.pageGutter)
                                .padding(.top, 20)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(shelf.items) { item in
                                        ShelfCardView(item: item, onTap: {})
                                    }
                                }
                                .padding(.horizontal, BCLayout.pageGutter)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.bcBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(id: id, type: .artist) }
    }
}

// MARK: - PlaylistDetailView
/// Mirrors Android PlaylistBrowse: header + draggable track list.
struct PlaylistDetailView: View {
    let id: String
    let title: String
    let thumbnailUrl: String?

    @StateObject private var vm = BrowseViewModel()
    @EnvironmentObject private var playerVM: PlayerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrowseHeaderView(
                    title: title,
                    subtitle: vm.subtitle,
                    thumbnailUrl: thumbnailUrl,
                    type: "Playlist"
                )
                // Play / Shuffle row
                HStack(spacing: 12) {
                    Button {
                        if let first = vm.songs.first {
                            playerVM.playSong(first, queue: vm.songs)
                        }
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .font(BCFont.bodyLarge)
                            .foregroundColor(.bcOnSurface)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.bcSurfaceVariant)
                            .cornerRadius(22)
                    }
                    Button {
                        playerVM.shuffleAndPlay(vm.songs)
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                            .font(BCFont.bodyLarge)
                            .foregroundColor(.bcOnSurface)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.bcSurfaceVariant)
                            .cornerRadius(22)
                    }
                }
                .padding(.horizontal, BCLayout.pageGutter)
                .padding(.vertical, 12)

                if vm.isLoading {
                    ForEach(0..<12, id: \.self) { _ in
                        SkeletonView().frame(height: 56).padding(.horizontal, BCLayout.pageGutter)
                    }
                } else {
                    ForEach(vm.songs) { song in
                        SwipeToQueueBox(song: song) {
                            SongRowView(
                                song: song,
                                isPlaying: playerVM.currentSong?.id == song.id,
                                onTap: { playerVM.playSong(song, queue: vm.songs) },
                                onMore: {}
                            )
                        }
                        .environmentObject(playerVM)
                        Divider().padding(.leading, BCLayout.pageGutter + 52)
                    }
                }
            }
        }
        .background(Color.bcBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(id: id, type: .playlist) }
    }
}

// MARK: - BrowseHeaderView
private struct BrowseHeaderView: View {
    let title: String
    let subtitle: String?
    let thumbnailUrl: String?
    let type: String

    var body: some View {
        VStack(spacing: 12) {
            ArtworkImage(url: thumbnailUrl, size: 200)
                .cornerRadius(type == "Artist" ? 100 : 12)
                .shadow(radius: 20)
                .padding(.top, 24)

            Text(title)
                .font(BCFont.titleLarge)
                .foregroundColor(.bcOnSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BCLayout.pageGutter)

            if let sub = subtitle {
                Text(sub)
                    .font(BCFont.bodyMedium)
                    .foregroundColor(.bcOnSurfaceVariant)
            }

            Text(type.uppercased())
                .font(BCFont.caption2)
                .foregroundColor(.bcOnSurfaceVariant)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - BrowseViewModel
@MainActor
class BrowseViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var shelves: [HomeShelf] = []
    @Published var subtitle: String? = nil
    @Published var isLoading = true

    func load(id: String, type: BrowseType) async {
        isLoading = true
        // TODO: Call YTMusicService to fetch browse page
        // Android ref:
        //   album   → InnerTube browseId "MPREb_" endpoint
        //   artist  → InnerTube browseId "UCxxxxxxx" endpoint
        //   playlist→ InnerTube browseId "VLPLxxxxxxx" endpoint
        // See YTMusicService.swift → fetchBrowse(id:)
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
    }
}

