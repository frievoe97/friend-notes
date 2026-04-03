import Foundation
import UserNotifications
import Combine

/// Supported navigation targets that can be opened from a tapped notification.
enum AppNotificationRoute: Equatable {
    case friend(id: String)
    case meeting(id: String)
    case followUp(id: String)
}

/// Shared store that buffers the most recent notification route until the UI consumes it.
final class NotificationRouteStore: ObservableObject {
    /// Process-wide shared route store used by app delegate and root UI.
    static let shared = NotificationRouteStore()

    /// Pending navigation target emitted after a notification tap.
    ///
    /// - Note: The route remains set until `consume()` is called by the UI.
    @Published private(set) var pendingRoute: AppNotificationRoute?

    private init() {}

    /// Parses a notification response and publishes a route when metadata is valid.
    ///
    /// - Parameter response: User interaction payload from `UNUserNotificationCenter`.
    /// - Side Effects: Mutates `pendingRoute` on the main thread when route metadata can be resolved.
    func handle(response: UNNotificationResponse) {
        handle(userInfo: response.notification.request.content.userInfo)
    }

    /// Clears any pending route after the UI has navigated.
    ///
    /// - Side Effects: Resets published state and can update subscribers.
    func consume() {
        pendingRoute = nil
    }

    /// Parses route metadata from notification payload user info.
    ///
    /// - Parameter userInfo: Raw notification metadata dictionary.
    /// - Note: Invalid or incomplete payloads are ignored intentionally.
    func handle(userInfo: [AnyHashable: Any]) {
        guard
            let routeType = userInfo["route_type"] as? String,
            let routeID = userInfo["route_id"] as? String,
            !routeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        switch routeType {
        case "friend":
            publish(.friend(id: routeID))
        case "meeting":
            publish(.meeting(id: routeID))
        case "followup":
            publish(.followUp(id: routeID))
        default:
            break
        }
    }

    /// Publishes a route on the main thread to satisfy `@Published` UI expectations.
    ///
    /// - Parameter route: Route to emit.
    private func publish(_ route: AppNotificationRoute) {
        if Thread.isMainThread {
            pendingRoute = route
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.pendingRoute = route
            }
        }
    }
}
