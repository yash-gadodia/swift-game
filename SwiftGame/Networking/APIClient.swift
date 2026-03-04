import Foundation

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func enterRoom(roomCode: String, playerId: UUID, playerName: String) async throws -> RoomEnterResponse {
        try await request(
            path: "/rooms/enter",
            method: "POST",
            body: ["roomCode": roomCode, "playerId": playerId.uuidString, "playerName": playerName],
            responseType: RoomEnterResponse.self
        )
    }

    func fetchDuoState(duoId: String) async throws -> DuoProfileV1 {
        try await request(path: "/duo/state?duoId=\(duoId)", method: "GET", responseType: DuoProfileV1.self)
    }

    func recordCompletion(roomCode: String, playerId: UUID, levelId: String) async throws -> CompletionResponse {
        let now = ISO8601DateFormatter().string(from: Date())
        return try await request(
            path: "/daily-completion",
            method: "POST",
            body: [
                "roomCode": roomCode,
                "playerId": playerId.uuidString,
                "levelId": levelId,
                "completedAt": now
            ],
            responseType: CompletionResponse.self
        )
    }

    func fetchPostcardPayload(duoId: String) async throws -> PostcardPayloadV1 {
        try await request(path: "/postcard-payload?duoId=\(duoId)", method: "GET", responseType: PostcardPayloadV1.self)
    }

    func createDuo(duoName: String, playerName: String) async throws -> DuoProfileV1 {
        try await request(
            path: "/duo/create",
            method: "POST",
            body: ["duoName": duoName, "playerName": playerName],
            responseType: DuoProfileV1.self
        )
    }

    func joinDuo(duoCode: String, playerName: String) async throws -> DuoProfileV1 {
        try await request(
            path: "/duo/join",
            method: "POST",
            body: ["duoCode": duoCode, "playerName": playerName],
            responseType: DuoProfileV1.self
        )
    }

    func fetchDailyLevel(for dateUTC: String) async throws -> DailyLevelResponse {
        try await request(path: "/daily-level?date=\(dateUTC)", method: "GET", responseType: DailyLevelResponse.self)
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        body: [String: Any]? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "request_failed"
            throw NSError(domain: "api", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }

        return try decoder.decode(T.self, from: data)
    }
}
