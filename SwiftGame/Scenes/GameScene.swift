import SpriteKit
import simd
import QuartzCore

final class GameScene: SKScene {
    var inputVector: SIMD2<Float> = .zero
    var actionPressed = false
    var onLevelCompleted: (() -> Void)?
    var onPeerConnectionChanged: ((Bool) -> Void)?

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
    private let themeBadgeLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let localAuraNode = SKShapeNode(circleOfRadius: 18)
    private let remoteAuraNode = SKShapeNode(circleOfRadius: 18)
    private let vignetteNode = SKShapeNode()

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
    private var peerConnected = false
    private var localTrailAccumulator: TimeInterval = 0
    private var remoteTrailAccumulator: TimeInterval = 0
    private var previousRemoteRenderPosition: SIMD2<Float>?

    private struct ScenePalette {
        let sky: UIColor
        let ground: UIColor
        let patch: UIColor
        let local: UIColor
        let remote: UIColor
        let hud: UIColor
        let accent: UIColor
    }

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
        let palette = paletteForTheme(level.theme)
        backgroundColor = palette.sky
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        localNode.color = palette.local
        remoteNode.color = palette.remote

        setupArena(palette: palette)
        setupHUD(palette: palette)
        setupPlayerEffects(palette: palette)
        setupSpawns()
        wireTransport()

        transport.send(.hello(playerId: localPlayerId))
    }

    private func setupArena(palette: ScenePalette) {
        let sky = SKSpriteNode(
            color: palette.sky.withAlphaComponent(0.92),
            size: CGSize(width: size.width + 80, height: size.height + 100)
        )
        sky.zPosition = -4
        addChild(sky)

        let ground = SKSpriteNode(
            color: palette.ground,
            size: CGSize(width: size.width + 100, height: size.height * 0.55)
        )
        ground.position = CGPoint(x: 0, y: -size.height * 0.18)
        ground.zPosition = -3
        addChild(ground)

        let centerPatch = SKShapeNode(rectOf: CGSize(width: 120, height: 120), cornerRadius: 10)
        centerPatch.fillColor = palette.patch
        centerPatch.strokeColor = .clear
        centerPatch.zPosition = -2
        addChild(centerPatch)

        let upperHaze = SKShapeNode(rectOf: CGSize(width: size.width + 160, height: size.height * 0.55))
        upperHaze.position = CGPoint(x: 0, y: size.height * 0.22)
        upperHaze.fillColor = palette.sky.withAlphaComponent(0.14)
        upperHaze.strokeColor = .clear
        upperHaze.zPosition = -2.5
        addChild(upperHaze)

        [localNode, remoteNode].forEach {
            $0.zPosition = 2
            addChild($0)
        }

        vignetteNode.path = CGPath(rect: CGRect(x: -size.width * 0.5, y: -size.height * 0.5, width: size.width, height: size.height), transform: nil)
        vignetteNode.fillColor = UIColor.black.withAlphaComponent(0.08)
        vignetteNode.strokeColor = .clear
        vignetteNode.zPosition = 3
        addChild(vignetteNode)
    }

    private func setupSpawns() {
        let localSpawn = localRole == .anchor ? SIMD2<Float>(-90, -80) : SIMD2<Float>(90, -80)
        let remoteSpawn = localRole == .anchor ? SIMD2<Float>(90, -80) : SIMD2<Float>(-90, -80)

        gameState.localPosition = localSpawn
        localNode.position = CGPoint(x: CGFloat(gameState.localPosition.x), y: CGFloat(gameState.localPosition.y))
        remoteNode.position = CGPoint(x: CGFloat(remoteSpawn.x), y: CGFloat(remoteSpawn.y))
    }

    private func setupHUD(palette: ScenePalette) {
        statusLabel.fontSize = 13
        statusLabel.horizontalAlignmentMode = .left
        statusLabel.verticalAlignmentMode = .top
        statusLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 18)
        statusLabel.text = "Role: \(localRole.rawValue.capitalized)"
        statusLabel.fontColor = palette.hud
        statusLabel.zPosition = 4

        objectiveLabel.fontSize = 11
        objectiveLabel.horizontalAlignmentMode = .left
        objectiveLabel.verticalAlignmentMode = .top
        objectiveLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 38)
        objectiveLabel.fontColor = palette.hud.withAlphaComponent(0.9)
        objectiveLabel.text = level.objective
        objectiveLabel.zPosition = 4

        metricsLabel.fontSize = 11
        metricsLabel.horizontalAlignmentMode = .left
        metricsLabel.verticalAlignmentMode = .top
        metricsLabel.position = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 56)
        metricsLabel.text = "RTT: 0 | PPS: 0"
        metricsLabel.fontColor = palette.hud.withAlphaComponent(0.82)
        metricsLabel.zPosition = 4

        themeBadgeLabel.fontSize = 11
        themeBadgeLabel.horizontalAlignmentMode = .right
        themeBadgeLabel.verticalAlignmentMode = .top
        themeBadgeLabel.position = CGPoint(x: size.width / 2 - 12, y: size.height / 2 - 18)
        themeBadgeLabel.fontColor = palette.hud.withAlphaComponent(0.9)
        themeBadgeLabel.text = "Theme: \(level.theme)"
        themeBadgeLabel.zPosition = 4

        addChild(statusLabel)
        addChild(objectiveLabel)
        addChild(metricsLabel)
        addChild(themeBadgeLabel)
    }

    private func setupPlayerEffects(palette: ScenePalette) {
        configureAura(localAuraNode, color: palette.local.withAlphaComponent(0.35))
        configureAura(remoteAuraNode, color: palette.remote.withAlphaComponent(0.35))

        localNode.addChild(localAuraNode)
        remoteNode.addChild(remoteAuraNode)
    }

    private func configureAura(_ node: SKShapeNode, color: UIColor) {
        node.fillColor = color
        node.strokeColor = .clear
        node.position = CGPoint(x: 0, y: -18)
        node.zPosition = -1
    }

    private func wireTransport() {
        transport.onMessage = { [weak self] message, _ in
            self?.handle(message: message)
        }

        transport.onPeerConnected = { [weak self] _ in
            self?.setPeerConnection(connected: true)
        }

        transport.onPeerDisconnected = { [weak self] _ in
            self?.setPeerConnection(connected: false)
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
        themeBadgeLabel.position = CGPoint(x: size.width / 2 - 12, y: size.height / 2 - 18)
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
        stepVisualEffects(dt: dt)
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
        localTrailAccumulator += dt
        if simd_length(gameState.localVelocity) > 30, localTrailAccumulator >= 0.09 {
            localTrailAccumulator = 0
            spawnFootstep(at: localNode.position, color: localNode.color)
        }
    }

    private func stepRemotePlayer(currentTime: TimeInterval) {
        guard let pos = gameState.interpolatedRemotePosition(at: currentTime) else { return }
        remoteNode.position = CGPoint(x: CGFloat(pos.x), y: CGFloat(pos.y))
        let previous = previousRemoteRenderPosition ?? pos
        let velocityLike = simd_length(pos - previous)
        previousRemoteRenderPosition = pos

        remoteTrailAccumulator += sendInterval
        if velocityLike > 3, remoteTrailAccumulator >= 0.12 {
            remoteTrailAccumulator = 0
            spawnFootstep(at: remoteNode.position, color: remoteNode.color.withAlphaComponent(0.8))
        }
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
                setPeerConnection(connected: true)
            }
        case .playerState(let packet):
            guard packet.playerId != localPlayerId else { return }
            if remotePlayerId == nil {
                remotePlayerId = packet.playerId
            }
            if !peerConnected {
                setPeerConnection(connected: true)
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

    private func paletteForTheme(_ theme: String) -> ScenePalette {
        switch theme.lowercased() {
        case "forest":
            return ScenePalette(
                sky: UIColor(red: 0.35, green: 0.56, blue: 0.42, alpha: 1),
                ground: UIColor(red: 0.27, green: 0.38, blue: 0.25, alpha: 1),
                patch: UIColor(red: 0.37, green: 0.52, blue: 0.34, alpha: 0.92),
                local: UIColor(red: 0.76, green: 0.92, blue: 0.66, alpha: 1),
                remote: UIColor(red: 0.59, green: 0.79, blue: 0.96, alpha: 1),
                hud: UIColor(red: 0.94, green: 0.99, blue: 0.95, alpha: 1),
                accent: UIColor(red: 0.80, green: 0.94, blue: 0.74, alpha: 1)
            )
        case "ember":
            return ScenePalette(
                sky: UIColor(red: 0.44, green: 0.28, blue: 0.20, alpha: 1),
                ground: UIColor(red: 0.32, green: 0.19, blue: 0.15, alpha: 1),
                patch: UIColor(red: 0.48, green: 0.29, blue: 0.20, alpha: 0.95),
                local: UIColor(red: 0.98, green: 0.78, blue: 0.56, alpha: 1),
                remote: UIColor(red: 0.92, green: 0.61, blue: 0.45, alpha: 1),
                hud: UIColor(red: 1.0, green: 0.94, blue: 0.88, alpha: 1),
                accent: UIColor(red: 0.97, green: 0.70, blue: 0.50, alpha: 1)
            )
        case "twilight":
            return ScenePalette(
                sky: UIColor(red: 0.24, green: 0.28, blue: 0.46, alpha: 1),
                ground: UIColor(red: 0.18, green: 0.21, blue: 0.31, alpha: 1),
                patch: UIColor(red: 0.28, green: 0.33, blue: 0.51, alpha: 0.94),
                local: UIColor(red: 0.75, green: 0.83, blue: 1.0, alpha: 1),
                remote: UIColor(red: 0.88, green: 0.74, blue: 1.0, alpha: 1),
                hud: UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1),
                accent: UIColor(red: 0.80, green: 0.76, blue: 1.0, alpha: 1)
            )
        default:
            return ScenePalette(
                sky: UIColor(red: 0.46, green: 0.58, blue: 0.48, alpha: 1),
                ground: UIColor(red: 0.35, green: 0.46, blue: 0.30, alpha: 1),
                patch: UIColor(red: 0.42, green: 0.53, blue: 0.37, alpha: 0.9),
                local: UIColor(red: 0.72, green: 0.85, blue: 0.67, alpha: 1),
                remote: UIColor(red: 0.52, green: 0.67, blue: 0.84, alpha: 1),
                hud: UIColor(red: 0.93, green: 0.96, blue: 0.92, alpha: 1),
                accent: UIColor(red: 0.79, green: 0.88, blue: 0.74, alpha: 1)
            )
        }
    }

    private func stepVisualEffects(dt: TimeInterval) {
        let phase = CGFloat((lastUpdateTime * 2.3).truncatingRemainder(dividingBy: .pi * 2))
        let localScale = 0.92 + 0.12 * sin(phase)
        let remoteScale = 0.90 + 0.10 * cos(phase * 0.9)
        localAuraNode.setScale(localScale)
        remoteAuraNode.setScale(remoteScale)
        let moving = simd_length(gameState.localVelocity) > 40
        localAuraNode.alpha = moving ? 0.6 : 0.35
        let remoteMotion = previousRemoteRenderPosition.map { _ in true } ?? false
        remoteAuraNode.alpha = remoteMotion ? 0.5 : 0.32
        vignetteNode.alpha = peerConnected ? 0.9 : 1.0
        _ = dt
    }

    private func spawnFootstep(at position: CGPoint, color: UIColor) {
        let dot = SKShapeNode(circleOfRadius: 2.6)
        dot.fillColor = color.withAlphaComponent(0.75)
        dot.strokeColor = .clear
        dot.position = CGPoint(x: position.x, y: position.y - 18)
        dot.zPosition = 1
        addChild(dot)

        let rise = SKAction.moveBy(x: 0, y: 7, duration: 0.2)
        rise.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let shrink = SKAction.scale(to: 0.6, duration: 0.2)
        let group = SKAction.group([rise, fade, shrink])
        dot.run(.sequence([group, .removeFromParent()]))
    }

    private func setPeerConnection(connected: Bool) {
        guard peerConnected != connected else { return }
        peerConnected = connected
        onPeerConnectionChanged?(connected)
        if connected {
            statusLabel.text = "Connected | \(localRole.rawValue.capitalized)"
            statusLabel.removeAction(forKey: "statusPulse")
            statusLabel.alpha = 1
        } else {
            statusLabel.text = "Partner disconnected"
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.55, duration: 0.35),
                SKAction.fadeAlpha(to: 1, duration: 0.35)
            ])
            statusLabel.run(.repeatForever(pulse), withKey: "statusPulse")
        }
    }
}
