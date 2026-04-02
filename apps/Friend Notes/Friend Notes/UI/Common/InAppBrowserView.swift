import SwiftUI
import SafariServices

// MARK: - In-App Browser

/// Lightweight Safari sheet wrapper for opening links without leaving the app.
struct InAppBrowserView: UIViewControllerRepresentable {
    /// URL to open inside the embedded browser.
    let url: URL

    /// Creates the Safari controller shown by this representable.
    ///
    /// - Parameter context: SwiftUI context bridge.
    /// - Returns: Configured `SFSafariViewController`.
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }

    /// Updates the hosted Safari controller.
    ///
    /// - Parameters:
    ///   - uiViewController: Hosted Safari controller instance.
    ///   - context: SwiftUI context bridge.
    /// - Note: No-op because this wrapper has immutable URL input.
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No-op: SFSafariViewController is configured on creation.
    }
}
