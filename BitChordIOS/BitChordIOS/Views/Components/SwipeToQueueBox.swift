// SwipeToQueueBox.swift
// BitChordIOS
// Android ref: sharedUi/.../ui/components/SwipeToQueueBox.kt

import SwiftUI

/// Wraps any view with a right-swipe gesture that queues the song next.
/// Matches Android `SwipeToQueueBox` — same swipe direction, same reveal icon.
struct SwipeToQueueBox<Content: View>: View {
    let song: Song
    @ViewBuilder let content: () -> Content

    @EnvironmentObject private var playerVM: PlayerViewModel
    @State private var offset: CGFloat = 0
    @State private var revealed = false

    private let revealThreshold: CGFloat = 72
    private let iconWidth: CGFloat = 72

    var body: some View {
        ZStack(alignment: .leading) {
            // Swipe-reveal background
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "text.line.last.and.arrowtriangle.forward")
                        .font(.system(size: 20))
                    Text("Next")
                        .font(BCFont.caption2)
                }
                .foregroundColor(.bcOnPrimary)
                .frame(width: iconWidth)
                .frame(maxHeight: .infinity)
                .background(Color.bcPrimary)
                .opacity(min(1, abs(offset) / revealThreshold))
            }

            content()
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            // Right-to-left swipe only (negative translation = left)
                            // Android SwipeToQueueBox reveals from the right
                            if value.translation.width < 0 {
                                offset = max(-iconWidth * 1.2, value.translation.width)
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -revealThreshold {
                                // Trigger queue-next
                                playerVM.queueNext(song)
                                withAnimation(.spring()) { offset = 0 }
                                // Haptic
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } else {
                                withAnimation(.spring()) { offset = 0 }
                            }
                        }
                )
        }
        .clipped()
    }
}

