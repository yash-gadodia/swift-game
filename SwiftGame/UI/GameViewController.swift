import UIKit
import SpriteKit

final class GameViewController: UIViewController {
    private let transport: SessionTransport
    private let localPlayerId: UUID

    private let skView = SKView()
    private let dPad = VirtualDPad()

    private var gameScene: GameScene?

    init(transport: SessionTransport, localPlayerId: UUID) {
        self.transport = transport
        self.localPlayerId = localPlayerId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.22, green: 0.31, blue: 0.24, alpha: 1)

        setupSKView()
        setupDPad()
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

    private func setupDPad() {
        dPad.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dPad)

        NSLayoutConstraint.activate([
            dPad.widthAnchor.constraint(equalToConstant: 140),
            dPad.heightAnchor.constraint(equalToConstant: 140),
            dPad.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            dPad.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
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
        let scene = GameScene(size: UIScreen.main.bounds.size, transport: transport, localPlayerId: localPlayerId)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        gameScene = scene

        dPad.onVectorChanged = { [weak scene] vector in
            scene?.inputVector = vector
        }
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }
}
