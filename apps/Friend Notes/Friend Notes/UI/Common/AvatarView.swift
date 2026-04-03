import SwiftUI

// MARK: - AvatarView

/// Circular avatar that renders deterministic initials and color from a name string.
struct AvatarView: View {
    /// Display name used to derive initials and color.
    let name: String
    /// Avatar diameter in points.
    let size: CGFloat
    /// Stable seed used only for color hashing.
    private let colorSeed: String

    /// Creates an avatar from a raw name string.
    ///
    /// - Parameters:
    ///   - name: Name source used for initials.
    ///   - size: Avatar diameter.
    ///   - colorSeed: Optional seed used for deterministic color hashing.
    init(name: String, size: CGFloat, colorSeed: String? = nil) {
        self.name = name
        self.size = size
        self.colorSeed = colorSeed ?? name
    }

    /// Creates an avatar from a friend model using canonical avatar identity rules.
    ///
    /// - Parameters:
    ///   - friend: Friend used to derive initials and stable color.
    ///   - size: Avatar diameter.
    init(friend: Friend, size: CGFloat) {
        self.init(
            name: friend.avatarInitialsSource,
            size: size,
            colorSeed: friend.avatarColorSeed
        )
    }

    private var initials: String {
        let words = name.split(separator: " ").map(String.init)
        let letters = words.prefix(2).compactMap { $0.first }
        return letters.map(String.init).joined().uppercased()
    }

    private var backgroundColor: Color {
        let palette: [Color] = [
            AppTheme.accent,
            AppTheme.event,
            AppTheme.birthday,
            .teal,
            .indigo,
            .mint,
            .cyan,
            .blue
        ]
        guard !colorSeed.isEmpty else { return .gray.opacity(0.85) }
        let hash = colorSeed.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }

    var body: some View {
        Circle()
            .fill(backgroundColor.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(initials.isEmpty ? "?" : initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
    }
}
