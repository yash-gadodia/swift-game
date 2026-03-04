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
}
