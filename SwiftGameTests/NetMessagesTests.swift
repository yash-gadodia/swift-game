import XCTest
@testable import SwiftGame
import simd

final class NetMessagesTests: XCTestCase {
    func testNetMessageRoundTrip() throws {
        let packet = PlayerStatePacket(
            playerId: UUID(),
            seq: 9,
            ts: 123.45,
            position: Vector2(SIMD2<Float>(10, 20)),
            velocity: Vector2(SIMD2<Float>(1, -2))
        )

        let samples: [NetMessage] = [
            .hello(playerId: UUID()),
            .playerState(packet),
            .gameEvent(GameEventPacket(type: "anchor_switch", actorId: UUID(), value: true, ts: 101)),
            .ping(ts: 99),
            .pong(ts: 100)
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for sample in samples {
            let data = try encoder.encode(sample)
            let decoded = try decoder.decode(NetMessage.self, from: data)
            XCTAssertEqual(decoded, sample)
        }
    }

    func testRoomEnvelopeDecodesWithoutVersionForBackwardCompatibility() throws {
        let json = """
        {
          "type": "relay",
          "senderId": "\(UUID().uuidString)",
          "roomCode": "1234",
          "message": {
            "type": "ping",
            "ping": 42
          }
        }
        """

        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(RoomEnvelope.self, from: data)

        XCTAssertEqual(decoded.version, ProtocolVersion.current)
        XCTAssertEqual(decoded.type, "relay")
    }

    func testRoomEnvelopeRoundTripPreservesVersion() throws {
        let sample = RoomEnvelope(
            version: 7,
            type: "relay",
            senderId: UUID(),
            role: .anchor,
            roomCode: "1234",
            message: .pong(ts: 12.3)
        )

        let data = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(RoomEnvelope.self, from: data)
        XCTAssertEqual(decoded, sample)
    }

    func testReconnectBackoffPolicyUsesExponentialDelayWithCap() {
        let policy = ReconnectBackoffPolicy(baseDelay: 0.5, maxDelay: 5, maxAttempts: 6)

        XCTAssertEqual(policy.delay(forAttempt: 1), 0.5, accuracy: 0.0001)
        XCTAssertEqual(policy.delay(forAttempt: 2), 1.0, accuracy: 0.0001)
        XCTAssertEqual(policy.delay(forAttempt: 3), 2.0, accuracy: 0.0001)
        XCTAssertEqual(policy.delay(forAttempt: 4), 4.0, accuracy: 0.0001)
        XCTAssertEqual(policy.delay(forAttempt: 5), 5.0, accuracy: 0.0001)
        XCTAssertEqual(policy.delay(forAttempt: 6), 5.0, accuracy: 0.0001)
    }

    func testReconnectBackoffPolicyHonorsAttemptBounds() {
        let policy = ReconnectBackoffPolicy(baseDelay: 0.5, maxDelay: 5, maxAttempts: 6)

        XCTAssertFalse(policy.canRetry(attempt: 0))
        XCTAssertTrue(policy.canRetry(attempt: 1))
        XCTAssertTrue(policy.canRetry(attempt: 6))
        XCTAssertFalse(policy.canRetry(attempt: 7))
    }
}
