import UIKit

final class LobbyViewController: UIViewController {
    private let localPlayerId = UUID()
    private let localPlayerName = UIDevice.current.name

    private let transport: SessionTransport = WebSocketSessionManager()
    private var apiClient: APIClient?

    private var duoProfile: DuoProfileV1?
    private var currentRole: PlayerRole?
    private var activeRoomCode: String?
    private var activeLevel: DailyLevelV1?

    private let titleLabel = UILabel()
    private let statusLabel = UILabel()

    private let serverField = UITextField()
    private let duoNameField = UITextField()
    private let duoCodeField = UITextField()
    private let roomCodeField = UITextField()

    private let createDuoButton = UIButton(type: .system)
    private let joinDuoButton = UIButton(type: .system)
    private let createRoomButton = UIButton(type: .system)
    private let joinRoomButton = UIButton(type: .system)

    private let streakLabel = UILabel()
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
        statusLabel.text = "Set server URL, create/join duo, then create/join room."

        streakLabel.translatesAutoresizingMaskIntoConstraints = false
        streakLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        streakLabel.textColor = UIColor(red: 0.84, green: 0.9, blue: 0.73, alpha: 1)
        streakLabel.text = "Duo streak: -"

        configureField(serverField, placeholder: "Server URL (e.g. http://127.0.0.1:8080)")
        serverField.text = "http://127.0.0.1:8080"

        configureField(duoNameField, placeholder: "Duo name (for create)")
        duoNameField.text = "Forest Duo"

        configureField(duoCodeField, placeholder: "Duo code (for join)")
        configureField(roomCodeField, placeholder: "Room code (4 digits)")
        roomCodeField.keyboardType = .numberPad

        configureButton(createDuoButton, title: "Create Duo", action: #selector(createDuoTapped))
        configureButton(joinDuoButton, title: "Join Duo", action: #selector(joinDuoTapped))
        configureButton(createRoomButton, title: "Create Daily Room", action: #selector(createRoomTapped))
        configureButton(joinRoomButton, title: "Join Daily Room", action: #selector(joinRoomTapped))

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            statusLabel,
            streakLabel,
            serverField,
            duoNameField,
            createDuoButton,
            duoCodeField,
            joinDuoButton,
            createRoomButton,
            roomCodeField,
            joinRoomButton
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

        [serverField, duoNameField, duoCodeField, roomCodeField].forEach {
            $0.heightAnchor.constraint(equalToConstant: 42).isActive = true
        }
        [createDuoButton, joinDuoButton, createRoomButton, joinRoomButton].forEach {
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
            self?.statusLabel.text = "Role assigned: \(role.rawValue.capitalized)"
        }

        transport.onPeerConnected = { [weak self] _ in
            self?.presentGameIfReady()
        }

        transport.onPeerDisconnected = { [weak self] _ in
            self?.hasPresentedGame = false
            self?.statusLabel.text = "Partner disconnected"
        }
    }

    @objc private func createDuoTapped() {
        guard let api = makeAPIClient() else { return }
        let duoName = duoNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeName = duoName?.isEmpty == false ? duoName! : "Forest Duo"

        Task {
            do {
                let profile = try await api.createDuo(duoName: safeName, playerName: localPlayerName)
                await MainActor.run {
                    self.duoProfile = profile
                    self.duoCodeField.text = profile.duoCode
                    self.streakLabel.text = "Duo streak: \(profile.currentStreak) | Grace: \(profile.graceTokens)"
                    self.statusLabel.text = "Duo created. Share code \(profile.duoCode)."
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "Create duo failed: \(error.localizedDescription)"
                }
            }
        }
    }

    @objc private func joinDuoTapped() {
        guard let api = makeAPIClient() else { return }
        let code = duoCodeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !code.isEmpty else {
            statusLabel.text = "Enter duo code first"
            return
        }

        Task {
            do {
                let profile = try await api.joinDuo(duoCode: code, playerName: localPlayerName)
                await MainActor.run {
                    self.duoProfile = profile
                    self.streakLabel.text = "Duo streak: \(profile.currentStreak) | Grace: \(profile.graceTokens)"
                    self.statusLabel.text = "Duo joined: \(profile.duoName)"
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "Join duo failed: \(error.localizedDescription)"
                }
            }
        }
    }

    @objc private func createRoomTapped() {
        guard let api = makeAPIClient() else { return }
        guard let duo = duoProfile else {
            statusLabel.text = "Create or join duo first"
            return
        }

        Task {
            do {
                let room = try await api.createRoom(duoId: duo.duoId, playerId: localPlayerId, playerName: localPlayerName)
                let daily = try await api.fetchDailyLevel(for: Self.utcDateString(from: Date()))
                await MainActor.run {
                    self.activeLevel = daily.level
                    self.currentRole = room.role
                    self.transport.connectSocket(serverURL: self.serverURL(), roomCode: room.roomCode, playerId: self.localPlayerId)
                    self.statusLabel.text = "Room \(room.roomCode) ready. Waiting for partner..."
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "Create room failed: \(error.localizedDescription)"
                }
            }
        }
    }

    @objc private func joinRoomTapped() {
        guard let api = makeAPIClient() else { return }
        guard let duo = duoProfile else {
            statusLabel.text = "Create or join duo first"
            return
        }

        let roomCode = roomCodeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard roomCode.count == 4 else {
            statusLabel.text = "Room code must be 4 digits"
            return
        }

        Task {
            do {
                let room = try await api.joinRoom(roomCode: roomCode, duoId: duo.duoId, playerId: localPlayerId, playerName: localPlayerName)
                let daily = try await api.fetchDailyLevel(for: Self.utcDateString(from: Date()))
                await MainActor.run {
                    self.activeLevel = daily.level
                    self.currentRole = room.role
                    self.transport.connectSocket(serverURL: self.serverURL(), roomCode: roomCode, playerId: self.localPlayerId)
                    self.statusLabel.text = "Joined room \(roomCode). Waiting for sync..."
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "Join room failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func presentGameIfReady() {
        guard !hasPresentedGame else { return }
        guard let role = currentRole, let level = activeLevel, let duoId = duoProfile?.duoId, let api = apiClient else {
            statusLabel.text = "Waiting for role + daily level"
            return
        }

        hasPresentedGame = true

        let gameVC = GameViewController(
            transport: transport,
            localPlayerId: localPlayerId,
            localRole: role,
            level: level,
            duoId: duoId,
            apiClient: api
        )
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }

    private func makeAPIClient() -> APIClient? {
        if let existing = apiClient {
            return existing
        }
        guard let url = URL(string: serverField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") else {
            statusLabel.text = "Invalid server URL"
            return nil
        }
        let api = APIClient(baseURL: url)
        self.apiClient = api
        return api
    }

    private func serverURL() -> URL {
        URL(string: serverField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "http://127.0.0.1:8080")!
    }

    private static func utcDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
