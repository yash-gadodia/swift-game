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

    func testIgnoresOutOfOrderOrDuplicateSequences() {
        let state = GameState(localPosition: .zero)
        let playerId = UUID()

        let first = PlayerStatePacket(
            playerId: playerId,
            seq: 3,
            ts: 1,
            position: Vector2(SIMD2<Float>(1, 1)),
            velocity: Vector2(.zero)
        )
        let duplicate = PlayerStatePacket(
            playerId: playerId,
            seq: 3,
            ts: 1.1,
            position: Vector2(SIMD2<Float>(2, 2)),
            velocity: Vector2(.zero)
        )
        let outOfOrder = PlayerStatePacket(
            playerId: playerId,
            seq: 2,
            ts: 0.9,
            position: Vector2(SIMD2<Float>(3, 3)),
            velocity: Vector2(.zero)
        )

        state.applyRemoteSnapshot(first)
        state.applyRemoteSnapshot(duplicate)
        state.applyRemoteSnapshot(outOfOrder)

        XCTAssertEqual(state.remoteSnapshots.count, 1)
        XCTAssertEqual(state.remoteSnapshots.first?.seq, 3)
        XCTAssertEqual(state.remoteSnapshots.first?.position.x ?? .zero, Float(1), accuracy: Float(0.001))
    }

    func testRemoteSnapshotBufferIsBoundedTo32() {
        let state = GameState(localPosition: .zero)
        let playerId = UUID()

        for idx in 1...40 {
            let packet = PlayerStatePacket(
                playerId: playerId,
                seq: UInt32(idx),
                ts: TimeInterval(idx),
                position: Vector2(SIMD2<Float>(Float(idx), 0)),
                velocity: Vector2(.zero)
            )
            state.applyRemoteSnapshot(packet)
        }

        XCTAssertEqual(state.remoteSnapshots.count, 32)
        XCTAssertEqual(state.remoteSnapshots.first?.seq, 9)
        XCTAssertEqual(state.remoteSnapshots.last?.seq, 40)
    }
}
