// AuthViews.swift
// BitChordIOS
// Android ref: sharedUi/.../ui/screens/YtMusicLoginScreen.kt
//              sharedUi/.../ui/screens/SpotifyLoginScreen.kt
//              sharedUi/.../ui/screens/DiscordLoginScreen.kt

import SwiftUI
import WebKit

// MARK: - YTMusic Login
/// WebView-based Google / YouTube Music sign-in.
/// Mirrors YtMusicLoginScreen.kt exactly — same WKWebView flow,
/// cookies extracted for InnerTube auth.
struct YTMusicLoginView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            YTLoginWebView(onSuccess: {
                appVM.isSignedIn = true
                dismiss()
            })
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Sign in with Google")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.bcPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct YTLoginWebView: UIViewRepresentable {
    let onSuccess: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSuccess: onSuccess) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // TODO: Configure cookie store for InnerTube auth extraction
        // Android ref: YtMusicLoginScreen.kt → CookieManager.getInstance()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        // Load Google accounts sign-in page (same URL as Android)
        let url = URL(string: "https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https://music.youtube.com/")!
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        let onSuccess: () -> Void
        init(onSuccess: @escaping () -> Void) { self.onSuccess = onSuccess }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url?.absoluteString else { return }
            // Detect successful redirect to YouTube Music
            // TODO: Extract SAPISID/HSID cookies for InnerTube
            // Android ref: YtMusicLoginScreen.kt → extractCookies()
            if url.contains("music.youtube.com") && !url.contains("accounts.google.com") {
                onSuccess()
            }
        }
    }
}

// MARK: - Spotify Login
/// OAuth-based Spotify sign-in.
/// Android ref: SpotifyLoginScreen.kt → SpotifyAppRemote
/// TODO: Wire SpotifyiOS SDK or OAuth PKCE flow once SDK is integrated.
struct SpotifyLoginView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "#1DB954"))

                Text("Connect Spotify")
                    .font(BCFont.titleLarge)
                    .foregroundColor(.bcOnSurface)

                Text("BitChord uses Spotify to show your playlists alongside YouTube Music content.")
                    .font(BCFont.bodyMedium)
                    .foregroundColor(.bcOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCLayout.pageGutter)

                Button {
                    // TODO: Launch Spotify OAuth PKCE
                    // Android ref: SpotifyLoginScreen.kt → SpotifyAppRemote.connect()
                } label: {
                    Text("Connect with Spotify")
                        .font(BCFont.bodyLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#1DB954"))
                        .cornerRadius(25)
                        .padding(.horizontal, BCLayout.pageGutter)
                }

                Spacer()
            }
            .padding(.top, 60)
            .background(Color.bcBackground)
            .navigationTitle("Spotify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.bcPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Discord Login
/// Discord in-app login for Discord RPC (Rich Presence).
/// Android ref: DiscordLoginScreen.kt → DiscordRPC token flow
/// TODO: Wire Discord OAuth + RPC once Discord iOS SDK/REST is integrated.
struct DiscordLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tokenInput = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "#5865F2"))

                Text("Discord Rich Presence")
                    .font(BCFont.titleLarge)
                    .foregroundColor(.bcOnSurface)

                Text("Show what you're listening to on your Discord profile.")
                    .font(BCFont.bodyMedium)
                    .foregroundColor(.bcOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCLayout.pageGutter)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Discord Bot Token")
                        .font(BCFont.caption)
                        .foregroundColor(.bcOnSurfaceVariant)
                    SecureField("Paste token here", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, BCLayout.pageGutter)
                }

                Button {
                    // TODO: Validate token + start RPC session
                    // Android ref: DiscordLoginScreen.kt → DiscordRPC.start()
                    dismiss()
                } label: {
                    Text("Connect Discord")
                        .font(BCFont.bodyLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#5865F2"))
                        .cornerRadius(25)
                        .padding(.horizontal, BCLayout.pageGutter)
                }
                .disabled(tokenInput.isEmpty)

                Spacer()
            }
            .padding(.top, 60)
            .background(Color.bcBackground)
            .navigationTitle("Discord")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.bcPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Color hex helper (local, avoids duplication if already in DesignSystem)
private extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

