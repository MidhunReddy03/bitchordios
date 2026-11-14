import SwiftUI

/// Root view — tab bar + floating mini-player, mirroring BitChord Android's
/// bottom-nav + PlayerDock architecture.
struct ContentView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var appVM: AppViewModel
    @State private var selectedTab: Tab = .home
    @State private var showFullPlayer = false

    // iPhone 13 safe-area constants (matched to Android layout)
    // Mini-player sits just above the tab bar.
    private let miniPlayerHeight: CGFloat = 64

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                    .tabItem {
                        Label("Home", systemImage: "music.note.house.fill")
                    }

                ExploreView()
                    .tag(Tab.explore)
                    .tabItem {
                        Label("Explore", systemImage: "safari.fill")
                    }

                LibraryView()
                    .tag(Tab.library)
                    .tabItem {
                        Label("Library", systemImage: "music.note.list")
                    }

                SearchView()
                    .tag(Tab.search)
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
            }
            .accentColor(.white)
            // Extra bottom padding so list content clears the mini player
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: playerVM.currentSong != nil ? miniPlayerHeight : 0)
            }

            // Mini player dock — always above the tab bar, slides up into
            // full player on tap, matching BitChord's PlayerDock/PlayerHost.
            if playerVM.currentSong != nil {
                VStack(spacing: 0) {
                    MiniPlayerView(showFullPlayer: $showFullPlayer)
                        .frame(height: miniPlayerHeight)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 8)
                .padding(.bottom, 83) // 49pt tab bar + 34pt home indicator
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: playerVM.currentSong != nil)
                .onTapGesture { showFullPlayer = true }
            }
        }
        .sheet(isPresented: $showFullPlayer) {
            NowPlayingView()
                .environmentObject(playerVM)
        }
    }
}

enum Tab: Hashable {
    case home, explore, library, search
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
        .environmentObject(PlayerViewModel())
        .preferredColorScheme(.dark)
}

