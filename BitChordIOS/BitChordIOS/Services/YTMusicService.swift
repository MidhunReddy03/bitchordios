import Foundation
import AVFoundation

// MARK: - YTMusicService
/// Network layer: YouTube Music API calls, stream resolution, lyrics.
/// Replace stub implementations with real InnerTube / module-source calls.
class YTMusicService {
    static let shared = YTMusicService()
    private init() {}

    // MARK: - Stream Resolution
    /// Resolve the best available stream URL for a song (YouTube → module fallback)
    func streamURL(for song: Song, completion: @escaping (URL?) -> Void) {
        // TODO: Implement InnerTube player endpoint (same as Android's
        // SourceResolver.resolveForNow). For now returns nil (stub).
        // Real implementation:
        // 1. POST to https://music.youtube.com/youtubei/v1/player with videoId
        // 2. Parse adaptiveFormats for audio/webm or audio/mp4
        // 3. If lossless quality requested, try module source first
        completion(nil)
    }

    // MARK: - Home Feed
    func fetchHome(completion: @escaping (Result<[HomeShelf], Error>) -> Void) {
        // TODO: POST https://music.youtube.com/youtubei/v1/browse
        //       with browseId = "FEmusic_home"
        //       Parse shelves into [HomeShelf]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            completion(.success([]))
        }
    }

    // MARK: - Library
    func fetchLibrary(completion: @escaping (Result<LibraryPage, Error>) -> Void) {
        // TODO: POST browse with browseId = "FEmusic_liked_playlists"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            completion(.success(LibraryPage(shelves: [])))
        }
    }

    // MARK: - Search
    func search(query: String, filter: SearchFilter, continuation: String? = nil,
                completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        // TODO: POST https://music.youtube.com/youtubei/v1/search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            completion(.success([]))
        }
    }

    func fetchSuggestions(query: String, completion: @escaping ([String]) -> Void) {
        // TODO: POST https://music.youtube.com/youtubei/v1/music/get_search_suggestions
        completion([query])
    }

    // MARK: - Browse
    func fetchBrowse(id: String, completion: @escaping (Result<(songs: [Song], shelves: [HomeShelf]), Error>) -> Void) {
        // TODO: POST https://music.youtube.com/youtubei/v1/browse with browseId
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            completion(.success((songs: [], shelves: [])))
        }
    }

    // MARK: - Lyrics
    func fetchLyrics(videoId: String, title: String, artist: String,
                     completion: @escaping ([LyricLine]?) -> Void) {
        // TODO: Try multiple providers in order:
        // lrclib → BetterLyrics → PaxSenix → Genius → KuGou → LyricsPlus
        // Same priority order as BitChord Android.
        completion(nil)
    }

    // MARK: - Canvas / Animated Artwork
    func fetchCanvas(videoId: String, completion: @escaping (URL?) -> Void) {
        // TODO: Spotify Canvas endpoint, then Apple Artist animation
        completion(nil)
    }

    // MARK: - Scrobbling (Last.fm / ListenBrainz hooks)
    func scrobble(song: Song, timestamp: Date) {
        // TODO: POST to Last.fm track.scrobble and ListenBrainz /1/submit-listens
    }

    func nowPlaying(song: Song) {
        // TODO: POST now-playing to Last.fm / ListenBrainz
    }
}

// MARK: - AVPlayerService helpers
extension AVPlayer {
    var isActuallyPlaying: Bool {
        return rate != 0 && error == nil && status == .readyToPlay
    }
}

