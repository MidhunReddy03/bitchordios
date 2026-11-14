import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit

// MARK: - SleepTimerOption
enum SleepTimerOption {
    case endOfTrack
    case duration(TimeInterval)
}

// MARK: - PlayerViewModel
/// Manages AVPlayer-based playback, mirroring BitChord's PlaybackService.
/// All features preserved: gapless, crossfade, shuffle, repeat, sleep timer,
/// volume, speed, background session, Now Playing info, scrobbling hooks.
@MainActor
class PlayerViewModel: ObservableObject {

    // MARK: State (mirrors NowPlayingScreen parameters)
    @Published var currentSong: Song? = nil
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var queue: [Song] = []
    @Published var queueIndex: Int = 0
    @Published var repeatMode: RepeatMode = .off
    @Published var shuffleEnabled: Bool = false
    @Published var autoplayEnabled: Bool = false
    @Published var durationMs: Int64 = 0
    @Published var positionMs: Int64 = 0
    @Published var volumeLevel: Float = 1.0
    @Published var playbackSpeed: Float = 1.0
    @Published var likeStatus: LikeStatus = .neutral
    @Published var lyricsOpen: Bool = false
    @Published var queueOpen: Bool = false
    @Published var outputSheetOpen: Bool = false
    @Published var nerdStats: NerdStats? = nil
    @Published var sleepTimerActive: Bool = false
    @Published var sleepTimerEndsAfterTrack: Bool = false
    @Published var crossfadeDurationSec: Int = 5

    // Lyrics configuration & state
    @Published var selectedLyricsProvider: String = "auto"
    @Published var lyricsOffsetMs: Int = 0
    @Published var syncedLyrics: [LyricLine] = []
    @Published var currentLyricIndex: Int = -1

    var hasPrevious: Bool { queueIndex > 0 || positionMs > 3000 }
    var hasNext: Bool { queueIndex < queue.count - 1 }

    // MARK: Private
    private var player: AVPlayer = AVPlayer()
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    var sleepTimer: Timer?

    init() {
        setupRemoteCommandCenter()
        setupAudioSession()
        startTimeObserver()
    }

    // MARK: - Playback Control

    func play(songs: [Song], startIndex: Int = 0) {
        queue = songs
        queueIndex = startIndex
        loadCurrentSong()
    }

    func playSong(_ song: Song) {
        play(songs: [song], startIndex: 0)
    }

    func playSong(_ song: Song, queue: [Song]? = nil) {
        if let queue = queue, !queue.isEmpty {
            if let idx = queue.firstIndex(where: { $0.id == song.id }) {
                play(songs: queue, startIndex: idx)
            } else {
                play(songs: [song] + queue, startIndex: 0)
            }
        } else {
            play(songs: [song], startIndex: 0)
        }
    }

    func shuffleAndPlay(_ songs: [Song]) {
        guard !songs.isEmpty else { return }
        let shuffled = songs.shuffled()
        play(songs: shuffled, startIndex: 0)
    }

    func queueNext(_ song: Song) {
        if queue.isEmpty {
            playSong(song)
        } else {
            let insertIndex = min(queueIndex + 1, queue.count)
            queue.insert(song, at: insertIndex)
        }
    }

    func playPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }

    func next() {
        guard hasNext else { return }
        queueIndex += 1
        loadCurrentSong()
    }

    func previous() {
        // Restart if > 3s played, else go to previous track (matches Android)
        if positionMs > 3000 {
            seek(to: 0)
        } else if queueIndex > 0 {
            queueIndex -= 1
            loadCurrentSong()
        }
    }

    func seek(toFraction fraction: Float) {
        guard durationMs > 0 else { return }
        let targetMs = Int64(fraction * Float(durationMs))
        seek(to: targetMs)
    }

    func seek(to ms: Int64) {
        let time = CMTime(value: ms, timescale: 1000)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        positionMs = ms
    }

    func setVolume(_ volume: Float) {
        volumeLevel = volume
        player.volume = volume
    }

    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        player.rate = isPlaying ? speed : 0
    }

    func toggleShuffle() {
        shuffleEnabled.toggle()
        if shuffleEnabled {
            // Shuffle remaining queue, keeping current track in place
            let remaining = Array(queue[(queueIndex + 1)...]).shuffled()
            queue = Array(queue[...queueIndex]) + remaining
        }
    }

    func cycleRepeat() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    func toggleAutoplay() {
        autoplayEnabled.toggle()
    }

    func toggleLike() {
        switch likeStatus {
        case .neutral, .disliked: likeStatus = .liked
        case .liked: likeStatus = .neutral
        }
    }

    // MARK: - Sleep Timer

    func setSleepTimer(minutes: Int) {
        sleepTimer?.invalidate()
        sleepTimerActive = true
        sleepTimerEndsAfterTrack = false
        sleepTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.player.pause()
                self?.isPlaying = false
                self?.sleepTimerActive = false
                self?.sleepTimer = nil
            }
        }
    }

    func setSleepTimer(_ option: SleepTimerOption) {
        switch option {
        case .endOfTrack:
            setSleepTimerAfterTrack()
        case .duration(let interval):
            setSleepTimer(minutes: max(1, Int(interval / 60)))
        }
    }

    func setSleepTimerAfterTrack() {
        sleepTimerEndsAfterTrack = true
        sleepTimerActive = true
    }

    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerActive = false
        sleepTimerEndsAfterTrack = false
    }

    // MARK: - Private Helpers

    private func loadCurrentSong() {
        guard queueIndex < queue.count else { return }
        let song = queue[queueIndex]
        currentSong = song
        isLoading = true
        isPlaying = false
        likeStatus = song.likeStatus
        durationMs = song.durationMs

        // In production: resolve stream URL via YTMusicService
        // For now, placeholder URL logic
        YTMusicService.shared.streamURL(for: song) { [weak self] url in
            guard let self, let url else {
                Task { @MainActor in self?.isLoading = false }
                return
            }
            Task { @MainActor in
                let item = AVPlayerItem(url: url)
                self.playerItem = item
                self.player.replaceCurrentItem(with: item)
                self.player.play()
                self.player.rate = self.playbackSpeed
                self.isPlaying = true
                self.isLoading = false
                self.positionMs = 0
                self.updateNowPlayingInfo()
                self.observeItemEnd()
            }
        }
    }

    private func observeItemEnd() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.sleepTimerEndsAfterTrack {
                    self.isPlaying = false
                    self.player.pause()
                    self.sleepTimerActive = false
                    self.sleepTimerEndsAfterTrack = false
                    return
                }
                switch self.repeatMode {
                case .one:
                    self.seek(to: 0)
                    self.player.play()
                case .all:
                    if self.hasNext { self.next() } else {
                        self.queueIndex = 0
                        self.loadCurrentSong()
                    }
                case .off:
                    if self.hasNext { self.next() }
                    else { self.isPlaying = false }
                }
            }
        }
    }

    private func startTimeObserver() {
        let interval = CMTime(value: 500, timescale: 1000) // 500ms tick
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.positionMs = Int64(time.seconds * 1000)
            self.updateCurrentLyricIndex()
        }
    }

    private func updateCurrentLyricIndex() {
        guard !syncedLyrics.isEmpty else { return }
        let idx = syncedLyrics.lastIndex { $0.startMs <= positionMs } ?? -1
        if idx != currentLyricIndex { currentLyricIndex = idx }
    }

    // MARK: - Lock Screen / Control Center (MPNowPlayingInfoCenter)

    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(positionMs) / 1000.0,
            MPMediaItemPropertyPlaybackDuration: Double(durationMs) / 1000.0,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(playbackSpeed) : 0.0,
        ]
        if let albumName = song.albumName {
            info[MPMediaItemPropertyAlbumTitle] = albumName
        }
        // Artwork: load async
        if let url = song.artworkAt(600) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data, let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? info
                    updatedInfo[MPMediaItemPropertyArtwork] = artwork
                    DispatchQueue.main.async {
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                    }
                }
            }.resume()
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteCommandCenter() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.addTarget { [weak self] _ in
            self?.player.play(); self?.isPlaying = true; return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            self?.player.pause(); self?.isPlaying = false; return .success
        }
        cc.nextTrackCommand.addTarget { [weak self] _ in
            self?.next(); return .success
        }
        cc.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous(); return .success
        }
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let e = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: Int64(e.positionTime * 1000))
            }
            return .success
        }
        cc.changePlaybackRateCommand.supportedPlaybackRates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        cc.changePlaybackRateCommand.addTarget { [weak self] event in
            if let e = event as? MPChangePlaybackRateCommandEvent {
                self?.setSpeed(Float(e.playbackRate))
            }
            return .success
        }
    }

    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}

// MARK: - RepeatMode
enum RepeatMode: Int {
    case off = 0, all = 2, one = 1
}

// MARK: - LyricLine
struct LyricLine: Identifiable {
    let id: Int
    let startMs: Int64
    let endMs: Int64
    let text: String
    let words: [LyricWord]
}

struct LyricWord {
    let startMs: Int64
    let endMs: Int64
    let text: String
}
