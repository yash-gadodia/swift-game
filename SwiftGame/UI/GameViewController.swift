import UIKit
import SpriteKit
import AVFoundation

enum PixelTheme {
    static let skyTop = UIColor(red: 0.44, green: 0.72, blue: 0.88, alpha: 1)
    static let skyBottom = UIColor(red: 0.66, green: 0.86, blue: 0.92, alpha: 1)
    static let grassDark = UIColor(red: 0.23, green: 0.46, blue: 0.25, alpha: 1)
    static let grassMid = UIColor(red: 0.31, green: 0.59, blue: 0.30, alpha: 1)
    static let woodDark = UIColor(red: 0.34, green: 0.22, blue: 0.15, alpha: 1)
    static let woodMid = UIColor(red: 0.46, green: 0.30, blue: 0.20, alpha: 1)
    static let cream = UIColor(red: 0.99, green: 0.95, blue: 0.84, alpha: 1)
    static let ink = UIColor(red: 0.15, green: 0.11, blue: 0.08, alpha: 1)
    static let accentMint = UIColor(red: 0.69, green: 0.89, blue: 0.64, alpha: 1)
    static let accentPeach = UIColor(red: 0.95, green: 0.69, blue: 0.53, alpha: 1)

    static func stylePixelCard(_ view: UIView) {
        view.backgroundColor = woodMid.withAlphaComponent(0.94)
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 2
        view.layer.borderColor = woodDark.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.22
        view.layer.shadowRadius = 0
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    static func stylePixelButton(_ button: UIButton, fill: UIColor = grassMid, stroke: UIColor = woodDark) {
        button.backgroundColor = fill
        button.layer.cornerRadius = 4
        button.layer.borderWidth = 2
        button.layer.borderColor = stroke.cgColor
        button.setTitleColor(cream, for: .normal)
        button.setTitleColor(cream.withAlphaComponent(0.75), for: .highlighted)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 0
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    static func stylePixelField(_ field: UITextField) {
        field.backgroundColor = UIColor(red: 0.93, green: 0.91, blue: 0.82, alpha: 1)
        field.textColor = ink
        field.tintColor = woodDark
        field.layer.cornerRadius = 4
        field.layer.borderWidth = 2
        field.layer.borderColor = woodDark.cgColor
    }

    static func pixelBackgroundGradientLayer() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [skyTop.cgColor, skyBottom.cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }

    static func pixelBannerImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let pixel: CGFloat = 4

            cg.setFillColor(skyTop.cgColor)
            cg.fill(CGRect(origin: .zero, size: size))

            cg.setFillColor(skyBottom.cgColor)
            cg.fill(CGRect(x: 0, y: size.height * 0.42, width: size.width, height: size.height * 0.58))

            cg.setFillColor(grassDark.cgColor)
            cg.fill(CGRect(x: 0, y: size.height * 0.68, width: size.width, height: size.height * 0.32))

            cg.setFillColor(grassMid.cgColor)
            var x: CGFloat = 0
            while x < size.width {
                let wobble = CGFloat(Int(x / pixel) % 3) * pixel
                cg.fill(CGRect(x: x, y: size.height * 0.64 + wobble * 0.2, width: pixel * 3, height: pixel * 2))
                x += pixel * 5
            }

            func drawCharacter(origin: CGPoint, shirt: UIColor, hair: UIColor, accent: UIColor) {
                let p = pixel
                cg.setFillColor(hair.cgColor)
                cg.fill(CGRect(x: origin.x + p, y: origin.y, width: p * 4, height: p))
                cg.fill(CGRect(x: origin.x, y: origin.y + p, width: p * 6, height: p))
                cg.setFillColor(UIColor(red: 0.99, green: 0.88, blue: 0.76, alpha: 1).cgColor)
                cg.fill(CGRect(x: origin.x + p, y: origin.y + p * 2, width: p * 4, height: p * 2))
                cg.setFillColor(shirt.cgColor)
                cg.fill(CGRect(x: origin.x + p, y: origin.y + p * 4, width: p * 4, height: p * 3))
                cg.setFillColor(accent.cgColor)
                cg.fill(CGRect(x: origin.x, y: origin.y + p * 5, width: p, height: p * 2))
                cg.fill(CGRect(x: origin.x + p * 5, y: origin.y + p * 5, width: p, height: p * 2))
                cg.setFillColor(woodDark.cgColor)
                cg.fill(CGRect(x: origin.x + p, y: origin.y + p * 7, width: p, height: p * 2))
                cg.fill(CGRect(x: origin.x + p * 4, y: origin.y + p * 7, width: p, height: p * 2))
            }

            drawCharacter(
                origin: CGPoint(x: size.width * 0.24, y: size.height * 0.42),
                shirt: accentMint,
                hair: UIColor(red: 0.38, green: 0.25, blue: 0.16, alpha: 1),
                accent: cream
            )
            drawCharacter(
                origin: CGPoint(x: size.width * 0.56, y: size.height * 0.42),
                shirt: accentPeach,
                hair: UIColor(red: 0.26, green: 0.20, blue: 0.14, alpha: 1),
                accent: cream
            )

            cg.setFillColor(cream.withAlphaComponent(0.8).cgColor)
            cg.fill(CGRect(x: size.width * 0.14, y: size.height * 0.2, width: pixel * 10, height: pixel * 2))
            cg.fill(CGRect(x: size.width * 0.68, y: size.height * 0.15, width: pixel * 8, height: pixel * 2))
        }
    }
}

enum PixelBitmapFont {
    private static let glyphWidth = 5
    private static let glyphHeight = 7
    private static let spacing = 1
    private static let glyphs: [Character: [String]] = [
        "A": ["01110","10001","10001","11111","10001","10001","10001"],
        "B": ["11110","10001","10001","11110","10001","10001","11110"],
        "C": ["01111","10000","10000","10000","10000","10000","01111"],
        "D": ["11110","10001","10001","10001","10001","10001","11110"],
        "E": ["11111","10000","10000","11110","10000","10000","11111"],
        "F": ["11111","10000","10000","11110","10000","10000","10000"],
        "G": ["01111","10000","10000","10111","10001","10001","01110"],
        "H": ["10001","10001","10001","11111","10001","10001","10001"],
        "I": ["11111","00100","00100","00100","00100","00100","11111"],
        "J": ["00001","00001","00001","00001","10001","10001","01110"],
        "K": ["10001","10010","10100","11000","10100","10010","10001"],
        "L": ["10000","10000","10000","10000","10000","10000","11111"],
        "M": ["10001","11011","10101","10101","10001","10001","10001"],
        "N": ["10001","11001","10101","10011","10001","10001","10001"],
        "O": ["01110","10001","10001","10001","10001","10001","01110"],
        "P": ["11110","10001","10001","11110","10000","10000","10000"],
        "Q": ["01110","10001","10001","10001","10101","10010","01101"],
        "R": ["11110","10001","10001","11110","10100","10010","10001"],
        "S": ["01111","10000","10000","01110","00001","00001","11110"],
        "T": ["11111","00100","00100","00100","00100","00100","00100"],
        "U": ["10001","10001","10001","10001","10001","10001","01110"],
        "V": ["10001","10001","10001","10001","10001","01010","00100"],
        "W": ["10001","10001","10001","10101","10101","11011","10001"],
        "X": ["10001","10001","01010","00100","01010","10001","10001"],
        "Y": ["10001","10001","01010","00100","00100","00100","00100"],
        "Z": ["11111","00001","00010","00100","01000","10000","11111"],
        "0": ["01110","10001","10011","10101","11001","10001","01110"],
        "1": ["00100","01100","00100","00100","00100","00100","01110"],
        "2": ["01110","10001","00001","00010","00100","01000","11111"],
        "3": ["11110","00001","00001","01110","00001","00001","11110"],
        "4": ["00010","00110","01010","10010","11111","00010","00010"],
        "5": ["11111","10000","10000","11110","00001","00001","11110"],
        "6": ["01110","10000","10000","11110","10001","10001","01110"],
        "7": ["11111","00001","00010","00100","01000","01000","01000"],
        "8": ["01110","10001","10001","01110","10001","10001","01110"],
        "9": ["01110","10001","10001","01111","00001","00001","01110"],
        ":": ["00000","00100","00100","00000","00100","00100","00000"],
        "|": ["00100","00100","00100","00100","00100","00100","00100"],
        ".": ["00000","00000","00000","00000","00000","01100","01100"],
        "-": ["00000","00000","00000","11111","00000","00000","00000"],
        " ": ["00000","00000","00000","00000","00000","00000","00000"],
        "?": ["01110","10001","00010","00100","00100","00000","00100"]
    ]

    static func render(text: String, color: UIColor, scale: CGFloat) -> UIImage {
        let upper = text.uppercased()
        let width = max(1, upper.count * (glyphWidth + spacing) - spacing)
        let height = glyphHeight
        let size = CGSize(width: CGFloat(width) * scale, height: CGFloat(height) * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor.clear.cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
            cg.setFillColor(color.cgColor)

            var cursor = 0
            for character in upper {
                let glyph = glyphs[character] ?? glyphs["?"]!
                for (rowIndex, row) in glyph.enumerated() {
                    for (colIndex, bit) in row.enumerated() where bit == "1" {
                        cg.fill(CGRect(
                            x: CGFloat(cursor + colIndex) * scale,
                            y: CGFloat(rowIndex) * scale,
                            width: scale,
                            height: scale
                        ))
                    }
                }
                cursor += glyphWidth + spacing
            }
        }
    }
}

struct GameUISettings: Equatable {
    var soundEnabled: Bool
    var effectsIntensity: Float
    var hapticsEnabled: Bool
}

struct GameSettingsStore {
    static let soundEnabledKey = "ui.soundEnabled"
    static let effectsIntensityKey = "ui.effectsIntensity"
    static let hapticsEnabledKey = "ui.hapticsEnabled"

    static func load(defaults: UserDefaults = .standard) -> GameUISettings {
        let hasSoundValue = defaults.object(forKey: soundEnabledKey) != nil
        let hasHapticsValue = defaults.object(forKey: hapticsEnabledKey) != nil
        let storedIntensity: Float? = {
            guard let raw = defaults.object(forKey: effectsIntensityKey) else { return nil }
            if let value = raw as? Float {
                return value
            }
            if let value = raw as? Double {
                return Float(value)
            }
            if let value = raw as? NSNumber {
                return value.floatValue
            }
            return nil
        }()

        return GameUISettings(
            soundEnabled: hasSoundValue ? defaults.bool(forKey: soundEnabledKey) : true,
            effectsIntensity: min(1.2, max(0.2, storedIntensity ?? 1)),
            hapticsEnabled: hasHapticsValue ? defaults.bool(forKey: hapticsEnabledKey) : true
        )
    }

    static func persist(_ settings: GameUISettings, defaults: UserDefaults = .standard) {
        defaults.set(settings.soundEnabled, forKey: soundEnabledKey)
        defaults.set(settings.effectsIntensity, forKey: effectsIntensityKey)
        defaults.set(settings.hapticsEnabled, forKey: hapticsEnabledKey)
    }
}

struct GameplayCoachState {
    static let seenKey = "ui.gameplayCoachSeen.v1"

    var hasSeen: Bool

    var shouldShow: Bool { !hasSeen }

    static func load(defaults: UserDefaults = .standard) -> GameplayCoachState {
        GameplayCoachState(hasSeen: defaults.bool(forKey: seenKey))
    }

    func persist(defaults: UserDefaults = .standard) {
        defaults.set(hasSeen, forKey: Self.seenKey)
    }
}

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
    private let roomPixelView = UIImageView()
    private let objectivePixelView = UIImageView()
    private let backButton = UIButton(type: .system)
    private let soundButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let settingsCard = UIView()
    private let intensityLabel = UILabel()
    private let intensitySlider = UISlider()
    private let hapticsLabel = UILabel()
    private let hapticsSwitch = UISwitch()
    private let coachOverlay = UIView()
    private let coachCard = UIView()
    private let coachTitleLabel = UILabel()
    private let coachBodyLabel = UILabel()
    private let coachConfirmButton = UIButton(type: .system)

    private var gameScene: GameScene?
    private let audioEngine = GameAudioEngine()
    private var soundEnabled = true
    private var effectsIntensity: Float = 1
    private var hapticsEnabled = true
    private var coachState = GameplayCoachState.load()

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
        view.backgroundColor = PixelTheme.skyBottom

        setupSKView()
        setupControls()
        setupTopHUD()
        setupSettingsPanel()
        setupCoachOverlay()
        loadSettings()
        audioEngine.applyTheme(level.theme)
        audioEngine.setMasterLevel(effectsIntensity)
        presentScene()
        applyCoachVisibility()
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
        actionButton.setTitle("Interact", for: .normal)
        actionButton.titleLabel?.font = UIFont(name: "Courier-Bold", size: 17) ?? UIFont.monospacedSystemFont(ofSize: 17, weight: .bold)
        PixelTheme.stylePixelButton(actionButton, fill: PixelTheme.accentPeach, stroke: PixelTheme.woodDark)
        actionButton.setTitleColor(PixelTheme.ink, for: .normal)
        actionButton.layer.cornerRadius = 8
        actionButton.addTarget(self, action: #selector(actionDown), for: .touchDown)
        actionButton.addTarget(self, action: #selector(actionUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

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
        PixelTheme.stylePixelCard(topHUDCard)

        roomLabel.translatesAutoresizingMaskIntoConstraints = false
        roomLabel.font = UIFont(name: "Courier-Bold", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        roomLabel.textColor = PixelTheme.cream
        roomLabel.text = "ROOM \(roomCode) | \(localRole.rawValue.uppercased())"
        roomLabel.isHidden = true

        roomPixelView.translatesAutoresizingMaskIntoConstraints = false
        roomPixelView.contentMode = .left
        roomPixelView.layer.magnificationFilter = .nearest
        roomPixelView.layer.minificationFilter = .nearest

        objectiveLabel.translatesAutoresizingMaskIntoConstraints = false
        objectiveLabel.font = UIFont(name: "Courier", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        objectiveLabel.textColor = PixelTheme.cream.withAlphaComponent(0.88)
        objectiveLabel.numberOfLines = 2
        objectiveLabel.text = level.objective
        objectiveLabel.isHidden = true

        objectivePixelView.translatesAutoresizingMaskIntoConstraints = false
        objectivePixelView.contentMode = .left
        objectivePixelView.layer.magnificationFilter = .nearest
        objectivePixelView.layer.minificationFilter = .nearest

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
        topHUDCard.addSubview(roomPixelView)
        topHUDCard.addSubview(objectivePixelView)
        topHUDCard.addSubview(buttonRow)

        NSLayoutConstraint.activate([
            topHUDCard.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            topHUDCard.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            topHUDCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),

            roomLabel.leadingAnchor.constraint(equalTo: topHUDCard.leadingAnchor, constant: 12),
            roomLabel.trailingAnchor.constraint(equalTo: topHUDCard.trailingAnchor, constant: -12),
            roomLabel.topAnchor.constraint(equalTo: topHUDCard.topAnchor, constant: 10),
            roomLabel.heightAnchor.constraint(equalToConstant: 0),

            roomPixelView.leadingAnchor.constraint(equalTo: roomLabel.leadingAnchor),
            roomPixelView.trailingAnchor.constraint(equalTo: roomLabel.trailingAnchor),
            roomPixelView.topAnchor.constraint(equalTo: topHUDCard.topAnchor, constant: 10),
            roomPixelView.heightAnchor.constraint(equalToConstant: 20),

            objectiveLabel.leadingAnchor.constraint(equalTo: roomLabel.leadingAnchor),
            objectiveLabel.trailingAnchor.constraint(equalTo: roomLabel.trailingAnchor),
            objectiveLabel.topAnchor.constraint(equalTo: roomLabel.bottomAnchor, constant: 4),
            objectiveLabel.heightAnchor.constraint(equalToConstant: 0),

            objectivePixelView.leadingAnchor.constraint(equalTo: roomLabel.leadingAnchor),
            objectivePixelView.trailingAnchor.constraint(equalTo: roomLabel.trailingAnchor),
            objectivePixelView.topAnchor.constraint(equalTo: roomPixelView.bottomAnchor, constant: 2),
            objectivePixelView.heightAnchor.constraint(equalToConstant: 34),

            buttonRow.leadingAnchor.constraint(equalTo: roomLabel.leadingAnchor),
            buttonRow.trailingAnchor.constraint(equalTo: roomLabel.trailingAnchor),
            buttonRow.topAnchor.constraint(equalTo: objectivePixelView.bottomAnchor, constant: 8),
            buttonRow.bottomAnchor.constraint(equalTo: topHUDCard.bottomAnchor, constant: -10),
            buttonRow.heightAnchor.constraint(equalToConstant: 30)
        ])
        refreshTopHUDBitmapLabels()
    }

    private func styleTopButton(_ button: UIButton) {
        button.titleLabel?.font = UIFont(name: "Courier-Bold", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        PixelTheme.stylePixelButton(button, fill: PixelTheme.grassDark)
        button.layer.cornerRadius = 4
    }

    private func refreshTopHUDBitmapLabels() {
        let roomText = roomLabel.text ?? "ROOM \(roomCode)"
        let objectiveText = objectiveLabel.text ?? level.objective
        roomPixelView.image = PixelBitmapFont.render(text: roomText, color: PixelTheme.cream, scale: 2)
        objectivePixelView.image = PixelBitmapFont.render(text: objectiveText, color: PixelTheme.cream.withAlphaComponent(0.9), scale: 2)
    }

    private func setupSettingsPanel() {
        settingsCard.translatesAutoresizingMaskIntoConstraints = false
        PixelTheme.stylePixelCard(settingsCard)
        settingsCard.alpha = 0
        settingsCard.isHidden = true

        intensityLabel.translatesAutoresizingMaskIntoConstraints = false
        intensityLabel.text = "FX Intensity"
        intensityLabel.font = UIFont(name: "Courier", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        intensityLabel.textColor = PixelTheme.cream

        intensitySlider.translatesAutoresizingMaskIntoConstraints = false
        intensitySlider.minimumValue = 0.2
        intensitySlider.maximumValue = 1.2
        intensitySlider.value = effectsIntensity
        intensitySlider.minimumTrackTintColor = PixelTheme.accentMint
        intensitySlider.maximumTrackTintColor = PixelTheme.woodDark
        intensitySlider.addTarget(self, action: #selector(intensityChanged), for: .valueChanged)

        hapticsLabel.translatesAutoresizingMaskIntoConstraints = false
        hapticsLabel.text = "Haptics"
        hapticsLabel.font = UIFont(name: "Courier", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        hapticsLabel.textColor = PixelTheme.cream

        hapticsSwitch.translatesAutoresizingMaskIntoConstraints = false
        hapticsSwitch.isOn = true
        hapticsSwitch.onTintColor = PixelTheme.accentMint
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

    private func setupCoachOverlay() {
        coachOverlay.translatesAutoresizingMaskIntoConstraints = false
        coachOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.46)
        coachOverlay.alpha = 0
        coachOverlay.isHidden = true

        coachCard.translatesAutoresizingMaskIntoConstraints = false
        PixelTheme.stylePixelCard(coachCard)

        coachTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        coachTitleLabel.text = "Controls Guide"
        coachTitleLabel.font = UIFont(name: "Courier-Bold", size: 18) ?? UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        coachTitleLabel.textColor = PixelTheme.cream

        coachBodyLabel.translatesAutoresizingMaskIntoConstraints = false
        coachBodyLabel.numberOfLines = 0
        coachBodyLabel.font = UIFont(name: "Courier", size: 13) ?? UIFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        coachBodyLabel.textColor = PixelTheme.cream.withAlphaComponent(0.92)
        coachBodyLabel.text = "Left pad moves your role.\nRight button holds Interact on the switch.\nOpen gate, then hold both players in DUO GOAL."

        coachConfirmButton.translatesAutoresizingMaskIntoConstraints = false
        coachConfirmButton.setTitle("Start Run", for: .normal)
        coachConfirmButton.setTitleColor(PixelTheme.cream, for: .normal)
        coachConfirmButton.titleLabel?.font = UIFont(name: "Courier-Bold", size: 14) ?? UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        PixelTheme.stylePixelButton(coachConfirmButton, fill: PixelTheme.grassDark)
        coachConfirmButton.addTarget(self, action: #selector(dismissCoachOverlay), for: .touchUpInside)

        view.addSubview(coachOverlay)
        coachOverlay.addSubview(coachCard)
        coachCard.addSubview(coachTitleLabel)
        coachCard.addSubview(coachBodyLabel)
        coachCard.addSubview(coachConfirmButton)

        NSLayoutConstraint.activate([
            coachOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coachOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coachOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            coachOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            coachCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            coachCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            coachCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            coachTitleLabel.leadingAnchor.constraint(equalTo: coachCard.leadingAnchor, constant: 14),
            coachTitleLabel.trailingAnchor.constraint(equalTo: coachCard.trailingAnchor, constant: -14),
            coachTitleLabel.topAnchor.constraint(equalTo: coachCard.topAnchor, constant: 14),

            coachBodyLabel.leadingAnchor.constraint(equalTo: coachTitleLabel.leadingAnchor),
            coachBodyLabel.trailingAnchor.constraint(equalTo: coachTitleLabel.trailingAnchor),
            coachBodyLabel.topAnchor.constraint(equalTo: coachTitleLabel.bottomAnchor, constant: 8),

            coachConfirmButton.topAnchor.constraint(equalTo: coachBodyLabel.bottomAnchor, constant: 14),
            coachConfirmButton.trailingAnchor.constraint(equalTo: coachBodyLabel.trailingAnchor),
            coachConfirmButton.bottomAnchor.constraint(equalTo: coachCard.bottomAnchor, constant: -12),
            coachConfirmButton.widthAnchor.constraint(equalToConstant: 96),
            coachConfirmButton.heightAnchor.constraint(equalToConstant: 34)
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
            self?.audioEngine.playCompletionCue()
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
        animateActionButton(pressed: true)
    }

    @objc private func actionUp() {
        gameScene?.actionPressed = false
        animateActionButton(pressed: false)
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
        persistSettings()
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
        persistSettings()
    }

    @objc private func hapticsChanged() {
        joystick.isHapticsEnabled = hapticsSwitch.isOn
        hapticsEnabled = hapticsSwitch.isOn
        persistSettings()
    }

    @objc private func dismissCoachOverlay() {
        guard coachState.shouldShow else { return }
        coachState.hasSeen = true
        coachState.persist()
        applyCoachVisibility(animated: true)
        audioEngine.playUIClick()
    }

    private func handlePeerConnectionState(_ isConnected: Bool) {
        roomLabel.textColor = isConnected
            ? UIColor(red: 0.90, green: 0.98, blue: 0.93, alpha: 1)
            : UIColor(red: 1.0, green: 0.76, blue: 0.70, alpha: 1)
        roomLabel.text = isConnected
            ? "ROOM \(roomCode) | \(localRole.rawValue.uppercased()) | LINKED"
            : "ROOM \(roomCode) | \(localRole.rawValue.uppercased()) | WAITING"
        refreshTopHUDBitmapLabels()
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

    private func animateActionButton(pressed: Bool) {
        UIView.animate(withDuration: 0.08, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.actionButton.transform = pressed ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
            self.actionButton.alpha = pressed ? 0.9 : 1
        }
    }

    private func loadSettings() {
        let settings = GameSettingsStore.load()
        soundEnabled = settings.soundEnabled
        effectsIntensity = settings.effectsIntensity
        hapticsEnabled = settings.hapticsEnabled

        soundButton.setTitle(soundEnabled ? "Sound On" : "Sound Off", for: .normal)
        intensitySlider.value = effectsIntensity
        hapticsSwitch.isOn = hapticsEnabled
        joystick.isHapticsEnabled = hapticsEnabled
    }

    private func persistSettings() {
        GameSettingsStore.persist(
            GameUISettings(
                soundEnabled: soundEnabled,
                effectsIntensity: effectsIntensity,
                hapticsEnabled: hapticsEnabled
            )
        )
    }

    private func applyCoachVisibility(animated: Bool = false) {
        let shouldShow = coachState.shouldShow
        joystick.isUserInteractionEnabled = !shouldShow
        actionButton.isEnabled = !shouldShow
        if shouldShow {
            coachOverlay.isHidden = false
        }

        let apply = {
            self.coachOverlay.alpha = shouldShow ? 1 : 0
        }
        let completion: (Bool) -> Void = { _ in
            if !shouldShow {
                self.coachOverlay.isHidden = true
            }
        }

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: apply, completion: completion)
        } else {
            apply()
            completion(true)
        }
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
    private var completionCueBuffer: AVAudioPCMBuffer?
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
        completionCueBuffer = Self.makeArpeggioCueBuffer(format: format)
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

    func playCompletionCue() {
        guard let completionCueBuffer else { return }
        playCue(completionCueBuffer)
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

    private static func makeArpeggioCueBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration = 0.42
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else {
            return nil
        }

        buffer.frameLength = frameCount
        let left = channels[0]
        let right = channels[1]
        let sampleRate = format.sampleRate
        let notes: [Double] = [523.25, 659.25, 783.99, 1046.5]
        let noteDuration = duration / Double(notes.count)
        let twoPi = 2.0 * Double.pi

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let noteIndex = min(notes.count - 1, Int(t / noteDuration))
            let noteTime = t - (Double(noteIndex) * noteDuration)
            let progress = noteTime / noteDuration
            let envelope = exp(-6 * progress)
            let tone = sin(twoPi * notes[noteIndex] * t)
            let sample = Float(tone * envelope * 0.2)
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
