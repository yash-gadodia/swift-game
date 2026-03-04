import XCTest
@testable import SwiftGame

final class SessionEnvelopeReducerTests: XCTestCase {
    func testRoleAssignedProducesStatusAndRole() {
        var reducer = SessionEnvelopeReducer(localPlayerId: UUID(), peerTracker: PeerLifecycleTracker())
        let envelope = RoomEnvelope(type: "role_assigned", senderId: nil, role: .dash, roomCode: "1234", message: nil)

        let outcome = reducer.apply(envelope)

        XCTAssertEqual(outcome.roleAssigned, .dash)
        XCTAssertEqual(outcome.statusText, "Role: Dash")
        XCTAssertNil(outcome.inboundMessage)
    }

    func testPeerJoinedDuplicateDoesNotEmitSecondConnect() {
        let remoteId = UUID()
        var reducer = SessionEnvelopeReducer(localPlayerId: UUID(), peerTracker: PeerLifecycleTracker())
        let first = RoomEnvelope(type: "peer_joined", senderId: remoteId, role: nil, roomCode: "1234", message: nil)
        let second = RoomEnvelope(type: "peer_joined", senderId: remoteId, role: nil, roomCode: "1234", message: nil)

        let firstOutcome = reducer.apply(first)
        let secondOutcome = reducer.apply(second)

        XCTAssertNotNil(firstOutcome.transition.connected)
        XCTAssertEqual(firstOutcome.statusText, "Partner connected")
        XCTAssertNil(secondOutcome.transition.connected)
        XCTAssertNil(secondOutcome.statusText)
    }

    func testRelayFromSelfIsIgnored() {
        let localPlayerId = UUID()
        var reducer = SessionEnvelopeReducer(localPlayerId: localPlayerId, peerTracker: PeerLifecycleTracker())
        let envelope = RoomEnvelope(
            type: "relay",
            senderId: localPlayerId,
            role: nil,
            roomCode: "1234",
            message: .ping(ts: 1)
        )

        let outcome = reducer.apply(envelope)
        XCTAssertNil(outcome.inboundMessage)
    }

    func testRelayFromRemoteProducesInboundMessage() {
        let localPlayerId = UUID()
        let remotePlayerId = UUID()
        var reducer = SessionEnvelopeReducer(localPlayerId: localPlayerId, peerTracker: PeerLifecycleTracker())
        let envelope = RoomEnvelope(
            type: "relay",
            senderId: remotePlayerId,
            role: nil,
            roomCode: "1234",
            message: .pong(ts: 2)
        )

        let outcome = reducer.apply(envelope)

        XCTAssertEqual(outcome.inboundMessage?.peer.id, remotePlayerId.uuidString)
        XCTAssertEqual(outcome.inboundMessage?.message, .pong(ts: 2))
    }

    func testPeerLeftClearsAndEmitsDisconnect() {
        let remoteId = UUID()
        var reducer = SessionEnvelopeReducer(localPlayerId: UUID(), peerTracker: PeerLifecycleTracker())
        _ = reducer.apply(RoomEnvelope(type: "peer_joined", senderId: remoteId, role: nil, roomCode: "1234", message: nil))

        let outcome = reducer.apply(RoomEnvelope(type: "peer_left", senderId: remoteId, role: nil, roomCode: "1234", message: nil))

        XCTAssertEqual(outcome.transition.disconnected?.id, remoteId.uuidString)
        XCTAssertEqual(outcome.statusText, "Partner disconnected")
    }
}
