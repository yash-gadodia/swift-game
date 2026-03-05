import UIKit

struct LobbyOnboardingState {
    static let seenKey = "ui.lobbyOnboardingSeen.v1"

    var hasSeen: Bool

    var shouldShowCard: Bool { !hasSeen }

    static func load(defaults: UserDefaults = .standard) -> LobbyOnboardingState {
        LobbyOnboardingState(hasSeen: defaults.bool(forKey: seenKey))
    }

    func persist(defaults: UserDefaults = .standard) {
        defaults.set(hasSeen, forKey: Self.seenKey)
    }
}

final class LobbyViewController: UIViewController {
    private let localPlayerId = UUID()
    private let localPlayerName = UIDevice.current.name

    private let transport: SessionTransport = WebSocketSessionManager()
    private var apiClient: APIClient?
    private var apiBaseURL: URL?

    private var currentRole: PlayerRole?
    private var activeRoomCode: String?
    private var activeLevel: DailyLevelV1?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusLabel = UILabel()
    private let serverField = UITextField()
    private let roomCodeField = UITextField()
    private let playButton = UIButton(type: .system)
    private let pasteButton = UIButton(type: .system)
    private let stackCard = UIView()
    private let statusCard = UIView()
    private let heroCard = UIView()
    private let heroImageView = UIImageView()
    private let onboardingCard = UIView()
    private let onboardingLabel = UILabel()
    private let onboardingDismissButton = UIButton(type: .system)
    private let gradientLayer = CAGradientLayer()

    private var hasPresentedGame = false
    private var hasStartedSessionAttempt = false
    private var connectedAt: Date?
    private var onboardingState = LobbyOnboardingState.load()
    private var lastHeroRenderSize: CGSize = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        wireCallbacks()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        refreshHeroArtIfNeeded()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    private func setupUI() {
        setupBackground()
        navigationController?.setNavigationBarHidden(true, animated: false)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Daily Duo"
        titleLabel.font = UIFont(name: "Courier-Bold", size: 34) ?? UIFont.monospacedSystemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = PixelTheme.cream

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Two-player ritual adventure"
        subtitleLabel.font = UIFont(name: "Courier", size: 14) ?? UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = PixelTheme.ink.withAlphaComponent(0.82)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont(name: "Courier", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = PixelTheme.cream
        statusLabel.text = "Enter 4-digit room code and tap Play."
        statusLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        configureField(serverField, placeholder: "Server URL (dev)")
        serverField.text = "http://127.0.0.1:8081"

        configureField(roomCodeField, placeholder: "Room code (4 digits)")
        roomCodeField.keyboardType = .numberPad
        roomCodeField.font = UIFont(name: "Courier-Bold", size: 21) ?? UIFont.monospacedDigitSystemFont(ofSize: 21, weight: .bold)
        roomCodeField.addTarget(self, action: #selector(roomCodeEdited), for: .editingChanged)

        configureButton(playButton, title: "Play", action: #selector(playTapped))
        configureButton(pasteButton, title: "Paste", action: #selector(pasteTapped))
        PixelTheme.stylePixelButton(pasteButton, fill: PixelTheme.woodMid)

        let buttonRow = UIStackView(arrangedSubviews: [playButton, pasteButton])
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.axis = .horizontal
        buttonRow.spacing = 10
        buttonRow.distribution = .fillEqually

        statusCard.translatesAutoresizingMaskIntoConstraints = false
        PixelTheme.stylePixelCard(statusCard)
        statusCard.addSubview(statusLabel)

        heroCard.translatesAutoresizingMaskIntoConstraints = false
        PixelTheme.stylePixelCard(heroCard)

        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.image = PixelTheme.pixelBannerImage(size: CGSize(width: 320, height: 118))
        heroImageView.contentMode = .scaleToFill
        heroImageView.layer.magnificationFilter = "nearest"
        heroImageView.layer.minificationFilter = "nearest"
        heroImageView.layer.cornerRadius = 3
        heroImageView.layer.masksToBounds = true
        heroCard.addSubview(heroImageView)

        NSLayoutConstraint.activate([
            heroImageView.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 8),
            heroImageView.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -8),
            heroImageView.topAnchor.constraint(equalTo: heroCard.topAnchor, constant: 8),
            heroImageView.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: -8),
            heroImageView.heightAnchor.constraint(equalToConstant: 118)
        ])

        onboardingCard.translatesAutoresizingMaskIntoConstraints = false
        PixelTheme.stylePixelCard(onboardingCard)

        onboardingLabel.translatesAutoresizingMaskIntoConstraints = false
        onboardingLabel.font = UIFont(name: "Courier", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        onboardingLabel.textColor = PixelTheme.cream
        onboardingLabel.numberOfLines = 0
        onboardingLabel.text = "Quick start: 1) Enter room code. 2) Hold Interact on switch to open gate. 3) Move both players to DUO GOAL."

        onboardingDismissButton.translatesAutoresizingMaskIntoConstraints = false
        onboardingDismissButton.setTitle("Got It", for: .normal)
        onboardingDismissButton.titleLabel?.font = UIFont(name: "Courier-Bold", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        PixelTheme.stylePixelButton(onboardingDismissButton, fill: PixelTheme.grassDark)
        onboardingDismissButton.addTarget(self, action: #selector(dismissOnboarding), for: .touchUpInside)

        onboardingCard.addSubview(onboardingLabel)
        onboardingCard.addSubview(onboardingDismissButton)

        NSLayoutConstraint.activate([
            onboardingLabel.leadingAnchor.constraint(equalTo: onboardingCard.leadingAnchor, constant: 10),
            onboardingLabel.trailingAnchor.constraint(equalTo: onboardingCard.trailingAnchor, constant: -10),
            onboardingLabel.topAnchor.constraint(equalTo: onboardingCard.topAnchor, constant: 10),

            onboardingDismissButton.topAnchor.constraint(equalTo: onboardingLabel.bottomAnchor, constant: 8),
            onboardingDismissButton.trailingAnchor.constraint(equalTo: onboardingLabel.trailingAnchor),
            onboardingDismissButton.bottomAnchor.constraint(equalTo: onboardingCard.bottomAnchor, constant: -10),
            onboardingDismissButton.widthAnchor.constraint(equalToConstant: 72),
            onboardingDismissButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        stackCard.translatesAutoresizingMaskIntoConstraints = false
        PixelTheme.stylePixelCard(stackCard)

        let stack = UIStackView(arrangedSubviews: [
            statusCard,
            heroCard,
            onboardingCard,
            serverField,
            roomCodeField,
            buttonRow
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12

        stackCard.addSubview(stack)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(stackCard)

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -12),
            statusLabel.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 10),
            statusLabel.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -10)
        ])

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            stackCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 26),

            stack.leadingAnchor.constraint(equalTo: stackCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: stackCard.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: stackCard.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: stackCard.bottomAnchor, constant: -16)
        ])

        [serverField, roomCodeField].forEach {
            $0.heightAnchor.constraint(equalToConstant: 42).isActive = true
        }
        [playButton, pasteButton].forEach {
            $0.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }
        onboardingCard.isHidden = !onboardingState.shouldShowCard
    }

    private func configureField(_ field: UITextField, placeholder: String) {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: PixelTheme.woodDark.withAlphaComponent(0.55)
            ]
        )
        field.borderStyle = .roundedRect
        PixelTheme.stylePixelField(field)
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
    }

    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "Courier-Bold", size: 17) ?? UIFont.monospacedSystemFont(ofSize: 17, weight: .bold)
        PixelTheme.stylePixelButton(button)
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func setupBackground() {
        view.backgroundColor = PixelTheme.skyBottom
        let pixelGradient = PixelTheme.pixelBackgroundGradientLayer()
        gradientLayer.colors = pixelGradient.colors
        gradientLayer.startPoint = pixelGradient.startPoint
        gradientLayer.endPoint = pixelGradient.endPoint
        view.layer.insertSublayer(gradientLayer, at: 0)

        let hill = UIView()
        hill.translatesAutoresizingMaskIntoConstraints = false
        hill.backgroundColor = PixelTheme.grassDark
        hill.isUserInteractionEnabled = false
        view.addSubview(hill)
        NSLayoutConstraint.activate([
            hill.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hill.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hill.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hill.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.24)
        ])
    }

    private func refreshHeroArtIfNeeded() {
        let targetSize = CGSize(width: max(180, heroImageView.bounds.width), height: max(90, heroImageView.bounds.height))
        guard targetSize != .zero, targetSize != lastHeroRenderSize else { return }
        heroImageView.image = PixelTheme.pixelBannerImage(size: targetSize)
        lastHeroRenderSize = targetSize
    }

    private func wireCallbacks() {
        transport.onStatusText = { [weak self] text in
            self?.statusLabel.text = text
        }

        transport.onRoomReady = { [weak self] code in
            self?.activeRoomCode = code
            self?.roomCodeField.text = code
        }

        transport.onRoleAssigned = { [weak self] role in
            self?.currentRole = role
            self?.statusLabel.text = "Role: \(role.rawValue.capitalized)"
        }

        transport.onPeerConnected = { [weak self] _ in
            guard let self else { return }
            if self.connectedAt == nil {
                self.connectedAt = Date()
            }
            self.emitTelemetry("session_connected", fields: [
                "transport": "websocket",
                "role": self.currentRole?.rawValue ?? "unknown"
            ])
            self.statusLabel.text = "Partner connected. Joining game..."
            self.presentGameIfReady()
        }

        transport.onPeerDisconnected = { [weak self] _ in
            guard let self else { return }
            self.hasPresentedGame = false
            self.statusLabel.text = "Partner disconnected"
            self.emitTelemetry("session_disconnected", fields: ["transport": "websocket"])
            if let connectedAt = self.connectedAt {
                let duration = Int(Date().timeIntervalSince(connectedAt))
                self.emitTelemetry("session_duration_seconds", fields: ["value": String(duration)])
            }
            self.connectedAt = nil
        }
    }

    @objc private func playTapped() {
        guard let serverURL = configuredServerURL() else {
            statusLabel.text = "Invalid server URL"
            return
        }
        if let warning = localhostConfigurationWarning(for: serverURL) {
            statusLabel.text = warning
            return
        }
        guard let api = makeAPIClient(serverURL: serverURL) else { return }
        let roomCode = normalizedRoomCode()
        guard roomCode.count == 4 else {
            statusLabel.text = "Invalid code: enter 4 digits"
            return
        }
        if hasStartedSessionAttempt {
            emitTelemetry("session_reconnect_attempted", fields: ["transport": "websocket"])
        } else {
            hasStartedSessionAttempt = true
        }
        emitTelemetry("session_room_join_started", fields: [
            "transport": "websocket",
            "room_code_length": String(roomCode.count)
        ])

        Task {
            do {
                _ = try await api.startSession(playerId: localPlayerId)
                let room = try await api.enterRoom(roomCode: roomCode, playerId: localPlayerId, playerName: localPlayerName)
                let daily = try await api.fetchDailyLevel(for: Self.utcDateString(from: Date()))
                await MainActor.run {
                    self.activeLevel = daily.level
                    self.currentRole = room.role
                    self.activeRoomCode = room.roomCode
                    self.transport.connectSocket(
                        serverURL: serverURL,
                        roomCode: room.roomCode,
                        playerId: self.localPlayerId,
                        sessionToken: api.sessionToken
                    )

                    if room.partnerConnected {
                        self.statusLabel.text = "Partner connected. Joining game..."
                        self.presentGameIfReady()
                    } else {
                        self.statusLabel.text = "Waiting for partner..."
                    }
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "Play failed: \(self.friendlyError(error))"
                }
            }
        }
    }

    @objc private func pasteTapped() {
        let pasted = UIPasteboard.general.string ?? ""
        roomCodeField.text = String(pasted.filter(\.isNumber).prefix(4))
    }

    @objc private func roomCodeEdited() {
        roomCodeField.text = normalizedRoomCode()
    }

    @objc private func dismissOnboarding() {
        guard onboardingState.shouldShowCard else { return }
        onboardingState.hasSeen = true
        onboardingState.persist()
        UIView.animate(withDuration: 0.2, animations: {
            self.onboardingCard.alpha = 0
        }, completion: { _ in
            self.onboardingCard.isHidden = true
            self.onboardingCard.alpha = 1
        })
    }

    private func normalizedRoomCode() -> String {
        let raw = roomCodeField.text ?? ""
        return String(raw.filter(\.isNumber).prefix(4))
    }

    private func presentGameIfReady() {
        guard !hasPresentedGame else { return }
        guard
            let role = currentRole,
            let level = activeLevel,
            let roomCode = activeRoomCode,
            let api = apiClient,
            transport.connectedPeerCount > 0
        else {
            return
        }

        hasPresentedGame = true
        let gameVC = GameViewController(
            transport: transport,
            localPlayerId: localPlayerId,
            localRole: role,
            level: level,
            roomCode: roomCode,
            apiClient: api
        )
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }

    private func makeAPIClient(serverURL url: URL) -> APIClient? {
        if let existing = apiClient, apiBaseURL == url {
            return existing
        }
        let api = APIClient(baseURL: url)
        apiClient = api
        apiBaseURL = url
        return api
    }

    private func configuredServerURL() -> URL? {
        URL(string: serverField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    private func localhostConfigurationWarning(for url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        let isLocalhost = host == "localhost" || host == "127.0.0.1"
        guard isLocalhost else { return nil }
        #if targetEnvironment(simulator)
        return nil
        #else
        return "On iPhone, localhost points to the phone. Use your Mac LAN IP (e.g. http://192.168.x.x:8081)."
        #endif
    }

    private func friendlyError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("room_full") { return "Room already has 2 players" }
        if msg.contains("invalid_room_code") { return "Invalid code: enter 4 digits" }
        if msg.contains("could not connect to the server") || msg.contains("timed out") {
            return "Can't reach server. Check URL and use Mac LAN IP on physical devices."
        }
        return error.localizedDescription
    }

    private static func utcDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func emitTelemetry(_ event: String, fields: [String: String] = [:]) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let sanitizedFields = fields.mapValues { String($0.prefix(256)) }

        Task { [apiClient] in
            guard let apiClient else { return }
            do {
                try await apiClient.sendTelemetry(event: event, ts: ts, fields: sanitizedFields)
            } catch {
                print("TELEMETRY_SEND_FAILED event=\(event) error=\(error.localizedDescription)")
            }
        }

        var debugPayload = sanitizedFields
        debugPayload["event"] = event
        debugPayload["ts"] = ts
        if let data = try? JSONSerialization.data(withJSONObject: debugPayload, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            print("TELEMETRY \(json)")
        } else {
            print("TELEMETRY event=\(event)")
        }
    }
}
