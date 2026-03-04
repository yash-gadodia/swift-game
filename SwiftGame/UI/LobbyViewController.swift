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
    private let statusLabel = UILabel()
    private let serverField = UITextField()
    private let roomCodeField = UITextField()
    private let playButton = UIButton(type: .system)
    private let pasteButton = UIButton(type: .system)

    private var hasPresentedGame = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        wireCallbacks()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.15, green: 0.21, blue: 0.17, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Daily Duo"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.88, green: 0.91, blue: 0.84, alpha: 1)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = UIColor(white: 0.9, alpha: 1)
        statusLabel.text = "Enter 4-digit room code and tap Play."

        configureField(serverField, placeholder: "Server URL (dev)")
        serverField.text = "http://127.0.0.1:8081"

        configureField(roomCodeField, placeholder: "Room code (4 digits)")
        roomCodeField.keyboardType = .numberPad

        configureButton(playButton, title: "Play", action: #selector(playTapped))
        configureButton(pasteButton, title: "Paste", action: #selector(pasteTapped))
        pasteButton.backgroundColor = UIColor(red: 0.24, green: 0.33, blue: 0.27, alpha: 1)

        let buttonRow = UIStackView(arrangedSubviews: [playButton, pasteButton])
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.axis = .horizontal
        buttonRow.spacing = 10
        buttonRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            statusLabel,
            serverField,
            roomCodeField,
            buttonRow
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
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
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.backgroundColor = UIColor(red: 0.24, green: 0.31, blue: 0.25, alpha: 1)
        field.textColor = .white
        field.tintColor = .white
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
    }

    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.31, green: 0.43, blue: 0.33, alpha: 1)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: action, for: .touchUpInside)
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
            self?.statusLabel.text = "Partner connected. Joining game..."
            self?.presentGameIfReady()
        }

        transport.onPeerDisconnected = { [weak self] _ in
            self?.hasPresentedGame = false
            self?.statusLabel.text = "Partner disconnected"
        }
    }

    @objc private func playTapped() {
        guard let api = makeAPIClient() else { return }
        let roomCode = normalizedRoomCode()
        guard roomCode.count == 4 else {
            statusLabel.text = "Invalid code: enter 4 digits"
            return
        }

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
}
