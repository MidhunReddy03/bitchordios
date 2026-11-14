// FrostedTopBar.swift
// BitChordIOS
// Android ref: sharedUi/.../ui/components/FrostedTopBar (Haze library blur overlay)

import SwiftUI

/// Ultra-thin frosted bar that sits above scrollable content on Search and Library tabs.
/// Height = safe-area top + 49pt (matches Android toolbar height).
/// Uses `.ultraThinMaterial` to replicate Haze blur.
struct FrostedTopBar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Frosted material fill (extends into status bar)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: geo.safeAreaInsets.top + 49)
                    .ignoresSafeArea(edges: .top)

                // Content (title / search field) sits at the bottom of the bar
                content()
                    .padding(.bottom, 8)
                    .padding(.horizontal, BCLayout.pageGutter)
            }
            .frame(height: geo.safeAreaInsets.top + 49)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .top)
        }
        .frame(height: 49) // layout height (safe area handled via ignoresSafeArea)
    }
}

