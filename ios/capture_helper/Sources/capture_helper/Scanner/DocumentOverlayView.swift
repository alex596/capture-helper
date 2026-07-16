import UIKit

/// Vue affichant l'overlay de détection du document
@available(iOS 13.0, *)
class DocumentOverlayView: UIView {

    private let shapeLayer = CAShapeLayer()
    private let maskLayer = CAShapeLayer()

    /// Couleur de l'overlay quand un document est détecté
    var detectedColor: UIColor = UIColor.systemGreen.withAlphaComponent(0.3) {
        didSet { updateAppearance() }
    }

    /// Couleur de la bordure du document détecté
    var borderColor: UIColor = .systemGreen {
        didSet { updateAppearance() }
    }

    /// Couleur de l'overlay quand aucun document n'est détecté
    var dimColor: UIColor = UIColor.black.withAlphaComponent(0.3)

    /// Points actuels du document (en coordonnées de la vue)
    private var currentPoints: [CGPoint] = []

    /// Animation en cours
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        backgroundColor = .clear

        // Layer de masque (zone sombre autour du document)
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = dimColor.cgColor
        layer.addSublayer(maskLayer)

        // Layer de forme (bordure du document)
        shapeLayer.fillColor = detectedColor.cgColor
        shapeLayer.strokeColor = borderColor.cgColor
        shapeLayer.lineWidth = 4
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: 0)
        shapeLayer.shadowOpacity = 0.5
        shapeLayer.shadowRadius = 3
        layer.addSublayer(shapeLayer)
    }

    private func updateAppearance() {
        shapeLayer.fillColor = detectedColor.cgColor
        shapeLayer.strokeColor = borderColor.cgColor
        maskLayer.fillColor = dimColor.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = bounds
        shapeLayer.frame = bounds

        if !currentPoints.isEmpty {
            updatePath(with: currentPoints, animated: false)
        }
    }

    /// Met à jour l'overlay avec les nouveaux points du document
    func updateDocumentBounds(points: [CGPoint], animated: Bool = true) {
        guard points.count == 4 else {
            hideOverlay(animated: animated)
            return
        }

        currentPoints = points
        updatePath(with: points, animated: animated)
    }

    /// Cache l'overlay (aucun document détecté)
    func hideOverlay(animated: Bool = true) {
        currentPoints = []

        let duration = animated ? 0.2 : 0

        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)

        // Masque couvrant tout l'écran
        let fullPath = UIBezierPath(rect: bounds)
        maskLayer.path = fullPath.cgPath

        // Pas de forme de document
        shapeLayer.path = nil

        CATransaction.commit()
    }

    private func updatePath(with points: [CGPoint], animated: Bool) {
        guard points.count == 4 else { return }

        // Créer le path du document
        let documentPath = UIBezierPath()
        documentPath.move(to: points[0])
        for i in 1..<points.count {
            documentPath.addLine(to: points[i])
        }
        documentPath.close()

        // Créer le masque (tout sauf le document)
        let fullPath = UIBezierPath(rect: bounds)
        fullPath.append(documentPath)

        let duration = animated ? 0.15 : 0

        if animated {
            // Animation fluide
            let pathAnimation = CABasicAnimation(keyPath: "path")
            pathAnimation.duration = duration
            pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            shapeLayer.add(pathAnimation, forKey: "pathAnimation")
            maskLayer.add(pathAnimation, forKey: "pathAnimation")
        }

        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        shapeLayer.path = documentPath.cgPath
        maskLayer.path = fullPath.cgPath
        CATransaction.commit()
    }

    /// Affiche un feedback visuel de capture
    func showCaptureFlash() {
        let flashView = UIView(frame: bounds)
        flashView.backgroundColor = .white
        flashView.alpha = 0
        addSubview(flashView)

        UIView.animate(withDuration: 0.1, animations: {
            flashView.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.2, animations: {
                flashView.alpha = 0
            }) { _ in
                flashView.removeFromSuperview()
            }
        }
    }
}
