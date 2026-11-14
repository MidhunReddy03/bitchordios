import SwiftUI

// MARK: - Layout Constants (iPhone 13 exact)
/// Mirrors BitChord Android's layout tokens for exact 1-to-1 pixel behaviour.
enum BCLayout {
    // Page gutter: matches Android PAGE_GUTTER 16dp
    static let pageGutter: CGFloat = 16

    // Player gutter: matches PLAYER_GUTTER 30dp
    static let playerGutter: CGFloat = 30

    // iPhone 13 screen: 390 × 844 pt
    static let screenWidth: CGFloat = 390
    static let screenHeight: CGFloat = 844

    // Safe-area offsets (approximated; use safeAreaInsets in production)
    static let statusBarHeight: CGFloat = 47   // notch + status area
    static let homeIndicator: CGFloat = 34     // home indicator bar
    static let tabBarHeight: CGFloat = 83      // 49 bar + 34 safe area

    // Mini-player above tab bar
    static let miniPlayerHeight: CGFloat = 64

    // Card widths (matches Android SHELF_CARD_WIDTH ~160dp)
    static let shelfCardWidth: CGFloat = 160
    static let videoCardWidth: CGFloat = 220

    // Row art size
    static let rowArtSize: CGFloat = 48
    static let searchArtSize: CGFloat = 52

    // Player constants
    static let artBoxTopPad: CGFloat = 8
    static let playerMaxWidth: CGFloat = 560
}

// MARK: - Colour Palette (Material3 dark, matches BitChord theme)
extension Color {
    // Primary accent (BitChord uses artwork-extracted palette; fall back to white)
    static let bcPrimary          = Color.white
    static let bcOnPrimary        = Color.black
    static let bcBackground       = Color(white: 0.08)
    static let bcSurface          = Color(white: 0.12)
    static let bcSurfaceVar       = Color(white: 0.18)
    static let bcSurfaceVariant   = Color(white: 0.18)
    static let bcOnBackground     = Color.white
    static let bcOnSurface        = Color.white
    static let bcOnSurfaceVar     = Color(white: 0.65)
    static let bcOnSurfaceVariant = Color(white: 0.65)
    static let bcOutline          = Color(white: 0.25)
    static let bcError            = Color(red: 0.9, green: 0.3, blue: 0.3)
}

// MARK: - Typography (Material3 scale, closest SF Pro equivalents)
extension Font {
    static let bcDisplayLarge  = Font.system(size: 32, weight: .bold,   design: .default)
    static let bcHeadlineLarge = Font.system(size: 24, weight: .bold,   design: .default)
    static let bcTitleLarge    = Font.system(size: 22, weight: .semibold)
    static let bcTitleMedium   = Font.system(size: 16, weight: .semibold)
    static let bcTitleSmall    = Font.system(size: 14, weight: .semibold)
    static let bcBodyLarge     = Font.system(size: 16, weight: .regular)
    static let bcBodyMedium    = Font.system(size: 14, weight: .regular)
    static let bcBodySmall     = Font.system(size: 12, weight: .regular)
    static let bcLabelLarge    = Font.system(size: 14, weight: .medium)
    static let bcLabelMedium   = Font.system(size: 12, weight: .medium)
    static let bcLabelSmall    = Font.system(size: 11, weight: .medium)
}

enum BCFont {
    static let displayLarge  = Font.system(size: 32, weight: .bold)
    static let headlineLarge = Font.system(size: 24, weight: .bold)
    static let titleLarge    = Font.system(size: 22, weight: .semibold)
    static let titleMedium   = Font.system(size: 16, weight: .semibold)
    static let titleSmall    = Font.system(size: 14, weight: .semibold)
    static let bodyLarge     = Font.system(size: 16, weight: .regular)
    static let bodyMedium    = Font.system(size: 14, weight: .regular)
    static let bodySmall     = Font.system(size: 12, weight: .regular)
    static let labelLarge    = Font.system(size: 14, weight: .medium)
    static let labelMedium   = Font.system(size: 12, weight: .medium)
    static let labelSmall    = Font.system(size: 11, weight: .medium)
    static let caption       = Font.system(size: 12, weight: .regular)
    static let caption2      = Font.system(size: 10, weight: .regular)
}

// MARK: - Modifiers

/// Fading horizontal edge effect (matches BitChord's FadingEdges)
struct FadingEdgeModifier: ViewModifier {
    let edge: Edge
    let fraction: CGFloat

    func body(content: Content) -> some View {
        content.mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: fraction),
                    .init(color: .black, location: 1 - fraction),
                    .init(color: .clear, location: 1),
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

extension View {
    func fadingEdges(fraction: CGFloat = 0.08) -> some View {
        modifier(FadingEdgeModifier(edge: .leading, fraction: fraction))
    }

    func thumbnailBorder(cornerRadius: CGFloat = 8) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - Skeleton shimmer
struct SkeletonView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color(white: 0.18), Color(white: 0.28), Color(white: 0.18)]),
                    startPoint: .init(x: phase - 1, y: 0),
                    endPoint: .init(x: phase, y: 0)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

// MARK: - Artwork async image (wraps AsyncImage with placeholder)
struct ArtworkImage: View {
    let url: URL?
    let cornerRadius: CGFloat

    init(url: URL?, cornerRadius: CGFloat = 8) {
        self.url = url
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                SkeletonView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Color.bcSurfaceVar
                    .overlay(Image(systemName: "music.note").foregroundColor(.bcOnSurfaceVar))
            @unknown default:
                Color.bcSurface
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .thumbnailBorder(cornerRadius: cornerRadius)
    }
}

// MARK: - Playing bars animation (matches BitChord's SearchPlayingBars)
struct PlayingBarsView: View {
    @State private var heights: [CGFloat] = [0.3, 0.7, 0.5, 0.9]
    let barCount = 4
    let barWidth: CGFloat = 3
    let maxHeight: CGFloat = 16
    let color: Color

    init(color: Color = .bcPrimary) {
        self.color = color
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: barWidth, height: heights[i] * maxHeight)
                    .animation(
                        .easeInOut(duration: 0.5 + Double(i) * 0.15)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: heights[i]
                    )
            }
        }
        .onAppear { animate() }
    }

    private func animate() {
        for i in 0..<barCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation { heights[i] = CGFloat.random(in: 0.4...1.0) }
            }
        }
        // Keep animating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { animate() }
    }
}

// MARK: - Sign-in Banner (matches BitChord's SignInBanner)
struct SignInBannerView: View {
    let onSignIn: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.bcOnSurfaceVar)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sign in for personalized content")
                    .font(.bcTitleSmall)
                    .foregroundColor(.bcOnBackground)
                Text("Your playlists, recommendations and history")
                    .font(.bcBodySmall)
                    .foregroundColor(.bcOnSurfaceVar)
            }
            Spacer()
            Button("Sign in", action: onSignIn)
                .font(.bcLabelMedium)
                .foregroundColor(.bcPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.bcSurfaceVar)
                .clipShape(Capsule())
        }
        .padding(BCLayout.pageGutter)
        .background(Color.bcSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, BCLayout.pageGutter)
        .padding(.bottom, 8)
    }
}

// MARK: - Message State (empty / error)
struct MessageStateView: View {
    let message: String
    let actionLabel: String?
    let onAction: (() -> Void)?

    init(_ message: String, actionLabel: String? = nil, onAction: (() -> Void)? = nil) {
        self.message = message
        self.actionLabel = actionLabel
        self.onAction = onAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.bcBodyMedium)
                .foregroundColor(.bcOnSurfaceVar)
                .multilineTextAlignment(.center)
            if let label = actionLabel, let action = onAction {
                Button(label, action: action)
                    .font(.bcLabelMedium)
                    .foregroundColor(.bcPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - Pill Segmented Control (matches BitChord's PillSegmentedControl)
struct PillSegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, label in
                    Button(action: { withAnimation(.spring(response: 0.3)) { selectedIndex = i } }) {
                        Text(label)
                            .font(.bcLabelMedium)
                            .foregroundColor(selectedIndex == i ? .black : .bcOnSurfaceVar)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedIndex == i
                                    ? Color.white
                                    : Color.bcSurfaceVar
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

