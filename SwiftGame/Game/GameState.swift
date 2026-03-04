import Foundation
import simd

final class GameState {
    struct RemoteSnapshot {
        let seq: UInt32
        let ts: TimeInterval
        let position: SIMD2<Float>
        let velocity: SIMD2<Float>
    }

    var localPosition: SIMD2<Float>
    var localVelocity: SIMD2<Float> = .zero

    private(set) var remoteSnapshots: [RemoteSnapshot] = []

    init(localPosition: SIMD2<Float>) {
        self.localPosition = localPosition
    }

    func applyRemoteSnapshot(_ packet: PlayerStatePacket) {
        let snapshot = RemoteSnapshot(
            seq: packet.seq,
            ts: packet.ts,
            position: packet.position.simd,
            velocity: packet.velocity.simd
        )

        if let last = remoteSnapshots.last, snapshot.seq <= last.seq {
            return
        }

        remoteSnapshots.append(snapshot)
        if remoteSnapshots.count > 32 {
            remoteSnapshots.removeFirst(remoteSnapshots.count - 32)
        }
    }

    func interpolatedRemotePosition(
        at renderTimestamp: TimeInterval,
        interpolationDelay: TimeInterval = 0.1
    ) -> SIMD2<Float>? {
        guard !remoteSnapshots.isEmpty else { return nil }

        let target = renderTimestamp - interpolationDelay

        if remoteSnapshots.count == 1 {
            let only = remoteSnapshots[0]
            let dt = Float(max(0, target - only.ts))
            return only.position + only.velocity * dt
        }

        var previous = remoteSnapshots[0]
        for current in remoteSnapshots.dropFirst() {
            if current.ts >= target {
                let span = max(0.0001, current.ts - previous.ts)
                let alpha = Float((target - previous.ts) / span)
                return simd_mix(previous.position, current.position, SIMD2<Float>(repeating: max(0, min(1, alpha))))
            }
            previous = current
        }

        let latest = remoteSnapshots[remoteSnapshots.count - 1]
        let dt = Float(max(0, target - latest.ts))
        return latest.position + latest.velocity * min(dt, 0.25)
    }

    func clampLocalPosition(to halfSize: SIMD2<Float>) {
        localPosition.x = max(-halfSize.x, min(halfSize.x, localPosition.x))
        localPosition.y = max(-halfSize.y, min(halfSize.y, localPosition.y))
    }
}
