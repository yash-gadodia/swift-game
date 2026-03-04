import UIKit
import MultipeerConnectivity

final class LobbyViewController: UIViewController {
    private let transport: SessionTransport = MultipeerSessionManager()
    private let localPlayerId = UUID()

    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let hostButton = UIButton(type: .system)
    private let joinButton = UIButton(type: .system)
    private let peersTableView = UITableView(frame: .zero, style: .insetGrouped)

    private var peers: [MCPeerID] = []
    private var hasPresentedGame = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        wireCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        wireCallbacks()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.16, green: 0.24, blue: 0.19, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Swift Game MVP"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = UIColor(white: 0.92, alpha: 1)
        statusLabel.text = "Choose Host or Join"

        configureButton(hostButton, title: "Host Game", action: #selector(hostTapped))
        configureButton(joinButton, title: "Join Game", action: #selector(joinTapped))

        peersTableView.translatesAutoresizingMaskIntoConstraints = false
        peersTableView.backgroundColor = .clear
        peersTableView.dataSource = self
        peersTableView.delegate = self
        peersTableView.register(UITableViewCell.self, forCellReuseIdentifier: "PeerCell")

        view.addSubview(titleLabel)
        view.addSubview(statusLabel)
        view.addSubview(hostButton)
        view.addSubview(joinButton)
        view.addSubview(peersTableView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            hostButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 18),
            hostButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hostButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            hostButton.heightAnchor.constraint(equalToConstant: 52),

            joinButton.topAnchor.constraint(equalTo: hostButton.bottomAnchor, constant: 10),
            joinButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            joinButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            joinButton.heightAnchor.constraint(equalToConstant: 52),

            peersTableView.topAnchor.constraint(equalTo: joinButton.bottomAnchor, constant: 16),
            peersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            peersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            peersTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.31, green: 0.45, blue: 0.34, alpha: 1)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func wireCallbacks() {
        transport.onStatusText = { [weak self] text in
            self?.statusLabel.text = text
        }

        transport.onPeersChanged = { [weak self] peers in
            self?.peers = peers
            self?.peersTableView.reloadData()
        }

        transport.onPeerConnected = { [weak self] _ in
            self?.presentGameIfNeeded()
        }

        transport.onPeerDisconnected = { [weak self] _ in
            self?.hasPresentedGame = false
            self?.statusLabel.text = "Peer disconnected. Host or Join again."
        }
    }

    @objc private func hostTapped() {
        hasPresentedGame = false
        transport.startHosting(displayName: UIDevice.current.name)
    }

    @objc private func joinTapped() {
        hasPresentedGame = false
        peers = []
        peersTableView.reloadData()
        transport.startBrowsing(displayName: UIDevice.current.name)
    }

    private func presentGameIfNeeded() {
        guard !hasPresentedGame else { return }
        hasPresentedGame = true

        let gameVC = GameViewController(transport: transport, localPlayerId: localPlayerId)
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }
}

extension LobbyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        peers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeerCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = peers[indexPath.row].displayName
        content.secondaryText = "Tap to invite"
        cell.contentConfiguration = content
        cell.backgroundColor = UIColor(white: 1, alpha: 0.06)
        return cell
    }
}

extension LobbyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        transport.invite(peer: peers[indexPath.row])
    }
}
