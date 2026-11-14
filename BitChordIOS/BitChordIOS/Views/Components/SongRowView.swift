// SongRowView.swift
// BitChordIOS — extracted shared component
// Android ref: sharedUi/.../ui/components/SongRow.kt

import SwiftUI

/// Unified song row used across Home, Search, Library, Queue.
/// Matches Android `SongRow` composable dimensions exactly.
struct SongRowView: View {
    let song: Song
    var isCurrent: Bool = false
    var isPlaying: Bool = false
    var showIndex: Int? = nil
    var onTap: (() -> Void)? = nil
    var onMore: (() -> Void)? = nil
    var onLongPress: (() -> Void)? = nil

    @EnvironmentObject private var playerVM: PlayerViewModel

    private var active: Bool {
        isCurrent || (playerVM.currentSong?.videoId == song.videoId && !song.videoId.isEmpty) || (playerVM.currentSong?.id == song.id)
    }

    private var playing: Bool {
        isPlaying || (active && playerVM.isPlaying)
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Leading: index number OR playing bars OR artwork
                if playing {
                    PlayingBarsView()
                        .frame(width: 40, height: 40)
                } else if let idx = showIndex {
                    Text("\(idx)")
                        .font(BCFont.caption)
                        .foregroundColor(.bcOnSurfaceVariant)
                        .frame(width: 40, height: 40)
                        .multilineTextAlignment(.center)
                } else {
                    ArtworkImage(
                        url: song.artworkAt(ArtworkSize.rowArt) ?? song.thumbnailUrl.flatMap(URL.init(string:)),
                        cornerRadius: 6
                    )
                        .frame(width: 40, height: 40)
                }

                // Title + artist
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(BCFont.bodyMedium)
                        .foregroundColor(active ? .bcPrimary : .bcOnSurface)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if song.isExplicit {
                            ExplicitBadge()
                        }
                        Text(song.artist)
                            .font(BCFont.caption)
                            .foregroundColor(.bcOnSurfaceVariant)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                // More button
                Button(action: {
                    if let onMore = onMore {
                        onMore()
                    } else if let onLongPress = onLongPress {
                        onLongPress()
                    }
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.bcOnSurfaceVariant)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, BCLayout.pageGutter)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture().onEnded { _ in
                onLongPress?()
            }
        )
    }
}

/// Small explicit "E" badge — matches Android ExplicitBadge composable.
struct ExplicitBadge: View {
    var body: some View {
        Text("E")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.bcOnSurfaceVariant)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.bcOnSurfaceVariant, lineWidth: 0.8)
            )
    }
}
