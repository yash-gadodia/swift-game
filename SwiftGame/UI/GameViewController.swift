import UIKit
import SpriteKit
import AVFoundation

final class GameViewController: UIViewController {
    private let transport: SessionTransport
    private let localPlayerId: UUID
    private let localRole: PlayerRole
    private let level: DailyLevelV1
    private let roomCode: String
    private let apiClient: APIClient

    private let skView = SKView()
    private let joystick = VirtualDPad()
    private let actionButton = UIButton(type: .system)
    private let topHUDCard = UIView()
    private let roomLabel = UILabel()
    private let objectiveLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let soundButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let settingsCard = UIView()
    private let intensityLabel = UILabel()
    private let intensitySlider = UISlider()
    private let hapticsLabel = UILabel()
    private let hapticsSwitch = UISwitch()

    private var gameScene: GameScene?
    private let audioEngine = GameAudioEngine()
    private var soundEnabled = true
    private var effectsIntensity: Float = 1

    init(
        transport: SessionTransport,
        localPlayerId: UUID,
        localRole: PlayerRole,
        level: DailyLevelV1,
        roomCode: String,
        apiClient: APIClient
    ) {
        self.transport = transport
        self.localPlayerId = localPlayerId
        self.localRole = localRole
        self.level = level
        self.roomCode = roomCode
        self.apiClient = apiClient
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.16, green: 0.24, blue: 0.19, alpha: 1)

        setupSKView()
        setupControls()
        setupTopHUD()
        setupSettingsPanel()
        audioEngine.applyTheme(level.theme)
        audioEngine.setMasterLevel(effectsIntensity)
        presentScene()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if soundEnabled {
            audioEngine.start()
            audioEngine.setMasterLevel(effectsIntensity)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioEngine.stop()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    private func setupSKView() {
        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)

        NSLayoutConstraint.activate([
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skView.topAnchor.constraint(equalTo: view.topAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupControls() {
        joystick.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(joystick)

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitle("Action", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = UIColor(red: 0.36, green: 0.47, blue: 0.29, alpha: 0.85)
        actionButton.layer.cornerRadius = 30
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        actionButton.addTarget(self, action: #selector(actionDown), for: .touchDown)
        actionButton.addTarget(self, action: #selector(actionUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        actionButton.isHidden = true
        actionButton.isUserInteractionEnabled = false

        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            joystick.widthAnchor.constraint(equalToConstant: 148),
            joystick.heightAnchor.constraint(equalToConstant: 148),
            joystick.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            joystick.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            actionButton.widthAnchor.constraint(equalToConstant: 120),
            actionButton.heightAnchor.constraint(equalToConstant: 60),
            actionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22)
        ])
    }

    private func setupTopHUD() {
        topHUDCard.translatesAutoresizingMaskIntoConstraints = false
        topHUDCard.backgroundColor = UIColor(red: 0.06, green: 0.15, blue: 0.11, alpha: 0.74)
        topHUDCard.layer.cornerRadius = 14
        topHUDCard.layer.borderColor = UIColor(red: 0.75, green: 0.9, blue: 0.80, alpha: 0.26).cgColor
        topHUDCard.layer.borderWidth = 1
        topHUDCard.layer.shadowColor = UIColor.black.cgColor
        topHUDCard.layer.shadowOpacity = 0.28
        topHUDCard.layer.shadowRadius = 10
        topHUDCard.layer.shadowOffset = CGSize(width: 0, height: 4)

        roomLabel.translatesAutoresizingMaskIntoConstraints = false
        roomLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        roomLabel.textColor = UIColor(red: 0.90, green: 0.98, blue: 0.93, alpha: 1)
        roomLabel.text = "ROOM \(roomCode) | \(localRole.rawValue.uppercased())"

        objectiveLabel.translatesAutoresizingMaskIntoConstraints = false
        objectiveLabel.font = UIFont(name: "AvenirNext-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        objectiveLabel.textColor = UIColor(red: 0.80, green: 0.90, blue: 0.84, alpha: 1)
        objectiveLabel.numberOfLines = 2
        objectiveLabel.text = level.objective

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Back", for: .normal)
        styleTopButton(backButton)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        soundButton.translatesAutoresizingMaskIntoConstraints = false
        soundButton.setTitle("Sound On", for: .normal)
        styleTopButton(soundButton)
        soundButton.addTarget(self, action: #selector(soundTapped), for: .touchUpInside)

        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setTitle("Tune", for: .normal)
        styleTopButton(settingsButton)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [backButton, soundButton, settingsButton])
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.axis = .horizontal
        buttonRow.spacing = 8
        buttonRow.distribution = .fillProportionally

        view.addSubview(topHUDCard)
        topHUDCard.addSubview(roomLabel)
        topHUDCard.addSubview(objectiveLabel)
        topHUDCard.addSubview(buttonRow)

        NSLayoutConstraint.activate([
            topHUDCard.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            topHUDCard.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            topHUDCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),

            roomLabel.leadingAnchor.constraint(equalTo: topHUDCard.leadingAnchor, constant: 12),
            roomLabel.trailingAnchor.constraint(equalTo: topHUDCard.trailingAnchor, constant: -12),
            roomLabel.topAnchor.constraint(equalTo: topHUDCard.topAnchor, constant: 10),

            objectiveLabel.leadingAnchor.constraint(equalTo: roomLabel.leadingAnchor),
            objectiveLabel.trailingAnchor.constraint(equalTo: roomLabel.trailingAnchor),
            objectiveLabel.topAnchor.constraint(equalTo: roomLabel.bottomAnchor, constant: 4),

            buttonRow.leadingAnchor.constraint(equalTo: roomLabel.leadingAnchor),
            buttonRow.trailingAnchor.constraint(equalTo: roomLabel.trailingAnchor),
            buttonRow.topAnchor.constraint(equalTo: objectiveLabel.bottomAnchor, constant: 8),
            buttonRow.bottomAnchor.constraint(equalTo: topHUDCard.bottomAnchor, constant: -10),
            buttonRow.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func styleTopButton(_ button: UIButton) {
        button.setTitleColor(UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.16, green: 0.28, blue: 0.22, alpha: 0.95)
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.77, green: 0.9, blue: 0.82, alpha: 0.35).cgColor
    }

    private func setupSettingsPanel() {
        settingsCard.translatesAutoresizingMaskIntoConstraints = false
        settingsCard.backgroundColor = UIColor(red: 0.07, green: 0.16, blue: 0.13, alpha: 0.94)
        settingsCard.layer.cornerRadius = 12
        settingsCard.layer.borderWidth = 1
        settingsCard.layer.borderColor = UIColor(red: 0.74, green: 0.90, blue: 0.79, alpha: 0.26).cgColor
        settingsCard.alpha = 0
        settingsCard.isHidden = true

        intensityLabel.translatesAutoresizingMaskIntoConstraints = false
        intensityLabel.text = "FX Intensity"
        intensityLabel.font = UIFont(name: "AvenirNext-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        intensityLabel.textColor = UIColor(red: 0.88, green: 0.96, blue: 0.91, alpha: 1)

        intensitySlider.translatesAutoresizingMaskIntoConstraints = false
        intensitySlider.minimumValue = 0.2
        intensitySlider.maximumValue = 1.2
        intensitySlider.value = effectsIntensity
        intensitySlider.minimumTrackTintColor = UIColor(red: 0.67, green: 0.89, blue: 0.73, alpha: 1)
        intensitySlider.maximumTrackTintColor = UIColor(red: 0.35, green: 0.47, blue: 0.40, alpha: 1)
        intensitySlider.addTarget(self, action: #selector(intensityChanged), for: .valueChanged)

        hapticsLabel.translatesAutoresizingMaskIntoConstraints = false
        hapticsLabel.text = "Haptics"
        hapticsLabel.font = UIFont(name: "AvenirNext-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        hapticsLabel.textColor = UIColor(red: 0.88, green: 0.96, blue: 0.91, alpha: 1)

        hapticsSwitch.translatesAutoresizingMaskIntoConstraints = false
        hapticsSwitch.isOn = true
        hapticsSwitch.onTintColor = UIColor(red: 0.42, green: 0.73, blue: 0.52, alpha: 1)
        hapticsSwitch.addTarget(self, action: #selector(hapticsChanged), for: .valueChanged)

        view.addSubview(settingsCard)
        settingsCard.addSubview(intensityLabel)
        settingsCard.addSubview(intensitySlider)
        settingsCard.addSubview(hapticsLabel)
        settingsCard.addSubview(hapticsSwitch)

        NSLayoutConstraint.activate([
            settingsCard.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            settingsCard.topAnchor.constraint(equalTo: topHUDCard.bottomAnchor, constant: 8),
            settingsCard.widthAnchor.constraint(equalToConstant: 200),

            intensityLabel.leadingAnchor.constraint(equalTo: settingsCard.leadingAnchor, constant: 12),
            intensityLabel.trailingAnchor.constraint(equalTo: settingsCard.trailingAnchor, constant: -12),
            intensityLabel.topAnchor.constraint(equalTo: settingsCard.topAnchor, constant: 10),

            intensitySlider.leadingAnchor.constraint(equalTo: intensityLabel.leadingAnchor),
            intensitySlider.trailingAnchor.constraint(equalTo: intensityLabel.trailingAnchor),
            intensitySlider.topAnchor.constraint(equalTo: intensityLabel.bottomAnchor, constant: 6),

            hapticsLabel.leadingAnchor.constraint(equalTo: intensityLabel.leadingAnchor),
            hapticsLabel.topAnchor.constraint(equalTo: intensitySlider.bottomAnchor, constant: 10),

            hapticsSwitch.trailingAnchor.constraint(equalTo: intensityLabel.trailingAnchor),
            hapticsSwitch.centerYAnchor.constraint(equalTo: hapticsLabel.centerYAnchor),
            hapticsSwitch.bottomAnchor.constraint(equalTo: settingsCard.bottomAnchor, constant: -10)
        ])
    }

    private func presentScene() {
        let scene = GameScene(
            size: UIScreen.main.bounds.size,
            transport: transport,
            localPlayerId: localPlayerId,
            localRole: localRole,
            level: level
        )
        scene.scaleMode = .resizeFill
        scene.onLevelCompleted = { [weak self] in
            self?.handleLevelCompletion()
        }
        scene.onPeerConnectionChanged = { [weak self] isConnected in
            self?.handlePeerConnectionState(isConnected)
        }

        skView.presentScene(scene)
        gameScene = scene

        joystick.onVectorChanged = { [weak self, weak scene] vector in
            scene?.inputVector = vector
            let intensity = min(1, max(0, hypot(vector.x, vector.y)))
            self?.audioEngine.setMovementIntensity(intensity * (self?.effectsIntensity ?? 1))
        }
    }

    @objc private func actionDown() {
        gameScene?.actionPressed = true
    }

    @objc private func actionUp() {
        gameScene?.actionPressed = false
    }

    @objc private func backTapped() {
        audioEngine.stop()
        dismiss(animated: true)
    }

    @objc private func soundTapped() {
        soundEnabled.toggle()
        soundButton.setTitle(soundEnabled ? "Sound On" : "Sound Off", for: .normal)
        audioEngine.playUIClick()
        if soundEnabled {
            audioEngine.start()
            audioEngine.setMasterLevel(effectsIntensity)
        } else {
            audioEngine.stop()
        }
    }

    @objc private func settingsTapped() {
        let shouldShow = settingsCard.isHidden
        if shouldShow {
            settingsCard.isHidden = false
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.settingsCard.alpha = shouldShow ? 1 : 0
        } completion: { _ in
            if !shouldShow {
                self.settingsCard.isHidden = true
            }
        }
        audioEngine.playUIClick()
    }

    @objc private func intensityChanged() {
        effectsIntensity = intensitySlider.value
        audioEngine.setMasterLevel(effectsIntensity)
    }

    @objc private func hapticsChanged() {
        joystick.isHapticsEnabled = hapticsSwitch.isOn
    }

    private func handlePeerConnectionState(_ isConnected: Bool) {
        roomLabel.textColor = isConnected
            ? UIColor(red: 0.90, green: 0.98, blue: 0.93, alpha: 1)
            : UIColor(red: 1.0, green: 0.76, blue: 0.70, alpha: 1)
        roomLabel.text = isConnected
            ? "ROOM \(roomCode) | \(localRole.rawValue.uppercased()) | LINKED"
            : "ROOM \(roomCode) | \(localRole.rawValue.uppercased()) | WAITING"
        if isConnected {
            audioEngine.playConnectedCue()
        } else {
            audioEngine.playDisconnectedCue()
        }
    }

    private func handleLevelCompletion() {
        Task {
            do {
                let completion = try await apiClient.recordCompletion(
                    roomCode: roomCode,
                    playerId: localPlayerId,
                    levelId: level.levelId
                )
                await MainActor.run {
                    self.presentCompletionOutcome(completion)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Completion Saved Locally", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func presentCompletionOutcome(_ completion: CompletionResponse) {
        if let duoId = completion.duoId {
            Task {
                do {
                    let payload = try await apiClient.fetchPostcardPayload(duoId: duoId)
                    await MainActor.run {
                        self.presentShareSheet(payload: payload)
                    }
                } catch {
                    await MainActor.run {
                        let alert = UIAlertController(title: "Completed", message: "Partner linked, postcard pending. \(error.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
            return
        }

        let alert = UIAlertController(
            title: "Checkpoint Saved",
            message: "Waiting for your partner to finish this level.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func presentShareSheet(payload: PostcardPayloadV1) {
        guard let image = skView.snapshot() else { return }
        let text = "\(payload.duoName) completed \(payload.dateUTC) together. \(payload.stamp)"
        let activity = UIActivityViewController(activityItems: [text, image], applicationActivities: nil)
        present(activity, animated: true)
    }
}

private extension SKView {
    func snapshot() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}

private final class GameAudioEngine {
    private let engine = AVAudioEngine()
    private let ambientPlayer = AVAudioPlayerNode()
    private let movementPlayer = AVAudioPlayerNode()
    private let cuePlayer = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    private var ambientLoopBuffer: AVAudioPCMBuffer?
    private var movementLoopBuffer: AVAudioPCMBuffer?
    private var connectedCueBuffer: AVAudioPCMBuffer?
    private var disconnectedCueBuffer: AVAudioPCMBuffer?
    private var uiClickBuffer: AVAudioPCMBuffer?
    private var movementVolume: Float = 0
    private var masterLevel: Float = 1

    private struct ThemeProfile {
        let droneHz: Double
        let overtoneHz: Double
        let shimmerHz: Double
        let movementPulseHz: Double
        let connectFromHz: Double
        let connectToHz: Double
        let disconnectFromHz: Double
        let disconnectToHz: Double
    }

    init() {
        [ambientPlayer, movementPlayer, cuePlayer].forEach {
            engine.attach($0)
            engine.connect($0, to: engine.mainMixerNode, format: format)
        }
        engine.mainMixerNode.outputVolume = 0.5
        ambientPlayer.volume = 0.58
        movementPlayer.volume = 0
        cuePlayer.volume = 0.9

        applyTheme("forest")
        uiClickBuffer = Self.makePercussiveClickBuffer(format: format)
    }

    func start() {
        guard let ambientLoopBuffer, let movementLoopBuffer else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            if !engine.isRunning {
                try engine.start()
            }
            if !ambientPlayer.isPlaying {
                ambientPlayer.scheduleBuffer(ambientLoopBuffer, at: nil, options: .loops)
                ambientPlayer.play()
            }
            if !movementPlayer.isPlaying {
                movementPlayer.scheduleBuffer(movementLoopBuffer, at: nil, options: .loops)
                movementPlayer.play()
            }
        } catch {
            print("AUDIO ambient_start_failed \(error.localizedDescription)")
        }
    }

    func stop() {
        if ambientPlayer.isPlaying {
            ambientPlayer.stop()
        }
        if movementPlayer.isPlaying {
            movementPlayer.stop()
        }
        if cuePlayer.isPlaying {
            cuePlayer.stop()
        }
        if engine.isRunning {
            engine.pause()
        }
    }

    func setMovementIntensity(_ intensity: Float) {
        let clamped = min(1, max(0, intensity))
        movementVolume = clamped
        movementPlayer.volume = clamped * 0.28 * masterLevel
    }

    func setMasterLevel(_ level: Float) {
        masterLevel = min(1.2, max(0.2, level))
        ambientPlayer.volume = 0.58 * masterLevel
        movementPlayer.volume = movementVolume * 0.28 * masterLevel
        cuePlayer.volume = 0.9 * min(masterLevel, 1)
    }

    func applyTheme(_ theme: String) {
        let profile = Self.profileForTheme(theme)
        ambientLoopBuffer = Self.makeAmbientLoopBuffer(
            format: format,
            droneHz: profile.droneHz,
            overtoneHz: profile.overtoneHz,
            shimmerHz: profile.shimmerHz
        )
        movementLoopBuffer = Self.makeMovementLoopBuffer(
            format: format,
            movementPulseHz: profile.movementPulseHz
        )
        connectedCueBuffer = Self.makeToneCueBuffer(
            format: format,
            baseFrequency: profile.connectFromHz,
            riseTo: profile.connectToHz,
            duration: 0.18
        )
        disconnectedCueBuffer = Self.makeToneCueBuffer(
            format: format,
            baseFrequency: profile.disconnectFromHz,
            riseTo: profile.disconnectToHz,
            duration: 0.22
        )
    }

    func playConnectedCue() {
        guard let connectedCueBuffer else { return }
        playCue(connectedCueBuffer)
    }

    func playDisconnectedCue() {
        guard let disconnectedCueBuffer else { return }
        playCue(disconnectedCueBuffer)
    }

    func playUIClick() {
        guard let uiClickBuffer else { return }
        playCue(uiClickBuffer)
    }

    private func playCue(_ buffer: AVAudioPCMBuffer) {
        if !engine.isRunning {
            return
        }
        cuePlayer.stop()
        cuePlayer.scheduleBuffer(buffer, at: nil)
        cuePlayer.play()
    }

    private static func makeAmbientLoopBuffer(
        format: AVAudioFormat,
        droneHz: Double,
        overtoneHz: Double,
        shimmerHz: Double
    ) -> AVAudioPCMBuffer? {
        let seconds = 8.0
        let frameCount = AVAudioFrameCount(format.sampleRate * seconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else {
            return nil
        }

        buffer.frameLength = frameCount
        let left = channels[0]
        let right = channels[1]
        let sampleRate = format.sampleRate
        let twoPi = 2.0 * Double.pi

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let envelope = 0.65 + 0.35 * sin(twoPi * 0.07 * t)
            let drone = sin(twoPi * droneHz * t) * 0.06
            let overtone = sin(twoPi * overtoneHz * t) * 0.035
            let shimmer = sin(twoPi * shimmerHz * t) * 0.018
            let sample = Float((drone + overtone + shimmer) * envelope)
            left[frame] = sample
            right[frame] = sample * 0.97
        }

        return buffer
    }

    private static func makeMovementLoopBuffer(format: AVAudioFormat, movementPulseHz: Double) -> AVAudioPCMBuffer? {
        let seconds = 2.0
        let frameCount = AVAudioFrameCount(format.sampleRate * seconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else {
            return nil
        }

        buffer.frameLength = frameCount
        let left = channels[0]
        let right = channels[1]
        let sampleRate = format.sampleRate
        let twoPi = 2.0 * Double.pi
        var state: UInt32 = 0x1234ABCD

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            state = state &* 1_664_525 &+ 1_013_904_223
            let noise = (Double(state & 0xFFFF) / 65535.0) * 2 - 1
            let lowPulse = sin(twoPi * movementPulseHz * t) * 0.5 + 0.5
            let sample = Float((noise * 0.025) * lowPulse)
            left[frame] = sample
            right[frame] = sample * 0.95
        }

        return buffer
    }

    private static func makeToneCueBuffer(format: AVAudioFormat, baseFrequency: Double, riseTo: Double, duration: Double) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else {
            return nil
        }

        buffer.frameLength = frameCount
        let left = channels[0]
        let right = channels[1]
        let sampleRate = format.sampleRate
        let twoPi = 2.0 * Double.pi

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(frameCount)
            let frequency = baseFrequency + (riseTo - baseFrequency) * progress
            let envelope = (1 - progress) * (1 - progress)
            let sample = Float(sin(twoPi * frequency * Double(frame) / sampleRate) * envelope * 0.22)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private static func makePercussiveClickBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * 0.06)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else {
            return nil
        }

        buffer.frameLength = frameCount
        let left = channels[0]
        let right = channels[1]
        let sampleRate = format.sampleRate
        let twoPi = 2.0 * Double.pi

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let decay = exp(-35 * t)
            let tone = sin(twoPi * 880 * t) + 0.35 * sin(twoPi * 1240 * t)
            let sample = Float(tone * decay * 0.18)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private static func profileForTheme(_ theme: String) -> ThemeProfile {
        switch theme.lowercased() {
        case "ember":
            return ThemeProfile(
                droneHz: 98,
                overtoneHz: 146.83,
                shimmerHz: 196,
                movementPulseHz: 24,
                connectFromHz: 440,
                connectToHz: 659.25,
                disconnectFromHz: 293.66,
                disconnectToHz: 220
            )
        case "twilight":
            return ThemeProfile(
                droneHz: 130.81,
                overtoneHz: 196,
                shimmerHz: 261.63,
                movementPulseHz: 15,
                connectFromHz: 392,
                connectToHz: 587.33,
                disconnectFromHz: 246.94,
                disconnectToHz: 185
            )
        default:
            return ThemeProfile(
                droneHz: 110,
                overtoneHz: 164.81,
                shimmerHz: 219.99,
                movementPulseHz: 18,
                connectFromHz: 392,
                connectToHz: 523.25,
                disconnectFromHz: 260,
                disconnectToHz: 196
            )
        }
    }
}
