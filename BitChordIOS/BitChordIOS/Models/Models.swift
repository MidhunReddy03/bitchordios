import Foundation

// MARK: - Song
/// Mirrors com.music.bitchord.data.model.Song exactly
struct Song: Identifiable, Hashable, Codable {
    let id: String          // videoId
    let title: String
    let artist: String
    let albumName: String?
    let thumbnailUrl: String?
    let durationMs: Int64
    let isVideo: Bool
    let isExplicit: Bool
    var likeStatus: LikeStatus = .neutral
    let playbackSource: String?
    let radioName: String?
    let browseId: String?   // for album/artist navigation
    var sourceQuality: String? = nil
    var sourceHiRes: Bool = false

    var videoId: String { id }

    // Artwork at a given pixel size (mirrors artworkAt() in Kotlin)
    func artworkAt(_ px: Int) -> URL? {
        guard var urlStr = thumbnailUrl else { return nil }
        // YouTube thumbnail resize: replace =w… suffix
        if urlStr.contains("=w") {
            urlStr = urlStr.replacingOccurrences(
                of: #"=w\d+"#,
                with: "=w\(px)",
                options: .regularExpression
            )
        } else if urlStr.contains("?") {
            urlStr += "&w=\(px)"
        } else {
            urlStr += "?w=\(px)"
        }
        return URL(string: urlStr)
    }
}

enum LikeStatus: String, Codable {
    case liked = "LIKE"
    case disliked = "DISLIKE"
    case neutral = "INDIFFERENT"
}

// MARK: - ShelfItem
/// Mirrors com.music.bitchord.data.model.ShelfItem
struct ShelfItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let thumbnailUrl: String?
    let videoId: String?
    let browseId: String?
    let isVideo: Bool
    let isExplicit: Bool

    func artworkAt(_ px: Int) -> URL? {
        guard let urlStr = thumbnailUrl else { return nil }
        return URL(string: urlStr)
    }
}

// MARK: - HomeShelf
/// Mirrors com.music.bitchord.data.model.HomeShelf
struct HomeShelf: Identifiable, Codable {
    var id: String { title + subtitle }
    let title: String
    let subtitle: String
    let items: [ShelfItem]
    let layout: ShelfLayout
}

enum ShelfLayout: String, Codable {
    case card = "CARD"
    case list = "LIST"
    case video = "VIDEO"
    case grid = "GRID"
}

// MARK: - UiState
enum UiState<T> {
    case loading
    case success(T)
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var data: T? {
        if case .success(let data) = self { return data }
        return nil
    }
}

// MARK: - Library
struct LibraryPage: Codable {
    let shelves: [HomeShelf]
}

struct LibraryLink: Identifiable {
    let id: String
    let title: String
    let icon: String       // SF Symbol name
    let logoAsset: String? // asset catalogue name for service logos
}

// MARK: - Search
struct SearchResult: Identifiable {
    let id: String
    let type: SearchResultType
    let song: Song?
    let browseItem: BrowseItem?
}

enum SearchResultType {
    case track, topTrack, browse
}

struct BrowseItem: Identifiable, Hashable, Codable {
    let browseId: String
    var id: String { browseId }
    let title: String
    let subtitle: String
    let thumbnailUrl: String?
    let type: BrowseType
}

enum BrowseType: String, Codable {
    case artist = "ARTIST"
    case album = "ALBUM"
    case playlist = "PLAYLIST"
    case other = "OTHER"
}

enum SearchFilter: String, CaseIterable {
    case all = "All"
    case songs = "Songs"
    case videos = "Videos"
    case albums = "Albums"
    case artists = "Artists"
    case playlists = "Playlists"

    var label: String { rawValue }
}

struct SearchHistoryEntity: Identifiable, Codable {
    let id: String
    let query: String
    let type: EntityType
    let thumbnailUrl: String?
    let subtitle: String?
}

enum EntityType: String, Codable {
    case song, album, artist, playlist, query
}

// MARK: - Player / Playback
struct NerdStats {
    let codec: String?
    let bitDepth: Int?
    let sampleRate: Int?
    let bitrate: Int?

    func describe() -> String? {
        var parts: [String] = []
        if let codec = codec { parts.append(codec) }
        if let bd = bitDepth { parts.append("\(bd)-bit") }
        if let sr = sampleRate { parts.append("\(sr / 1000)kHz") }
        if let br = bitrate { parts.append("\(br)kbps") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

// MARK: - Top Picks
struct TopPick: Identifiable {
    let id: String
    let title: String
    let artist: String
    let thumbnailUrl: String?
    let mood: TopPickMood?
}

enum TopPickMood: String {
    case chill, focus, workout, party, sleep
}

// MARK: - PlaybackSource
enum PlaybackSourceType: String, Codable {
    case youtube, module, local
}

// MARK: - Artwork pixels (matches Android PLAYER_ART_PX / CARD_ART_PX)
enum ArtworkSize {
    static let playerArt = 1080
    static let cardArt   = 400
    static let rowArt    = 150
}

