// LyricsOffsetSheet.swift
// BitChordIOS
// Android ref: sharedUi/.../ui/player/LyricsOffsetSheet.kt

import SwiftUI

/// Sheet to adjust lyric timing offset (ms).
/// Matches Android LyricsOffsetSheet: same ±5000ms range, same 100ms step buttons.
struct LyricsOffsetSheet: View {
    @EnvironmentObject private var playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var offsetMs: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Current offset display
                VStack(spacing: 6) {
                    Text("Timing Offset")
                        .font(BCFont.titleMedium)
                        .foregroundColor(.bcOnSurface)
                    Text(offsetMs == 0 ? "No offset" : "\(offsetMs > 0 ? "+" : "")\(offsetMs) ms")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.bcPrimary)
                        .monospacedDigit()
                }
                .padding(.top, 32)

                // ± step buttons — matches Android LyricsOffsetSheet step row
                HStack(spacing: 16) {
                    ForEach([-500, -100], id: \.self) { step in
                        stepButton(step: step)
                    }
                    Spacer()
                    ForEach([100, 500], id: \.self) { step in
                        stepButton(step: step)
                    }
                }
                .padding(.horizontal, BCLayout.pageGutter)

                // Slider ±5000ms
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { Double(offsetMs) },
                            set: { offsetMs = Int($0) }
                        ),
                        in: -5000...5000,
                        step: 100
                    )
                    .tint(.bcPrimary)
                    .padding(.horizontal, BCLayout.pageGutter)

                    HStack {
                        Text("-5000ms")
                        Spacer()
                        Text("+5000ms")
                    }
                    .font(BCFont.caption)
                    .foregroundColor(.bcOnSurfaceVariant)
                    .padding(.horizontal, BCLayout.pageGutter)
                }

                // Reset
                Button("Reset to 0") {
                    withAnimation { offsetMs = 0 }
                }
                .foregroundColor(.bcOnSurfaceVariant)

                Spacer()
            }
            .background(Color.bcBackground)
            .navigationTitle("Lyric Timing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.bcPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        playerVM.lyricsOffsetMs = offsetMs
                        dismiss()
                    }
                    .foregroundColor(.bcPrimary)
                    .bold()
                }
            }
        }
        .onAppear { offsetMs = playerVM.lyricsOffsetMs }
        .preferredColorScheme(.dark)
    }

    private func stepButton(step: Int) -> some View {
        Button {
            withAnimation {
                offsetMs = max(-5000, min(5000, offsetMs + step))
            }
        } label: {
            Text("\(step > 0 ? "+" : "")\(step)ms")
                .font(BCFont.caption)
                .foregroundColor(.bcOnSurface)
                .frame(width: 68, height: 36)
                .background(Color.bcSurfaceVariant)
                .cornerRadius(18)
        }
    }
}

