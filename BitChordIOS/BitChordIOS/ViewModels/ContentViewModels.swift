import Foundation
import Combine

// MARK: - HomeViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var state: UiState<[HomeShelf]> = .loading
    @Published var refreshing: Bool = false
    @Published var loadingMore: Bool = false
    @Published var topPicks: [TopPick]? = nil
    @Published var topPicksLoading: Bool = false
    @Published var recentlyPlayedLoading: Bool = false
    @Published var listenerName: String? = nil

    func load() {
        state = .loading
        YTMusicService.shared.fetchHome { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let shelves): self?.state = .success(shelves)
                case .failure(let err): self?.state = .error(err.localizedDescription)
                }
            }
        }
    }

    func refresh() {
        refreshing = true
        YTMusicService.shared.fetchHome { [weak self] result in
            Task { @MainActor in
                self?.refreshing = false
                switch result {
                case .success(let shelves): self?.state = .success(shelves)
                case .failure(let err): self?.state = .error(err.localizedDescription)
                }
            }
        }
    }

    func loadMore() {
        guard !loadingMore else { return }
        loadingMore = true
        // continuation fetch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.loadingMore = false
        }
    }
}

// MARK: - SearchViewModel
@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var filter: SearchFilter = .all
    @Published var results: UiState<[SearchResult]>? = nil
    @Published var loadingMore: Bool = false
    @Published var history: [SearchHistoryEntity] = []
    @Published var suggestions: [String] = []
    @Published var typeaheadResults: [SearchResult] = []
    @Published var focusRequested: Bool = false
    @Published var scrollResetTrigger: Int = 0

    private var searchTask: Task<Void, Never>?
    private var suggestionTask: Task<Void, Never>?

    func onQueryChange(_ newQuery: String) {
        query = newQuery
        if newQuery.isEmpty {
            suggestions = []
            typeaheadResults = []
            results = nil
        } else {
            fetchSuggestions(for: newQuery)
        }
    }

    func submit() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        suggestions = []
        typeaheadResults = []
        results = .loading
        scrollResetTrigger += 1
        searchTask?.cancel()
        searchTask = Task {
            await search(query: query, filter: filter)
        }
    }

    func onFilterChange(_ newFilter: SearchFilter) {
        filter = newFilter
        if results != nil { submit() }
    }

    func loadMore() {
        guard !loadingMore else { return }
        loadingMore = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.loadingMore = false
        }
    }

    func removeHistory(_ query: String) {
        history.removeAll { $0.query == query }
    }

    func clearHistory() { history.removeAll() }

    private func fetchSuggestions(for query: String) {
        suggestionTask?.cancel()
        suggestionTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            // In production: call YTMusicService.fetchSuggestions
            await MainActor.run { self.suggestions = [query, "\(query) lyrics", "\(query) live"] }
        }
    }

    private func search(query: String, filter: SearchFilter) async {
        // In production: call YTMusicService.search
        try? await Task.sleep(nanoseconds: 800_000_000)
        guard !Task.isCancelled else { return }
        await MainActor.run { self.results = .success([]) }
    }
}

// MARK: - LibraryViewModel
@MainActor
class LibraryViewModel: ObservableObject {
    @Published var state: UiState<LibraryPage> = .loading
    @Published var refreshing: Bool = false
    @Published var links: [LibraryLink] = [
        LibraryLink(id: "downloads", title: "Downloads", icon: "arrow.down.circle.fill", logoAsset: nil),
        LibraryLink(id: "local", title: "Local Music", icon: "folder.fill", logoAsset: nil),
    ]
    @Published var deviceItems: [ShelfItem] = []

    func load() {
        state = .loading
        YTMusicService.shared.fetchLibrary { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let page): self?.state = .success(page)
                case .failure(let err): self?.state = .error(err.localizedDescription)
                }
            }
        }
    }

    func refresh() {
        refreshing = true
        load()
    }
}

