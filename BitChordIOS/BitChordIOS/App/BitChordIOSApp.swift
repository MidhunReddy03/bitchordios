import SwiftUI
import AVFoundation
import UIKit

@main
struct BitChordIOSApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()

    init() {
        // Configure AVAudioSession for background playback
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: [.allowBluetooth, .allowBluetoothA2DP]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .environmentObject(playerViewModel)
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        // Match BitChord's dark Material3 look globally
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
}

