import Foundation

struct DuoProfileV1: Codable {
    let duoId: String
    let duoCode: String
    let duoName: String
    let memberA: String
    let memberB: String?
    let currentStreak: Int
    let graceTokens: Int
    let milestonesUnlocked: [Int]
}

enum RoomEnterState: String, Codable {
    case created
    case joined
    case rejoined
}

struct DailyLevelV1: Codable {
    struct Entity: Codable {
        let kind: String
        let x: Double
        let y: Double
        let width: Double?
        let height: Double?
    }

    let levelId: String
    let dateUTC: String
    let theme: String
    let version: Int
    let objective: String
    let entities: [Entity]
    let spawnAnchor: [Double]
    let spawnDash: [Double]
    let winZoneX: Double
    let gateX: Double
    let switchX: Double
    let dashPlateX: Double
}

struct SanctuaryStateV1: Codable {
    let sanctuaryLevel: Int
    let placedDecor: [String]
    let ambientFlags: [String: Bool]
}

struct CompletionEventV1: Codable {
    let roomCode: String
    let playerId: String
    let dateUTC: String
    let completedAt: String
    let levelId: String
    let version: Int
}

struct PostcardPayloadV1: Codable {
    let duoName: String
    let dateUTC: String
    let stamp: String
    let bgTheme: String
    let sanctuaryPreviewSeed: Int
}

struct RoomEnterResponse: Codable {
    let roomCode: String
    let role: PlayerRole
    let state: RoomEnterState
    let duoId: String?
    let partnerConnected: Bool
}

struct CompletionResponse: Codable {
    let ok: Bool
    let idempotent: Bool
    let duoId: String?
    let status: String
    let profile: DuoProfileV1?
}

struct DailyLevelResponse: Codable {
    let level: DailyLevelV1
    let fallbackUsed: Bool
}
