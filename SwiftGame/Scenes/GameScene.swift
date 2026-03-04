import SpriteKit
import MultipeerConnectivity
import simd
import QuartzCore

final class GameScene: SKScene {
    var inputVector: SIMD2<Float> = .zero

    private let transport: SessionTransport
    private let localPlayerId: UUID

    private let gameState = GameState(localPosition: SIMD2<Float>(-110, 0))

    private let localNode = SKSpriteNode(color: .systemGreen, size: CGSize(width: 34, height: 34))
    private let remoteNode = SKSpriteNode(color: .systemBlue, size: CGSize(width: 34, height: 34))

    private let statusLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let metricsLabel = SKLabelNode(fontNamed: "Menlo")
    private let disconnectLabel = SKLabelNode(fontNamed: "Menlo-Bold")

    private let moveSpeed: Float = 150
    private var lastUpdateTime: TimeInterval = 0
    private var sequence: UInt32 = 0

    private var sendAccumulator: TimeInterval = 0
    private let sendInterval: TimeInterval = 0.05

    private var pingAccumulator: TimeInterval = 0
    private var pendingPingTimestamp: TimeInterval?
    private var latestRTTMs: Int = 0

    private var packetsThisSecond = 0
    private var packetsPerSecond = 0
    private var packetCounterTime: TimeInterval = 0

    private var remotePlayerId: UUID?
    private var remoteConnected = false

    init(size: CGSize, transport: SessionTransport, localPlayerId: UUID) {
        self.transport = transport
        self.localPlayerId = localPlayerId
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.43, green: 0.58, blue: 0.4, alpha: 1)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupWorld()
        setupHUD()
        wireTransport()

        transport.send(.hello(playerId: localPlayerId))
    }

    private func setupWorld() {
        let tileSize: CGFloat = 42
        for x in stride(from: -size.width / 2, through: size.width / 2, by: tileSize) {
            let vertical = SKShapeNode(rectOf: CGSize(width: 1, height: size.height + 100))
            vertical.strokeColor = UIColor(white: 0, alpha: 0.1)
            vertical.position = CGPoint(x: x, y: 0)
            addChild(vertical)
        }

        for y in stride(from: -size.height / 2, through: size.height / 2, by: tileSize) {
            let horizontal = SKShapeNode(rectOf: CGSize(width: size.width + 100, height: 1))
            horizontal.strokeColor = UIColor(white: 0, alpha: 0.1)
            horizontal.position = CGPoint(x: 0, y: y)
            addChild(horizontal)
        }

        localNode.zPosition = 2
        remoteNode.zPosition = 2

        localNode.position = CGPoint(x: CGFloat(gameState.localPosition.x), y: CGFloat(gameState.localPosition.y))
        remoteNode.position = CGPoint(x: 110, y: 0)

        addChild(localNode)
        addChild(remoteNode)
    }

    private func setupHUD() {
        statusLabel.fontSize = 14
        statusLabel.horizontalAlignmentMode = .left
        statusLabel.verticalAlignmentMode = .top
        statusLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 18)
        statusLabel.zPosition = 3
        statusLabel.text = "Connected"
        addChild(statusLabel)

        metricsLabel.fontSize = 12
        metricsLabel.horizontalAlignmentMode = .left
        metricsLabel.verticalAlignmentMode = .top
        metricsLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 40)
        metricsLabel.zPosition = 3
        metricsLabel.text = "RTT: -- ms | PPS: 0"
        addChild(metricsLabel)

        disconnectLabel.fontSize = 18
        disconnectLabel.horizontalAlignmentMode = .center
        disconnectLabel.verticalAlignmentMode = .center
        disconnectLabel.position = CGPoint(x: 0, y: size.height / 2 - 44)
        disconnectLabel.zPosition = 4
        disconnectLabel.text = ""
        addChild(disconnectLabel)
    }

    private func wireTransport() {
        transport.onMessage = { [weak self] message, _ in
            self?.handle(message: message)
        }

        transport.onPeerDisconnected = { [weak self] _ in
            self?.remoteConnected = false
            self?.disconnectLabel.text = "Peer disconnected"
            self?.statusLabel.text = "Disconnected"
        }

        transport.onPeerConnected = { [weak self] _ in
            guard let self else { return }
            self.remoteConnected = true
            self.disconnectLabel.text = ""
            self.statusLabel.text = "Connected"
            self.transport.send(.hello(playerId: self.localPlayerId))
        }
    }

    override func willMove(from view: SKView) {
        transport.onMessage = nil
        transport.onPeerConnected = nil
        transport.onPeerDisconnected = nil
    }

    override func didChangeSize(_ oldSize: CGSize) {
        statusLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 18)
        metricsLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 40)
        disconnectLabel.position = CGPoint(x: 0, y: size.height / 2 - 44)
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let dt = min(1.0 / 20.0, currentTime - lastUpdateTime)
        lastUpdateTime = currentTime

        stepLocalPlayer(dt: dt)
        stepRemotePlayer(currentTime: currentTime)
        stepNetworking(dt: dt, currentTime: currentTime)
        stepMetrics(dt: dt)
    }

    private func stepLocalPlayer(dt: TimeInterval) {
        let direction = simd_length(inputVector) > 1 ? simd_normalize(inputVector) : inputVector
        gameState.localVelocity = direction * moveSpeed
        gameState.localPosition += gameState.localVelocity * Float(dt)
        gameState.clampLocalPosition(to: SIMD2<Float>(Float(size.width * 0.5 - 20), Float(size.height * 0.5 - 20)))

        localNode.position = CGPoint(x: CGFloat(gameState.localPosition.x), y: CGFloat(gameState.localPosition.y))
    }

    private func stepRemotePlayer(currentTime: TimeInterval) {
        guard let interpolated = gameState.interpolatedRemotePosition(at: currentTime) else { return }
        remoteNode.position = CGPoint(x: CGFloat(interpolated.x), y: CGFloat(interpolated.y))
    }

    private func stepNetworking(dt: TimeInterval, currentTime: TimeInterval) {
        sendAccumulator += dt
        pingAccumulator += dt

        if sendAccumulator >= sendInterval {
            sendAccumulator = 0
            sequence &+= 1

            let packet = PlayerStatePacket(
                playerId: localPlayerId,
                seq: sequence,
                ts: currentTime,
                position: Vector2(gameState.localPosition),
                velocity: Vector2(gameState.localVelocity)
            )
            transport.send(.playerState(packet))
        }

        if pingAccumulator >= 1.0 {
            pingAccumulator = 0
            let now = CACurrentMediaTime()
            pendingPingTimestamp = now
            transport.send(.ping(ts: now))
        }
    }

    private func stepMetrics(dt: TimeInterval) {
        packetCounterTime += dt
        if packetCounterTime >= 1 {
            packetCounterTime = 0
            packetsPerSecond = packetsThisSecond
            packetsThisSecond = 0
        }

        metricsLabel.text = "RTT: \(latestRTTMs) ms | PPS: \(packetsPerSecond)"
    }

    private func handle(message: NetMessage) {
        packetsThisSecond += 1

        switch message {
        case .hello(let playerId):
            if playerId != localPlayerId {
                remotePlayerId = playerId
                remoteConnected = true
                disconnectLabel.text = ""
                statusLabel.text = "Connected"
            }
        case .playerState(let packet):
            guard packet.playerId != localPlayerId else { return }
            if remotePlayerId == nil {
                remotePlayerId = packet.playerId
            }
            gameState.applyRemoteSnapshot(packet)
        case .ping(let timestamp):
            transport.send(.pong(ts: timestamp))
        case .pong(let timestamp):
            guard let pending = pendingPingTimestamp, abs(pending - timestamp) < 0.001 else { return }
            latestRTTMs = Int((CACurrentMediaTime() - timestamp) * 1000)
            pendingPingTimestamp = nil
        }
    }
}
