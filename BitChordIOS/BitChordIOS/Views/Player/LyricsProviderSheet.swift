// LyricsProviderSheet.swift
// BitChordIOS
// Android ref: sharedUi/.../ui/player/LyricsProviderSheet.kt

import SwiftUI

/// Sheet to pick the lyrics provider.
/// Matches Android LyricsProviderSheet exactly — same 11 providers in same priority order.
struct LyricsProviderSheet: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    // Same priority order as Android LyricsProviders.kt
    private let providers: [(id: String, label: String, icon: String)] = [
        ("lrclib",        "LRCLib",           "music.note.list"),
        ("betterlyrics",  "BetterLyrics",     "text.alignleft"),
        ("paxsenix",      "PaxSenix",         "sparkles"),
        ("genius",        "Genius",            "lightbulb"),
        ("kugou",         "KuGou",            "music.note"),
        ("lyricsplus",    "Lyrics+",          "plus.circle"),
        ("musixmatch",    "Musixmatch",       "m.circle"),
        ("qqmusic",       "QQ Music",         "q.circle"),
        ("netease",       "NetEase",          "cloud"),
        ("megalobiz",     "Megalobiz",        "globe"),
        ("auto",          "Auto (default)",   "wand.and.stars"),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(providers, id: \.id) { provider in
                    Button {
                        playerVM.selectedLyricsProvider = provider.id
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: provider.icon)
                                .foregroundColor(.bcPrimary)
                                .frame(width: 28)
                            Text(provider.label)
                                .foregroundColor(.bcOnSurface)
                            Spacer()
                            if playerVM.selectedLyricsProvider == provider.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.bcPrimary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.bcBackground)
            .navigationTitle("Lyrics Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.bcPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

