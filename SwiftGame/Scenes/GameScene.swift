import SpriteKit
import simd
import QuartzCore

final class GameScene: SKScene {
    var inputVector: SIMD2<Float> = .zero
    var actionPressed = false
    var onLevelCompleted: (() -> Void)?

    private let transport: SessionTransport
    private let localPlayerId: UUID
    private let localRole: PlayerRole
    private let level: DailyLevelV1

    private let gameState = GameState(localPosition: SIMD2<Float>(-80, -60))

    private let localNode = SKSpriteNode(
        color: UIColor(red: 0.72, green: 0.85, blue: 0.67, alpha: 1),
        size: CGSize(width: 28, height: 40)
    )
    private let remoteNode = SKSpriteNode(
        color: UIColor(red: 0.52, green: 0.67, blue: 0.84, alpha: 1),
        size: CGSize(width: 28, height: 40)
    )

    private let statusLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let objectiveLabel = SKLabelNode(fontNamed: "Menlo")
    private let metricsLabel = SKLabelNode(fontNamed: "Menlo")

    private let moveSpeed: Float = 170
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

    init(size: CGSize, transport: SessionTransport, localPlayerId: UUID, localRole: PlayerRole, level: DailyLevelV1) {
        self.transport = transport
        self.localPlayerId = localPlayerId
        self.localRole = localRole
        self.level = level
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.46, green: 0.58, blue: 0.48, alpha: 1)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupArena()
        setupHUD()
        setupSpawns()
        wireTransport()

        transport.send(.hello(playerId: localPlayerId))
    }

    private func setupArena() {
        let sky = SKSpriteNode(
            color: UIColor(red: 0.58, green: 0.71, blue: 0.56, alpha: 1),
            size: CGSize(width: size.width + 80, height: size.height + 100)
        )
        sky.zPosition = -4
        addChild(sky)

        let ground = SKSpriteNode(
            color: UIColor(red: 0.35, green: 0.46, blue: 0.30, alpha: 1),
            size: CGSize(width: size.width + 100, height: size.height * 0.55)
        )
        ground.position = CGPoint(x: 0, y: -size.height * 0.18)
        ground.zPosition = -3
        addChild(ground)

        let centerPatch = SKShapeNode(rectOf: CGSize(width: 120, height: 120), cornerRadius: 10)
        centerPatch.fillColor = UIColor(red: 0.42, green: 0.53, blue: 0.37, alpha: 0.9)
        centerPatch.strokeColor = .clear
        centerPatch.zPosition = -2
        addChild(centerPatch)

        [localNode, remoteNode].forEach {
            $0.zPosition = 2
            addChild($0)
        }
    }

    private func setupSpawns() {
        let localSpawn = localRole == .anchor ? SIMD2<Float>(-90, -80) : SIMD2<Float>(90, -80)
        let remoteSpawn = localRole == .anchor ? SIMD2<Float>(90, -80) : SIMD2<Float>(-90, -80)

        gameState.localPosition = localSpawn
        localNode.position = CGPoint(x: CGFloat(gameState.localPosition.x), y: CGFloat(gameState.localPosition.y))
        remoteNode.position = CGPoint(x: CGFloat(remoteSpawn.x), y: CGFloat(remoteSpawn.y))
    }

    private func setupHUD() {
        statusLabel.fontSize = 13
        statusLabel.horizontalAlignmentMode = .left
        statusLabel.verticalAlignmentMode = .top
        statusLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 18)
        statusLabel.text = "Role: \(localRole.rawValue.capitalized)"
        statusLabel.zPosition = 4

        objectiveLabel.fontSize = 11
        objectiveLabel.horizontalAlignmentMode = .left
        objectiveLabel.verticalAlignmentMode = .top
        objectiveLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 38)
        objectiveLabel.text = "Move around together. Movement sync test."
        objectiveLabel.zPosition = 4

        metricsLabel.fontSize = 11
        metricsLabel.horizontalAlignmentMode = .left
        metricsLabel.verticalAlignmentMode = .top
        metricsLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 56)
        metricsLabel.text = "RTT: 0 | PPS: 0"
        metricsLabel.zPosition = 4

        addChild(statusLabel)
        addChild(objectiveLabel)
        addChild(metricsLabel)
    }

    private func wireTransport() {
        transport.onMessage = { [weak self] message, _ in
            self?.handle(message: message)
        }

        transport.onPeerConnected = { [weak self] _ in
            self?.statusLabel.text = "Connected | \(self?.localRole.rawValue.capitalized ?? "Role")"
        }

        transport.onPeerDisconnected = { [weak self] _ in
            self?.statusLabel.text = "Partner disconnected"
        }
    }

    override func willMove(from view: SKView) {
        transport.onMessage = nil
        transport.onPeerConnected = nil
        transport.onPeerDisconnected = nil
    }

    override func didChangeSize(_ oldSize: CGSize) {
        statusLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 18)
        objectiveLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 38)
        metricsLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 56)
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
        let nextVelocity = direction * moveSpeed

        gameState.localVelocity = nextVelocity
        gameState.localPosition += gameState.localVelocity * Float(dt)
        gameState.clampLocalPosition(
            to: SIMD2<Float>(
                Float(size.width * 0.5 - 24),
                Float(size.height * 0.5 - 70)
            )
        )
        localNode.position = CGPoint(x: CGFloat(gameState.localPosition.x), y: CGFloat(gameState.localPosition.y))
    }

    private func stepRemotePlayer(currentTime: TimeInterval) {
        guard let pos = gameState.interpolatedRemotePosition(at: currentTime) else { return }
        remoteNode.position = CGPoint(x: CGFloat(pos.x), y: CGFloat(pos.y))
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
            }
        case .playerState(let packet):
            guard packet.playerId != localPlayerId else { return }
            if remotePlayerId == nil {
                remotePlayerId = packet.playerId
            }
            gameState.applyRemoteSnapshot(packet)
        case .gameEvent:
            break
        case .ping(let ts):
            transport.send(.pong(ts: ts))
        case .pong(let ts):
            guard let pending = pendingPingTimestamp, abs(pending - ts) < 0.001 else { return }
            latestRTTMs = Int((CACurrentMediaTime() - ts) * 1000)
            pendingPingTimestamp = nil
        }
    }
}
