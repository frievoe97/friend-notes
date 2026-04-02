import SwiftUI
import SafariServices

// MARK: - In-App Browser

/// Lightweight Safari sheet wrapper for opening links without leaving the app.
struct InAppBrowserView: UIViewControllerRepresentable {
    /// URL to open inside the embedded browser.
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No-op: SFSafariViewController is configured on creation.
    }
}
