import Foundation

struct PeerSummary: Equatable {
    let id: String
    let displayName: String
}

protocol SessionTransport: AnyObject {
    var connectedPeerCount: Int { get }
    var roomCode: String? { get }
    var localRole: PlayerRole? { get }

    var onPeerConnected: ((PeerSummary) -> Void)? { get set }
    var onPeerDisconnected: ((PeerSummary) -> Void)? { get set }
    var onMessage: ((NetMessage, PeerSummary) -> Void)? { get set }
    var onStatusText: ((String) -> Void)? { get set }
    var onRoomReady: ((String) -> Void)? { get set }
    var onRoleAssigned: ((PlayerRole) -> Void)? { get set }

    func connectSocket(serverURL: URL, roomCode: String, playerId: UUID)
    func stop()
    func send(_ message: NetMessage)
}

final class WebSocketSessionManager: SessionTransport {
    private(set) var roomCode: String?
    private(set) var localRole: PlayerRole?

    var connectedPeerCount: Int {
        peer == nil ? 0 : 1
    }

    var onPeerConnected: ((PeerSummary) -> Void)?
    var onPeerDisconnected: ((PeerSummary) -> Void)?
    var onMessage: ((NetMessage, PeerSummary) -> Void)?
    var onStatusText: ((String) -> Void)?
    var onRoomReady: ((String) -> Void)?
    var onRoleAssigned: ((PlayerRole) -> Void)?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var task: URLSessionWebSocketTask?
    private var playerId: UUID?
    private var peer: PeerSummary?

    func connectSocket(serverURL: URL, roomCode: String, playerId: UUID) {
        stop()

        guard var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false) else {
            onStatusText?("Invalid server URL")
            return
        }

        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.path = "/ws"
        components.queryItems = [
            URLQueryItem(name: "roomCode", value: roomCode),
            URLQueryItem(name: "playerId", value: playerId.uuidString)
        ]

        guard let url = components.url else {
            onStatusText?("Invalid websocket URL")
            return
        }

        self.roomCode = roomCode
        self.playerId = playerId

        let task = URLSession.shared.webSocketTask(with: url)
        self.task = task
        task.resume()

        onStatusText?("Connecting to room \(roomCode)...")
        onRoomReady?(roomCode)
        receiveLoop()
    }

    func stop() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil

        if let peer {
            onPeerDisconnected?(peer)
        }

        roomCode = nil
        peer = nil
        localRole = nil
        playerId = nil
    }

    func send(_ message: NetMessage) {
        guard let task else { return }

        let envelope = RoomEnvelope(
            type: "relay",
            senderId: playerId,
            role: nil,
            roomCode: roomCode,
            message: message
        )

        do {
            let data = try encoder.encode(envelope)
            task.send(.data(data)) { [weak self] error in
                if let error {
                    DispatchQueue.main.async {
                        self?.onStatusText?("Send failed: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            onStatusText?("Encode failed: \(error.localizedDescription)")
        }
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.onStatusText?("Socket disconnected: \(error.localizedDescription)")
                    if let peer = self.peer {
                        self.onPeerDisconnected?(peer)
                    }
                }
            case .success(let message):
                self.handle(message)
                self.receiveLoop()
            }
        }
    }

    private func handle(_ wsMessage: URLSessionWebSocketTask.Message) {
        let data: Data
        switch wsMessage {
        case .data(let incoming):
            data = incoming
        case .string(let string):
            data = Data(string.utf8)
        @unknown default:
            return
        }

        do {
            let envelope = try decoder.decode(RoomEnvelope.self, from: data)
            DispatchQueue.main.async {
                self.process(envelope)
            }
        } catch {
            DispatchQueue.main.async {
                self.onStatusText?("Decode failed: \(error.localizedDescription)")
            }
        }
    }

    private func process(_ envelope: RoomEnvelope) {
        switch envelope.type {
        case "peer_joined":
            guard let sender = envelope.senderId else { return }
            let remote = PeerSummary(id: sender.uuidString, displayName: "Partner")
            peer = remote
            onPeerConnected?(remote)
            onStatusText?("Partner connected")
        case "peer_left":
            guard let peer else { return }
            onPeerDisconnected?(peer)
            self.peer = nil
            onStatusText?("Partner disconnected")
        case "role_assigned":
            guard let role = envelope.role else { return }
            localRole = role
            onRoleAssigned?(role)
            onStatusText?("Role: \(role.rawValue.capitalized)")
        case "relay":
            guard
                let senderId = envelope.senderId,
                senderId != playerId,
                let message = envelope.message
            else { return }

            let remote = PeerSummary(id: senderId.uuidString, displayName: "Partner")
            onMessage?(message, remote)
        default:
            break
        }
    }
}
