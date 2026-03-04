import Foundation
import MultipeerConnectivity

protocol SessionTransport: AnyObject {
    var connectedPeerCount: Int { get }
    var availablePeers: [MCPeerID] { get }

    var onPeersChanged: (([MCPeerID]) -> Void)? { get set }
    var onPeerConnected: ((MCPeerID) -> Void)? { get set }
    var onPeerDisconnected: ((MCPeerID) -> Void)? { get set }
    var onMessage: ((NetMessage, MCPeerID) -> Void)? { get set }
    var onStatusText: ((String) -> Void)? { get set }

    func startHosting(displayName: String)
    func startBrowsing(displayName: String)
    func invite(peer: MCPeerID)
    func stop()
    func send(_ message: NetMessage)
}

final class MultipeerSessionManager: NSObject, SessionTransport {
    static let serviceType = "swftgmvp"

    private(set) var availablePeers: [MCPeerID] = [] {
        didSet { onPeersChanged?(availablePeers) }
    }

    var connectedPeerCount: Int {
        session?.connectedPeers.count ?? 0
    }

    var onPeersChanged: (([MCPeerID]) -> Void)?
    var onPeerConnected: ((MCPeerID) -> Void)?
    var onPeerDisconnected: ((MCPeerID) -> Void)?
    var onMessage: ((NetMessage, MCPeerID) -> Void)?
    var onStatusText: ((String) -> Void)?

    private var myPeerID: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func startHosting(displayName: String) {
        resetSession(displayName: displayName)
        guard let myPeerID, let session else { return }

        let advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
        onStatusText?("Hosting as \(myPeerID.displayName). Waiting for player...")
    }

    func startBrowsing(displayName: String) {
        resetSession(displayName: displayName)
        guard let myPeerID, let session else { return }

        let browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
        onStatusText?("Browsing nearby hosts as \(myPeerID.displayName)...")

        if session.connectedPeers.isEmpty {
            availablePeers = []
        }
    }

    func invite(peer: MCPeerID) {
        guard let session, let browser else { return }
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 12)
        onStatusText?("Invited \(peer.displayName)...")
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil

        browser?.stopBrowsingForPeers()
        browser = nil

        session?.disconnect()
        session = nil

        availablePeers = []
        onStatusText?("Stopped")
    }

    func send(_ message: NetMessage) {
        guard let session, !session.connectedPeers.isEmpty else { return }
        do {
            let data = try encoder.encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            onStatusText?("Send failed: \(error.localizedDescription)")
        }
    }

    private func resetSession(displayName: String) {
        stop()
        let peerID = MCPeerID(displayName: displayName)
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        self.myPeerID = peerID
        self.session = session
    }
}

extension MultipeerSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        guard let session else {
            invitationHandler(false, nil)
            return
        }
        guard session.connectedPeers.isEmpty else {
            invitationHandler(false, nil)
            onStatusText?("Rejected \(peerID.displayName): session already full")
            return
        }
        invitationHandler(true, session)
        onStatusText?("Accepted invite from \(peerID.displayName)")
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        onStatusText?("Advertising failed: \(error.localizedDescription)")
    }
}

extension MultipeerSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        if !availablePeers.contains(peerID) {
            availablePeers.append(peerID)
            onStatusText?("Found host: \(peerID.displayName)")
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        availablePeers.removeAll(where: { $0 == peerID })
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        onStatusText?("Browse failed: \(error.localizedDescription)")
    }
}

extension MultipeerSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                self.onStatusText?("Disconnected: \(peerID.displayName)")
                self.onPeerDisconnected?(peerID)
            case .connecting:
                self.onStatusText?("Connecting to \(peerID.displayName)...")
            case .connected:
                self.onStatusText?("Connected: \(peerID.displayName)")
                self.onPeerConnected?(peerID)
            @unknown default:
                self.onStatusText?("Unknown connection state")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try decoder.decode(NetMessage.self, from: data)
            DispatchQueue.main.async {
                self.onMessage?(message, peerID)
            }
        } catch {
            DispatchQueue.main.async {
                self.onStatusText?("Decode failed: \(error.localizedDescription)")
            }
        }
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {}

    func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        certificateHandler(true)
    }
}
