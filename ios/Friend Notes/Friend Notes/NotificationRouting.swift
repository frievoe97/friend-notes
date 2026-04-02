import Foundation
import UserNotifications
import Combine

/// Supported navigation targets that can be opened from a tapped notification.
enum AppNotificationRoute: Equatable {
    case friend(id: String)
    case meeting(id: String)
}

/// Shared store that buffers the most recent notification route until the UI consumes it.
final class NotificationRouteStore: ObservableObject {
    static let shared = NotificationRouteStore()

    @Published private(set) var pendingRoute: AppNotificationRoute?

    private init() {}

    /// Parses a notification response and publishes a route when metadata is valid.
    func handle(response: UNNotificationResponse) {
        handle(userInfo: response.notification.request.content.userInfo)
    }

    /// Clears any pending route after the UI has navigated.
    func consume() {
        pendingRoute = nil
    }

    /// Parses route metadata from notification payload user info.
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
        default:
            break
        }
    }

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
