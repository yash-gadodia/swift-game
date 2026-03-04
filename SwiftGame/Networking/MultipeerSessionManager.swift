import Foundation

struct PeerSummary: Equatable {
    let id: String
    let displayName: String
}

struct PeerLifecycleTransition {
    let connected: PeerSummary?
    let disconnected: PeerSummary?

    static let noChange = PeerLifecycleTransition(connected: nil, disconnected: nil)
}

struct PeerLifecycleTracker {
    private(set) var currentPeer: PeerSummary?

    mutating func setPeer(_ peer: PeerSummary) -> PeerLifecycleTransition {
        if currentPeer == peer {
            return .noChange
        }

        let previous = currentPeer
        currentPeer = peer
        return PeerLifecycleTransition(connected: peer, disconnected: previous)
    }

    mutating func clearPeer(notify: Bool) -> PeerLifecycleTransition {
        guard let previous = currentPeer else { return .noChange }
        currentPeer = nil
        return PeerLifecycleTransition(connected: nil, disconnected: notify ? previous : nil)
    }
}

struct ReconnectBackoffPolicy: Equatable {
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let maxAttempts: Int

    init(baseDelay: TimeInterval = 0.5, maxDelay: TimeInterval = 5.0, maxAttempts: Int = 6) {
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.maxAttempts = maxAttempts
    }

    func canRetry(attempt: Int) -> Bool {
        attempt > 0 && attempt <= maxAttempts
    }

    func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        let exponential = baseDelay * pow(2.0, Double(attempt - 1))
        return min(maxDelay, exponential)
    }
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
        peerTracker.currentPeer == nil ? 0 : 1
    }

    var onPeerConnected: ((PeerSummary) -> Void)?
    var onPeerDisconnected: ((PeerSummary) -> Void)?
    var onMessage: ((NetMessage, PeerSummary) -> Void)?
    var onStatusText: ((String) -> Void)?
    var onRoomReady: ((String) -> Void)?
    var onRoleAssigned: ((PlayerRole) -> Void)?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let reconnectPolicy = ReconnectBackoffPolicy()

    private var task: URLSessionWebSocketTask?
    private var playerId: UUID?
    private var serverURL: URL?
    private var peerTracker = PeerLifecycleTracker()
    private var connectionGeneration: UInt64 = 0
    private var reconnectAttempt = 0
    private var reconnectWorkItem: DispatchWorkItem?
    private var shouldReconnect = false

    func connectSocket(serverURL: URL, roomCode: String, playerId: UUID) {
        stop(notifyPeerDisconnect: false)

        self.serverURL = serverURL
        self.roomCode = roomCode
        self.playerId = playerId
        reconnectAttempt = 0
        shouldReconnect = true

        openSocket(isReconnect: false)
    }

    func stop() {
        stop(notifyPeerDisconnect: true)
    }

    private func stop(notifyPeerDisconnect: Bool) {
        connectionGeneration &+= 1
        shouldReconnect = false
        reconnectAttempt = 0
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil

        task?.cancel(with: .goingAway, reason: nil)
        task = nil

        emit(peerTracker.clearPeer(notify: notifyPeerDisconnect))

        serverURL = nil
        roomCode = nil
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

    private func openSocket(isReconnect: Bool) {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil

        guard
            let serverURL,
            let roomCode,
            let playerId,
            var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)
        else {
            onStatusText?("Socket setup incomplete")
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

        connectionGeneration &+= 1
        let generation = connectionGeneration

        let task = URLSession.shared.webSocketTask(with: url)
        self.task = task
        task.resume()

        let prefix = isReconnect ? "Reconnecting" : "Connecting"
        onStatusText?("\(prefix) to room \(roomCode)...")
        onRoomReady?(roomCode)
        receiveLoop(generation: generation)
    }

    private func receiveLoop(generation: UInt64) {
        task?.receive { [weak self] result in
            guard let self else { return }
            guard generation == self.connectionGeneration else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    guard generation == self.connectionGeneration else { return }
                    self.task = nil
                    self.emit(self.peerTracker.clearPeer(notify: true))
                    if self.scheduleReconnectIfNeeded(lastError: error) {
                        return
                    }
                    self.onStatusText?("Socket disconnected: \(error.localizedDescription)")
                }
            case .success(let message):
                self.handle(message)
                self.receiveLoop(generation: generation)
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
        if reconnectAttempt > 0 {
            reconnectAttempt = 0
            reconnectWorkItem?.cancel()
            reconnectWorkItem = nil
            onStatusText?("Reconnected to room \(roomCode ?? "")")
        }

        switch envelope.type {
        case "peer_joined":
            guard let sender = envelope.senderId else { return }
            let remote = PeerSummary(id: sender.uuidString, displayName: "Partner")
            let transition = peerTracker.setPeer(remote)
            emit(transition)
            if transition.connected == nil {
                return
            }
            onStatusText?("Partner connected")
        case "peer_left":
            emit(peerTracker.clearPeer(notify: true))
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

    private func emit(_ transition: PeerLifecycleTransition) {
        if let disconnected = transition.disconnected {
            onPeerDisconnected?(disconnected)
        }
        if let connected = transition.connected {
            onPeerConnected?(connected)
        }
    }

    private func scheduleReconnectIfNeeded(lastError: Error) -> Bool {
        guard shouldReconnect else { return false }

        reconnectAttempt += 1
        guard reconnectPolicy.canRetry(attempt: reconnectAttempt) else {
            onStatusText?("Connection lost: \(lastError.localizedDescription)")
            return false
        }

        let delay = reconnectPolicy.delay(forAttempt: reconnectAttempt)
        onStatusText?("Connection lost. Retrying in \(formatDelay(delay))s (\(reconnectAttempt)/\(reconnectPolicy.maxAttempts))")

        let generation = connectionGeneration
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard generation == self.connectionGeneration else { return }
            self.openSocket(isReconnect: true)
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return true
    }

    private func formatDelay(_ delay: TimeInterval) -> String {
        if abs(delay.rounded() - delay) < 0.01 {
            return String(Int(delay.rounded()))
        }
        return String(format: "%.1f", delay)
    }
}
