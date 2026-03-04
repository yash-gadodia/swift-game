import Foundation
import simd

struct Vector2: Codable, Equatable {
    let x: Float
    let y: Float

    init(_ vector: SIMD2<Float>) {
        self.x = vector.x
        self.y = vector.y
    }

    var simd: SIMD2<Float> {
        SIMD2<Float>(x, y)
    }
}

struct PlayerStatePacket: Codable, Equatable {
    let playerId: UUID
    let seq: UInt32
    let ts: TimeInterval
    let position: Vector2
    let velocity: Vector2
}

enum NetMessage: Codable, Equatable {
    case hello(playerId: UUID)
    case playerState(PlayerStatePacket)
    case ping(ts: TimeInterval)
    case pong(ts: TimeInterval)

    private enum CodingKeys: String, CodingKey {
        case type
        case hello
        case playerState
        case ping
        case pong
    }

    private enum MessageType: String, Codable {
        case hello
        case playerState
        case ping
        case pong
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .hello:
            let playerId = try container.decode(UUID.self, forKey: .hello)
            self = .hello(playerId: playerId)
        case .playerState:
            let packet = try container.decode(PlayerStatePacket.self, forKey: .playerState)
            self = .playerState(packet)
        case .ping:
            let timestamp = try container.decode(TimeInterval.self, forKey: .ping)
            self = .ping(ts: timestamp)
        case .pong:
            let timestamp = try container.decode(TimeInterval.self, forKey: .pong)
            self = .pong(ts: timestamp)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .hello(let playerId):
            try container.encode(MessageType.hello, forKey: .type)
            try container.encode(playerId, forKey: .hello)
        case .playerState(let packet):
            try container.encode(MessageType.playerState, forKey: .type)
            try container.encode(packet, forKey: .playerState)
        case .ping(let timestamp):
            try container.encode(MessageType.ping, forKey: .type)
            try container.encode(timestamp, forKey: .ping)
        case .pong(let timestamp):
            try container.encode(MessageType.pong, forKey: .type)
            try container.encode(timestamp, forKey: .pong)
        }
    }
}
