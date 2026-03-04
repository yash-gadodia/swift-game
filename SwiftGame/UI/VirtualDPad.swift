import UIKit
import simd

final class VirtualDPad: UIView {
    var onVectorChanged: ((SIMD2<Float>) -> Void)?
    var isHapticsEnabled = true

    private let baseView = UIView()
    private let ringView = UIView()
    private let knobView = UIView()
    private let horizontalGuide = UIView()
    private let verticalGuide = UIView()
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    private var radius: CGFloat {
        min(bounds.width, bounds.height) * 0.5
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        isMultipleTouchEnabled = false

        baseView.backgroundColor = UIColor(red: 0.12, green: 0.17, blue: 0.14, alpha: 0.72)
        baseView.layer.borderColor = UIColor(red: 0.74, green: 0.88, blue: 0.78, alpha: 0.35).cgColor
        baseView.layer.borderWidth = 2.5
        baseView.layer.shadowColor = UIColor.black.cgColor
        baseView.layer.shadowOpacity = 0.35
        baseView.layer.shadowOffset = CGSize(width: 0, height: 6)
        baseView.layer.shadowRadius = 12
        addSubview(baseView)

        ringView.backgroundColor = UIColor.clear
        ringView.layer.borderColor = UIColor(red: 0.65, green: 0.80, blue: 0.68, alpha: 0.6).cgColor
        ringView.layer.borderWidth = 1.5
        addSubview(ringView)

        [horizontalGuide, verticalGuide].forEach {
            $0.backgroundColor = UIColor(red: 0.90, green: 0.98, blue: 0.93, alpha: 0.22)
            addSubview($0)
        }

        knobView.backgroundColor = UIColor(red: 0.93, green: 1.0, blue: 0.95, alpha: 0.92)
        knobView.layer.borderColor = UIColor(red: 0.33, green: 0.46, blue: 0.36, alpha: 0.8).cgColor
        knobView.layer.borderWidth = 1.5
        knobView.layer.shadowColor = UIColor.black.cgColor
        knobView.layer.shadowOpacity = 0.25
        knobView.layer.shadowOffset = CGSize(width: 0, height: 2)
        knobView.layer.shadowRadius = 4
        addSubview(knobView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        baseView.frame = bounds
        baseView.layer.cornerRadius = radius
        baseView.layer.shadowPath = UIBezierPath(ovalIn: baseView.bounds).cgPath

        let ringInset = radius * 0.15
        ringView.frame = bounds.insetBy(dx: ringInset, dy: ringInset)
        ringView.layer.cornerRadius = ringView.bounds.width * 0.5

        horizontalGuide.frame = CGRect(x: bounds.minX + radius * 0.22, y: bounds.midY - 0.5, width: bounds.width - radius * 0.44, height: 1)
        verticalGuide.frame = CGRect(x: bounds.midX - 0.5, y: bounds.minY + radius * 0.22, width: 1, height: bounds.height - radius * 0.44)

        let knobSize = radius * 0.75
        knobView.frame = CGRect(x: 0, y: 0, width: knobSize, height: knobSize)
        knobView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        knobView.layer.cornerRadius = knobSize * 0.5
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        updateStick(with: point)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        updateStick(with: point)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetStick()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetStick()
    }

    private func updateStick(with point: CGPoint) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        var delta = CGPoint(x: point.x - center.x, y: point.y - center.y)

        let distance = sqrt(delta.x * delta.x + delta.y * delta.y)
        let maxDistance = radius * 0.65

        if distance > maxDistance, distance > 0 {
            let scale = maxDistance / distance
            delta.x *= scale
            delta.y *= scale
        }

        knobView.center = CGPoint(x: center.x + delta.x, y: center.y + delta.y)

        let x = Float(delta.x / maxDistance)
        let y = Float(delta.y / maxDistance)
        let vector = SIMD2<Float>(x, y)
        let magnitude = simd_length(vector)

        if magnitude < 0.08 {
            onVectorChanged?(.zero)
        } else {
            if magnitude > 0.9, isHapticsEnabled {
                feedback.impactOccurred(intensity: 0.65)
                feedback.prepare()
            }
            onVectorChanged?(SIMD2<Float>(x, -y))
        }
    }

    private func resetStick() {
        UIView.animate(withDuration: 0.14, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.knobView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        }
        onVectorChanged?(.zero)
    }
}
