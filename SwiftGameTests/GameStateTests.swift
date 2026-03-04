import XCTest
@testable import SwiftGame
import simd

final class GameStateTests: XCTestCase {
    func testInterpolatesBetweenSnapshots() {
        let state = GameState(localPosition: .zero)

        let p1 = PlayerStatePacket(
            playerId: UUID(),
            seq: 1,
            ts: 10,
            position: Vector2(SIMD2<Float>(0, 0)),
            velocity: Vector2(SIMD2<Float>(10, 0))
        )
        let p2 = PlayerStatePacket(
            playerId: p1.playerId,
            seq: 2,
            ts: 10.2,
            position: Vector2(SIMD2<Float>(20, 0)),
            velocity: Vector2(SIMD2<Float>(10, 0))
        )

        state.applyRemoteSnapshot(p1)
        state.applyRemoteSnapshot(p2)

        let result = state.interpolatedRemotePosition(at: 10.2, interpolationDelay: 0.1)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.x ?? -1, 10, accuracy: 0.001)
    }

    func testExtrapolatesWhenOnlyOneSnapshot() {
        let state = GameState(localPosition: .zero)

        let p1 = PlayerStatePacket(
            playerId: UUID(),
            seq: 1,
            ts: 5,
            position: Vector2(SIMD2<Float>(2, 3)),
            velocity: Vector2(SIMD2<Float>(4, 0))
        )

        state.applyRemoteSnapshot(p1)
        let result = state.interpolatedRemotePosition(at: 5.2, interpolationDelay: 0)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.x ?? -1, 2.8, accuracy: 0.001)
        XCTAssertEqual(result?.y ?? -1, 3, accuracy: 0.001)
    }
}
