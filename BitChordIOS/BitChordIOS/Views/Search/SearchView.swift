import SwiftUI

// MARK: - SearchView
/// Mirrors BitChord's SearchScreen.kt exactly:
/// - Fixed search field + filter tabs at top (always visible)
/// - Suggestions dropdown while typing
/// - Live typeahead results below suggestions
/// - Recent searches when field is empty
/// - Filter pill control once results are present
/// - Top result card promoted above all results
/// - Song rows + browse rows (albums/artists/playlists)
/// - Infinite scroll pagination
struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @EnvironmentObject var playerVM: PlayerViewModel
    @FocusState private var fieldFocused: Bool
    @State private var filterIndex: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // — Fixed top area: search field + filter pills —
                // Matches the top padding = topPadding (status bar + frosted bar clearance)
                VStack(spacing: 4) {
                    SearchFieldView(
                        query: $vm.query,
                        placeholder: "Search YouTube Music",
                        onSubmit: { vm.submit() },
                        onQueryChange: { vm.onQueryChange($0) }
                    )
                    .padding(.horizontal, BCLayout.pageGutter)
                    .padding(.top, 8)

                    // Filter pills — only when results are present (not suggesting)
                    if vm.results != nil && vm.suggestions.isEmpty {
                        PillSegmentedControl(
                            options: SearchFilter.allCases.map(\.label),
                            selectedIndex: Binding(
                                get: { SearchFilter.allCases.firstIndex(of: vm.filter) ?? 0 },
                                set: { vm.onFilterChange(SearchFilter.allCases[$0]) }
                            )
                        )
                        .padding(.horizontal, BCLayout.pageGutter)
                        .padding(.bottom, 6)
                    }
                }
                .background(.ultraThinMaterial)

                // — Scrollable body —
                ScrollViewReader { proxy in
                    List {
                        Group {
                            if !vm.suggestions.isEmpty {
                                // Suggestions while typing
                                suggestionRows
                                if !vm.typeaheadResults.isEmpty {
                                    typeaheadRows
                                }
                            } else if let results = vm.results {
                                resultRows(results)
                            } else {
                                // History / empty state
                                historyRows
                            }
                        }
                        // Load-more trigger at list bottom
                        if case .success = vm.results {
                            Color.clear.frame(height: 1)
                                .onAppear { vm.loadMore() }
                        }
                        // Bottom padding clears mini-player + tab bar
                        Color.clear.frame(height: BCLayout.miniPlayerHeight + BCLayout.tabBarHeight)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .background(Color.bcBackground)
                    .onChange(of: vm.scrollResetTrigger) { _ in
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
            .background(Color.bcBackground)
            .navigationBarHidden(true)
        }
    }

    // MARK: - Suggestion rows (matches searchSuggestions in SearchScreen.kt)
    @ViewBuilder private var suggestionRows: some View {
        ForEach(Array(vm.suggestions.dropFirst().prefix(3).enumerated()), id: \.offset) { _, term in
            SuggestionRowView(
                term: term,
                onFill: { vm.onQueryChange(term) },
                onSelect: { vm.onQueryChange(term); vm.submit() }
            )
            .listRowBackground(Color.bcBackground)
            .listRowSeparatorTint(Color.bcOutline)
        }
    }

    // MARK: - Typeahead rows (live media while typing)
    @ViewBuilder private var typeaheadRows: some View {
        Divider().background(Color.bcOutline).listRowBackground(Color.bcBackground)
        ForEach(vm.typeaheadResults) { result in
            if let song = result.song {
                TypeaheadSongRowView(song: song, isCurrent: false, isPlaying: false)
                    .listRowBackground(Color.bcBackground)
            }
        }
    }

    // MARK: - History (matches recentSearches in SearchScreen.kt)
    @ViewBuilder private var historyRows: some View {
        if vm.history.isEmpty {
            MessageStateView("Search for songs, albums, artists and playlists")
                .listRowBackground(Color.bcBackground)
        } else {
            ForEach(vm.history) { entity in
                SearchHistoryRowView(
                    entity: entity,
                    onSelect: { vm.onQueryChange(entity.query); vm.submit() },
                    onRemove: { vm.removeHistory(entity.query) }
                )
                .listRowBackground(Color.bcBackground)
            }
            Button("Clear history") { vm.clearHistory() }
                .font(.bcLabelMedium)
                .foregroundColor(.bcOnSurfaceVar)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.bcBackground)
        }
    }

    // MARK: - Results (matches searchSections in SearchScreen.kt)
    @ViewBuilder private func resultRows(_ results: UiState<[SearchResult]>) -> some View {
        switch results {
        case .loading:
            ForEach(0..<8, id: \.self) { _ in
                SongRowSkeletonView().listRowBackground(Color.bcBackground)
            }

        case .error(let msg):
            MessageStateView(msg, actionLabel: "Retry") { vm.submit() }
                .listRowBackground(Color.bcBackground)

        case .success(let rows):
            if rows.isEmpty {
                MessageStateView("No results for \"\(vm.query)\"")
                    .listRowBackground(Color.bcBackground)
            } else {
                // Top result card (promoted)
                if vm.filter == .all,
                   let topResult = rows.first(where: { $0.type == .topTrack }),
                   let song = topResult.song {
                    TopResultCardView(
                        song: song,
                        onPlay: { playerVM.playSong(song) },
                        onPlaylist: { },
                        onLongPress: { }
                    )
                    .listRowBackground(Color.bcBackground)
                    .listRowSeparator(.hidden)
                }

                // All result rows
                ForEach(rows) { result in
                    Group {
                        if let song = result.song {
                            SongRowView(
                                song: song,
                                isCurrent: playerVM.currentSong?.videoId == song.videoId,
                                isPlaying: playerVM.isPlaying && playerVM.currentSong?.videoId == song.videoId,
                                onTap: { playerVM.playSong(song) },
                                onLongPress: { }
                            )
                        } else if let browse = result.browseItem {
                            BrowseRowView(item: browse, onTap: { })
                        }
                    }
                    .listRowBackground(Color.bcBackground)
                    .listRowSeparatorTint(Color.bcOutline)
                }

                if vm.loadingMore {
                    ProgressView().frame(maxWidth: .infinity).listRowBackground(Color.bcBackground)
                }
            }
        }
    }
}

// MARK: - SearchField (matches SearchField.kt)
struct SearchFieldView: View {
    @Binding var query: String
    let placeholder: String
    let onSubmit: () -> Void
    let onQueryChange: (String) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.bcOnSurfaceVar)
                .font(.system(size: 17))

            TextField(placeholder, text: $query)
                .font(.bcBodyLarge)
                .foregroundColor(.bcOnBackground)
                .tint(.bcPrimary)
                .focused($focused)
                .submitLabel(.search)
                .onSubmit(onSubmit)
                .onChange(of: query, perform: onQueryChange)

            if !query.isEmpty {
                Button(action: { query = ""; onQueryChange("") }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.bcOnSurfaceVar)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.bcSurfaceVar)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - SuggestionRow (matches SuggestionRow.kt)
struct SuggestionRowView: View {
    let term: String
    let onFill: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.bcOnSurfaceVar)
                .frame(width: 22)

            Button(action: onSelect) {
                Text(term)
                    .font(.bcTitleMedium)
                    .foregroundColor(.bcOnBackground)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onFill) {
                Image(systemName: "arrow.up.left")
                    .foregroundColor(.bcOnSurfaceVar)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, BCLayout.pageGutter)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - TypeaheadSongRow (matches TypeaheadSongRow.kt)
struct TypeaheadSongRowView: View {
    let song: Song
    let isCurrent: Bool
    let isPlaying: Bool
    var onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                ArtworkImage(
                    url: song.artworkAt(ArtworkSize.rowArt),
                    cornerRadius: 8
                )
                .frame(width: BCLayout.searchArtSize, height: BCLayout.searchArtSize)

                if isCurrent && isPlaying {
                    PlayingBarsView().frame(width: 20, height: 16)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.bcTitleMedium)
                    .foregroundColor(.bcOnBackground)
                    .lineLimit(1)
                Text(song.artist)
                    .font(.bcBodyMedium)
                    .foregroundColor(.bcOnSurfaceVar)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, BCLayout.pageGutter)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

// MARK: - TopResultCard (matches TopResultCard.kt)
struct TopResultCardView: View {
    let song: Song
    let onPlay: () -> Void
    let onPlaylist: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top result")
                .font(.bcLabelLarge)
                .foregroundColor(.bcOnSurface)

            HStack(spacing: 14) {
                ArtworkImage(url: song.artworkAt(ArtworkSize.rowArt), cornerRadius: 10)
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.bcTitleLarge)
                        .foregroundColor(.bcOnSurface)
                        .lineLimit(2)
                    Text(song.artist)
                        .font(.bcBodyMedium)
                        .foregroundColor(.bcOnSurfaceVar)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onLongPress) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.bcOnSurface)
                        .frame(width: 44, height: 44)
                }
            }

            HStack(spacing: 10) {
                OutlineButton(label: "Play", icon: "play.fill", action: onPlay)
                OutlineButton(label: "Add to playlist", icon: "text.badge.plus", action: onPlaylist)
            }
        }
        .padding(.horizontal, BCLayout.pageGutter)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }
}

private struct OutlineButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 14))
                Text(label).font(.bcLabelMedium)
            }
            .foregroundColor(.bcOnSurface)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .overlay(Capsule().stroke(Color.bcOutline, lineWidth: 1))
        }
    }
}

// MARK: - BrowseRow (albums / artists / playlists)
struct BrowseRowView: View {
    let item: BrowseItem
    let onTap: () -> Void
    var onLongPress: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            ArtworkImage(
                url: URL(string: item.thumbnailUrl ?? ""),
                cornerRadius: item.type == .artist ? 32 : 8
            )
            .frame(width: 52, height: 52)
            .clipShape(item.type == .artist ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 8)))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.bcTitleMedium)
                    .foregroundColor(.bcOnBackground)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.bcBodyMedium)
                    .foregroundColor(.bcOnSurfaceVar)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .foregroundColor(.bcOnSurfaceVar)
                .font(.system(size: 14))
        }
        .padding(.horizontal, BCLayout.pageGutter)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onLongPressGesture { onLongPress?() }
    }
}


struct SongRowSkeletonView: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonView().frame(width: BCLayout.rowArtSize, height: BCLayout.rowArtSize).cornerRadius(7)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView().frame(width: 160, height: 14).cornerRadius(4)
                SkeletonView().frame(width: 100, height: 12).cornerRadius(4)
            }
        }
        .padding(.horizontal, BCLayout.pageGutter)
        .padding(.vertical, 4)
    }
}

// MARK: - SearchHistoryRow
struct SearchHistoryRowView: View {
    let entity: SearchHistoryEntity
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: entity.type == .song ? "music.note" : "clock")
                .foregroundColor(.bcOnSurfaceVar)
                .frame(width: 22)

            Button(action: onSelect) {
                Text(entity.query)
                    .font(.bcTitleMedium)
                    .foregroundColor(.bcOnBackground)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .foregroundColor(.bcOnSurfaceVar)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, BCLayout.pageGutter)
        .padding(.vertical, 6)
    }
}

// AnyShape wrapper (iOS 16+ has it natively, this covers iOS 15)
struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path
    init<S: Shape>(_ shape: S) { pathBuilder = shape.path(in:) }
    func path(in rect: CGRect) -> Path { pathBuilder(rect) }
}

#Preview {
    SearchView()
        .environmentObject(AppViewModel())
        .environmentObject(PlayerViewModel())
        .preferredColorScheme(.dark)
}

