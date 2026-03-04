import XCTest
@testable import SwiftGame

final class SessionLifecycleTrackerTests: XCTestCase {
    func testSetPeerEmitsConnectOnceForNewPeer() {
        var tracker = PeerLifecycleTracker()
        let peer = PeerSummary(id: "p1", displayName: "Partner")

        let first = tracker.setPeer(peer)
        let second = tracker.setPeer(peer)

        XCTAssertEqual(first.connected, peer)
        XCTAssertNil(first.disconnected)
        XCTAssertNil(second.connected)
        XCTAssertNil(second.disconnected)
    }

    func testSetPeerEmitsDisconnectThenConnectWhenPeerChanges() {
        var tracker = PeerLifecycleTracker()
        let firstPeer = PeerSummary(id: "p1", displayName: "Partner")
        let secondPeer = PeerSummary(id: "p2", displayName: "Partner")

        _ = tracker.setPeer(firstPeer)
        let transition = tracker.setPeer(secondPeer)

        XCTAssertEqual(transition.disconnected, firstPeer)
        XCTAssertEqual(transition.connected, secondPeer)
    }

    func testClearPeerRespectsNotifyFlag() {
        var tracker = PeerLifecycleTracker()
        let peer = PeerSummary(id: "p1", displayName: "Partner")
        _ = tracker.setPeer(peer)

        let silent = tracker.clearPeer(notify: false)
        XCTAssertNil(silent.connected)
        XCTAssertNil(silent.disconnected)

        _ = tracker.setPeer(peer)
        let notifying = tracker.clearPeer(notify: true)
        XCTAssertNil(notifying.connected)
        XCTAssertEqual(notifying.disconnected, peer)
    }
}
