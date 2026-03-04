import UIKit
import simd

final class VirtualDPad: UIView {
    var onVectorChanged: ((SIMD2<Float>) -> Void)?

    private let baseView = UIView()
    private let knobView = UIView()

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

        baseView.backgroundColor = UIColor(white: 0.15, alpha: 0.55)
        baseView.layer.borderColor = UIColor(white: 1, alpha: 0.35).cgColor
        baseView.layer.borderWidth = 2
        addSubview(baseView)

        knobView.backgroundColor = UIColor(white: 1, alpha: 0.75)
        addSubview(knobView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        baseView.frame = bounds
        baseView.layer.cornerRadius = radius

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
            onVectorChanged?(SIMD2<Float>(x, -y))
        }
    }

    private func resetStick() {
        knobView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        onVectorChanged?(.zero)
    }
}
