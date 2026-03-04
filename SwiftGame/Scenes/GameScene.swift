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

    private let gameState = GameState(localPosition: SIMD2<Float>(-220, -110))

    private let localNode = SKSpriteNode(color: UIColor(red: 0.72, green: 0.85, blue: 0.67, alpha: 1), size: CGSize(width: 28, height: 40))
    private let remoteNode = SKSpriteNode(color: UIColor(red: 0.52, green: 0.67, blue: 0.84, alpha: 1), size: CGSize(width: 28, height: 40))

    private let switchNode = SKSpriteNode(color: .brown, size: CGSize(width: 24, height: 16))
    private let gateNode = SKSpriteNode(color: .darkGray, size: CGSize(width: 20, height: 100))
    private let dashPlateNode = SKSpriteNode(color: .orange, size: CGSize(width: 28, height: 8))
    private let winZoneNode = SKSpriteNode(color: .systemGreen, size: CGSize(width: 40, height: 80))

    private let statusLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let objectiveLabel = SKLabelNode(fontNamed: "Menlo")
    private let metricsLabel = SKLabelNode(fontNamed: "Menlo")

    private let moveSpeed: Float = 130
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

    private var remoteConnected = false
    private var remotePlayerId: UUID?

    private var localSwitchActive = false
    private var remoteSwitchActive = false
    private var localDashPlateActive = false
    private var remoteDashPlateActive = false

    private var levelCompleted = false

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
        backgroundColor = UIColor(red: 0.45, green: 0.58, blue: 0.45, alpha: 1)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupWorld()
        setupHUD()
        setupSpawn()
        wireTransport()

        transport.send(.hello(playerId: localPlayerId))
    }

    private func setupWorld() {
        let sky = SKSpriteNode(color: UIColor(red: 0.58, green: 0.71, blue: 0.56, alpha: 1), size: CGSize(width: size.width + 80, height: size.height + 100))
        sky.zPosition = -4
        addChild(sky)

        let ground = SKSpriteNode(color: UIColor(red: 0.32, green: 0.4, blue: 0.26, alpha: 1), size: CGSize(width: size.width + 100, height: 110))
        ground.position = CGPoint(x: 0, y: -size.height / 2 + 55)
        ground.zPosition = -3
        addChild(ground)

        switchNode.position = CGPoint(x: level.switchX, y: -148)
        gateNode.position = CGPoint(x: level.gateX, y: -110)
        dashPlateNode.position = CGPoint(x: level.dashPlateX, y: -152)
        winZoneNode.position = CGPoint(x: level.winZoneX, y: -120)

        [switchNode, gateNode, dashPlateNode, winZoneNode, localNode, remoteNode].forEach {
            $0.zPosition = 2
            addChild($0)
        }
    }

    private func setupSpawn() {
        let localSpawn: [Double]
        let remoteSpawn: [Double]

        if localRole == .anchor {
            localSpawn = level.spawnAnchor
            remoteSpawn = level.spawnDash
        } else {
            localSpawn = level.spawnDash
            remoteSpawn = level.spawnAnchor
        }

        gameState.localPosition = SIMD2<Float>(Float(localSpawn[0]), Float(localSpawn[1]))
        localNode.position = CGPoint(x: CGFloat(gameState.localPosition.x), y: CGFloat(gameState.localPosition.y))
        remoteNode.position = CGPoint(x: remoteSpawn[0], y: remoteSpawn[1])
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
        objectiveLabel.text = level.objective
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
            self?.remoteConnected = true
            self?.statusLabel.text = "Connected | \(self?.localRole.rawValue.capitalized ?? "Role")"
        }

        transport.onPeerDisconnected = { [weak self] _ in
            self?.remoteConnected = false
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
        processRoleActions(currentTime: currentTime)
        stepRemotePlayer(currentTime: currentTime)
        updatePuzzleState()
        stepNetworking(dt: dt, currentTime: currentTime)
        stepMetrics(dt: dt)
        checkLevelCompletion()
    }

    private func stepLocalPlayer(dt: TimeInterval) {
        let xOnly = SIMD2<Float>(inputVector.x, 0)
        let direction = simd_length(xOnly) > 1 ? simd_normalize(xOnly) : xOnly

        var nextVelocity = direction * moveSpeed
        if localRole == .dash, actionPressed {
            nextVelocity.x *= 1.9
        }

        gameState.localVelocity = nextVelocity
        gameState.localPosition += gameState.localVelocity * Float(dt)

        let minY: Float = -152
        gameState.localPosition.y = minY

        if !gateIsOpen() {
            let localX = gameState.localPosition.x
            if localX > Float(level.gateX - 10), localX < Float(level.gateX + 12) {
                gameState.localPosition.x = localRole == .anchor ? Float(level.gateX - 18) : Float(level.gateX + 18)
            }
        }

        gameState.clampLocalPosition(to: SIMD2<Float>(Float(size.width * 0.5 - 30), Float(size.height * 0.5 - 30)))
        localNode.position = CGPoint(x: CGFloat(gameState.localPosition.x), y: CGFloat(gameState.localPosition.y))
    }

    private func processRoleActions(currentTime: TimeInterval) {
        if localRole == .anchor {
            let nearSwitch = abs(localNode.position.x - CGFloat(level.switchX)) < 30
            let newState = actionPressed && nearSwitch
            if newState != localSwitchActive {
                localSwitchActive = newState
                transport.send(.gameEvent(GameEventPacket(type: "anchor_switch", actorId: localPlayerId, value: newState, ts: currentTime)))
            }
        } else {
            let onPlate = abs(localNode.position.x - CGFloat(level.dashPlateX)) < 20
            if onPlate != localDashPlateActive {
                localDashPlateActive = onPlate
                transport.send(.gameEvent(GameEventPacket(type: "dash_plate", actorId: localPlayerId, value: onPlate, ts: currentTime)))
            }
        }
    }

    private func stepRemotePlayer(currentTime: TimeInterval) {
        guard let pos = gameState.interpolatedRemotePosition(at: currentTime) else { return }
        remoteNode.position = CGPoint(x: CGFloat(pos.x), y: CGFloat(pos.y))
    }

    private func updatePuzzleState() {
        switchNode.color = (localSwitchActive || remoteSwitchActive) ? .systemYellow : .brown
        dashPlateNode.color = (localDashPlateActive || remoteDashPlateActive) ? .systemTeal : .orange
        gateNode.isHidden = gateIsOpen()
        winZoneNode.color = isExitUnlocked() ? .systemMint : .systemGreen
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

    private func checkLevelCompletion() {
        guard !levelCompleted, isExitUnlocked() else { return }

        let localAtExit = localNode.position.x >= CGFloat(level.winZoneX)
        let remoteAtExit = remoteNode.position.x >= CGFloat(level.winZoneX)

        if localAtExit && remoteAtExit {
            levelCompleted = true
            statusLabel.text = "Level complete!"
            onLevelCompleted?()
        }
    }

    private func gateIsOpen() -> Bool {
        localSwitchActive || remoteSwitchActive
    }

    private func isExitUnlocked() -> Bool {
        localDashPlateActive || remoteDashPlateActive
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
        case .gameEvent(let event):
            guard event.actorId != localPlayerId else { return }
            if event.type == "anchor_switch" {
                remoteSwitchActive = event.value
            } else if event.type == "dash_plate" {
                remoteDashPlateActive = event.value
            }
        case .ping(let ts):
            transport.send(.pong(ts: ts))
        case .pong(let ts):
            guard let pending = pendingPingTimestamp, abs(pending - ts) < 0.001 else { return }
            latestRTTMs = Int((CACurrentMediaTime() - ts) * 1000)
            pendingPingTimestamp = nil
        }
    }
}
