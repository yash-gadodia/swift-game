import UIKit

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
    private let gradientLayer = CAGradientLayer()

    private var hasPresentedGame = false
    private var hasStartedSessionAttempt = false
    private var connectedAt: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        wireCallbacks()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    private func setupUI() {
        setupBackground()
        navigationController?.setNavigationBarHidden(true, animated: false)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Daily Duo"
        titleLabel.font = UIFont(name: "AvenirNext-Heavy", size: 40) ?? UIFont.systemFont(ofSize: 40, weight: .heavy)
        titleLabel.textColor = UIColor(red: 0.96, green: 0.99, blue: 0.94, alpha: 1)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Two-player ritual adventure"
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 15) ?? UIFont.systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = UIColor(red: 0.82, green: 0.90, blue: 0.84, alpha: 1)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = UIColor(red: 0.90, green: 0.97, blue: 0.92, alpha: 1)
        statusLabel.text = "Enter 4-digit room code and tap Play."
        statusLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        configureField(serverField, placeholder: "Server URL (dev)")
        serverField.text = "http://127.0.0.1:8081"

        configureField(roomCodeField, placeholder: "Room code (4 digits)")
        roomCodeField.keyboardType = .numberPad
        roomCodeField.font = UIFont.monospacedDigitSystemFont(ofSize: 21, weight: .semibold)
        roomCodeField.addTarget(self, action: #selector(roomCodeEdited), for: .editingChanged)

        configureButton(playButton, title: "Play", action: #selector(playTapped))
        configureButton(pasteButton, title: "Paste", action: #selector(pasteTapped))
        pasteButton.backgroundColor = UIColor(red: 0.18, green: 0.29, blue: 0.23, alpha: 0.94)

        let buttonRow = UIStackView(arrangedSubviews: [playButton, pasteButton])
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.axis = .horizontal
        buttonRow.spacing = 10
        buttonRow.distribution = .fillEqually

        statusCard.translatesAutoresizingMaskIntoConstraints = false
        statusCard.backgroundColor = UIColor(red: 0.11, green: 0.22, blue: 0.17, alpha: 0.82)
        statusCard.layer.cornerRadius = 12
        statusCard.layer.borderColor = UIColor(red: 0.65, green: 0.85, blue: 0.73, alpha: 0.22).cgColor
        statusCard.layer.borderWidth = 1
        statusCard.addSubview(statusLabel)

        stackCard.translatesAutoresizingMaskIntoConstraints = false
        stackCard.backgroundColor = UIColor(red: 0.11, green: 0.17, blue: 0.14, alpha: 0.86)
        stackCard.layer.cornerRadius = 18
        stackCard.layer.borderColor = UIColor(red: 0.66, green: 0.86, blue: 0.75, alpha: 0.22).cgColor
        stackCard.layer.borderWidth = 1
        stackCard.layer.shadowColor = UIColor.black.cgColor
        stackCard.layer.shadowOpacity = 0.25
        stackCard.layer.shadowRadius = 16
        stackCard.layer.shadowOffset = CGSize(width: 0, height: 8)

        let stack = UIStackView(arrangedSubviews: [
            statusCard,
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
    }

    private func configureField(_ field: UITextField, placeholder: String) {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(red: 0.73, green: 0.85, blue: 0.78, alpha: 0.78)
            ]
        )
        field.borderStyle = .roundedRect
        field.backgroundColor = UIColor(red: 0.15, green: 0.25, blue: 0.20, alpha: 0.96)
        field.textColor = UIColor(red: 0.95, green: 0.99, blue: 0.97, alpha: 1)
        field.tintColor = UIColor(red: 0.90, green: 0.97, blue: 0.94, alpha: 1)
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.layer.cornerRadius = 10
        field.layer.borderColor = UIColor(red: 0.67, green: 0.87, blue: 0.76, alpha: 0.25).cgColor
        field.layer.borderWidth = 1
    }

    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor(red: 0.96, green: 0.99, blue: 0.95, alpha: 1), for: .normal)
        button.backgroundColor = UIColor(red: 0.23, green: 0.43, blue: 0.30, alpha: 1)
        button.layer.cornerRadius = 10
        button.layer.borderColor = UIColor(red: 0.80, green: 0.94, blue: 0.85, alpha: 0.32).cgColor
        button.layer.borderWidth = 1
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func setupBackground() {
        view.backgroundColor = UIColor(red: 0.08, green: 0.14, blue: 0.12, alpha: 1)
        gradientLayer.colors = [
            UIColor(red: 0.13, green: 0.24, blue: 0.20, alpha: 1).cgColor,
            UIColor(red: 0.07, green: 0.15, blue: 0.12, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
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
        guard let api = makeAPIClient() else { return }
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
                let room = try await api.enterRoom(roomCode: roomCode, playerId: localPlayerId, playerName: localPlayerName)
                let daily = try await api.fetchDailyLevel(for: Self.utcDateString(from: Date()))
                await MainActor.run {
                    self.activeLevel = daily.level
                    self.currentRole = room.role
                    self.activeRoomCode = room.roomCode
                    self.transport.connectSocket(serverURL: self.serverURL(), roomCode: room.roomCode, playerId: self.localPlayerId)

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

    private func makeAPIClient() -> APIClient? {
        guard let url = URL(string: serverField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") else {
            statusLabel.text = "Invalid server URL"
            return nil
        }
        if let existing = apiClient, apiBaseURL == url {
            return existing
        }
        let api = APIClient(baseURL: url)
        apiClient = api
        apiBaseURL = url
        return api
    }

    private func serverURL() -> URL {
        URL(string: serverField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "http://127.0.0.1:8081")!
    }

    private func friendlyError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("room_full") { return "Room already has 2 players" }
        if msg.contains("invalid_room_code") { return "Invalid code: enter 4 digits" }
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
