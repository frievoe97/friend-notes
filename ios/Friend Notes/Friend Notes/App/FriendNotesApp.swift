import SwiftUI
import SwiftData
import UserNotifications
import UIKit

/// Application delegate responsible for notification delegate wiring.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Configures notification center delegation at app launch.
    ///
    /// - Parameters:
    ///   - application: The running application instance.
    ///   - launchOptions: Optional launch metadata provided by the system.
    /// - Returns: `true` when launch setup succeeds.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// Defines presentation behavior for notifications while app is in foreground.
    ///
    /// - Parameters:
    ///   - center: The notification center delivering the notification.
    ///   - notification: The notification to present.
    ///   - completionHandler: Callback that receives selected presentation options.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Handles user taps on local notifications and forwards deep-link metadata to the UI layer.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationRouteStore.shared.handle(response: response)
        completionHandler()
    }
}

/// Main application entry point and root model container bootstrap.
///
/// Boots the app, wires the shared model container, and installs root UI.
@main
struct FriendNotesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Shared persistent SwiftData container for app models.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Friend.self, Meeting.self, GiftIdea.self, FriendEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// Root scene definition for the app.
    var body: some Scene {
        WindowGroup {
            RootSplashContainerView()
                .tint(AppTheme.accent)
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Root container that shows a short branded splash before entering main content.
private struct RootSplashContainerView: View {
    /// Local splash gate to keep launch animation state private to this container.
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.25)) {
                showSplash = false
            }
        }
    }
}

/// Simple launch splash that stays visible for a short moment.
private struct SplashView: View {
    var body: some View {
        ZStack {
            AppGradientBackground()
            VStack(spacing: 14) {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                Text("FriendNotes")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .ignoresSafeArea()
    }
}
