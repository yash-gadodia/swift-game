import Foundation
import simd

enum PlayerRole: String, Codable {
    case anchor
    case dash
}

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

struct GameEventPacket: Codable, Equatable {
    let type: String
    let actorId: UUID
    let value: Bool
    let ts: TimeInterval
}

enum NetMessage: Codable, Equatable {
    case hello(playerId: UUID)
    case playerState(PlayerStatePacket)
    case gameEvent(GameEventPacket)
    case ping(ts: TimeInterval)
    case pong(ts: TimeInterval)

    private enum CodingKeys: String, CodingKey {
        case type
        case hello
        case playerState
        case gameEvent
        case ping
        case pong
    }

    private enum MessageType: String, Codable {
        case hello
        case playerState
        case gameEvent
        case ping
        case pong
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .hello:
            self = .hello(playerId: try container.decode(UUID.self, forKey: .hello))
        case .playerState:
            self = .playerState(try container.decode(PlayerStatePacket.self, forKey: .playerState))
        case .gameEvent:
            self = .gameEvent(try container.decode(GameEventPacket.self, forKey: .gameEvent))
        case .ping:
            self = .ping(ts: try container.decode(TimeInterval.self, forKey: .ping))
        case .pong:
            self = .pong(ts: try container.decode(TimeInterval.self, forKey: .pong))
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
        case .gameEvent(let packet):
            try container.encode(MessageType.gameEvent, forKey: .type)
            try container.encode(packet, forKey: .gameEvent)
        case .ping(let ts):
            try container.encode(MessageType.ping, forKey: .type)
            try container.encode(ts, forKey: .ping)
        case .pong(let ts):
            try container.encode(MessageType.pong, forKey: .type)
            try container.encode(ts, forKey: .pong)
        }
    }
}

struct RoomEnvelope: Codable {
    let type: String
    let senderId: UUID?
    let role: PlayerRole?
    let roomCode: String?
    let message: NetMessage?
}
