import UIKit

/// Utility for forcing first-responder resignation when focus state alone is insufficient.
enum Keyboard {
    /// Attempts to dismiss the currently active keyboard responder.
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

