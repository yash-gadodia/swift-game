import UIKit
import SpriteKit

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

    private var gameScene: GameScene?

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
        setupBackButton()
        presentScene()
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
        actionButton.setTitle(localRole == .anchor ? "Hold" : "Dash", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = UIColor(red: 0.36, green: 0.47, blue: 0.29, alpha: 0.85)
        actionButton.layer.cornerRadius = 30
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        actionButton.addTarget(self, action: #selector(actionDown), for: .touchDown)
        actionButton.addTarget(self, action: #selector(actionUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            joystick.widthAnchor.constraint(equalToConstant: 140),
            joystick.heightAnchor.constraint(equalToConstant: 140),
            joystick.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            joystick.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            actionButton.widthAnchor.constraint(equalToConstant: 120),
            actionButton.heightAnchor.constraint(equalToConstant: 60),
            actionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22)
        ])
    }

    private func setupBackButton() {
        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Back", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.35)
        closeButton.layer.cornerRadius = 8
        closeButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.widthAnchor.constraint(equalToConstant: 64),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
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

        skView.presentScene(scene)
        gameScene = scene

        joystick.onVectorChanged = { [weak scene] vector in
            scene?.inputVector = vector
        }
    }

    @objc private func actionDown() {
        gameScene?.actionPressed = true
    }

    @objc private func actionUp() {
        gameScene?.actionPressed = false
    }

    @objc private func backTapped() {
        dismiss(animated: true)
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
