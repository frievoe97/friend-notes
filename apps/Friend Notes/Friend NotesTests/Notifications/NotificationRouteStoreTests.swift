import Combine
import XCTest
@testable import Friend_Notes

final class NotificationRouteStoreTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        NotificationRouteStore.shared.consume()
    }

    override func tearDown() {
        cancellables.removeAll()
        NotificationRouteStore.shared.consume()
        super.tearDown()
    }

    func testHandleUserInfoPublishesFriendRoute() {
        NotificationRouteStore.shared.handle(userInfo: [
            "route_type": "friend",
            "route_id": "friend-123",
        ])

        XCTAssertEqual(NotificationRouteStore.shared.pendingRoute, .friend(id: "friend-123"))
    }

    func testHandleUserInfoPublishesMeetingRoute() {
        NotificationRouteStore.shared.handle(userInfo: [
            "route_type": "meeting",
            "route_id": "meeting-123",
        ])

        XCTAssertEqual(NotificationRouteStore.shared.pendingRoute, .meeting(id: "meeting-123"))
    }

    func testHandleUserInfoPublishesFollowUpRoute() {
        NotificationRouteStore.shared.handle(userInfo: [
            "route_type": "followup",
            "route_id": "followup-123",
        ])

        XCTAssertEqual(NotificationRouteStore.shared.pendingRoute, .followUp(id: "followup-123"))
    }

    func testHandleUserInfoIgnoresMissingRouteType() {
        NotificationRouteStore.shared.handle(userInfo: [
            "route_id": "friend-123",
        ])

        XCTAssertNil(NotificationRouteStore.shared.pendingRoute)
    }

    func testHandleUserInfoIgnoresMissingRouteID() {
        NotificationRouteStore.shared.handle(userInfo: [
            "route_type": "friend",
        ])

        XCTAssertNil(NotificationRouteStore.shared.pendingRoute)
    }

    func testHandleUserInfoIgnoresWhitespaceOnlyRouteID() {
        NotificationRouteStore.shared.handle(userInfo: [
            "route_type": "friend",
            "route_id": "   ",
        ])

        XCTAssertNil(NotificationRouteStore.shared.pendingRoute)
    }

    func testHandleUserInfoIgnoresUnknownRouteType() {
        NotificationRouteStore.shared.handle(userInfo: [
            "route_type": "unknown",
            "route_id": "id-1",
        ])

        XCTAssertNil(NotificationRouteStore.shared.pendingRoute)
    }

    func testConsumeClearsPendingRoute() {
        NotificationRouteStore.shared.handle(userInfo: [
            "route_type": "friend",
            "route_id": "friend-123",
        ])
        XCTAssertNotNil(NotificationRouteStore.shared.pendingRoute)

        NotificationRouteStore.shared.consume()

        XCTAssertNil(NotificationRouteStore.shared.pendingRoute)
    }

    func testBackgroundPublishingArrivesOnMainThread() {
        let publishedOnMainExpectation = expectation(description: "route published on main thread")

        NotificationRouteStore.shared.$pendingRoute
            .dropFirst()
            .sink { route in
                guard case .meeting(let id)? = route else { return }
                XCTAssertEqual(id, "meeting-background")
                XCTAssertTrue(Thread.isMainThread)
                publishedOnMainExpectation.fulfill()
            }
            .store(in: &cancellables)

        DispatchQueue.global(qos: .userInitiated).async {
            NotificationRouteStore.shared.handle(userInfo: [
                "route_type": "meeting",
                "route_id": "meeting-background",
            ])
        }

        wait(for: [publishedOnMainExpectation], timeout: 2.0)
    }
}
