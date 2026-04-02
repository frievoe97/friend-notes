import SwiftUI

/// Gradient background variant intended for sheets so intrinsic sizing remains intact.
struct SheetGradientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.backgroundOrbPrimary.opacity(0.36))
                .frame(width: 260, height: 260)
                .blur(radius: 72)
                .offset(x: -120, y: -90)

            Circle()
                .fill(AppTheme.backgroundOrbSecondary.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 86)
                .offset(x: 130, y: 130)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
