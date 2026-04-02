import SwiftUI

/// Full-screen decorative gradient background used across major screens.
struct AppGradientBackground: View {
    var body: some View {
        GeometryReader { _ in
            ZStack {
                LinearGradient(
                    colors: [
                        AppTheme.backgroundTop,
                        AppTheme.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(AppTheme.backgroundOrbPrimary.opacity(0.4))
                    .frame(width: 500, height: 500)
                    .blur(radius: 120)
                    .offset(x: -180, y: -180)

                Circle()
                    .fill(AppTheme.backgroundOrbSecondary.opacity(0.35))
                    .frame(width: 600, height: 600)
                    .blur(radius: 140)
                    .offset(x: 200, y: 200)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
