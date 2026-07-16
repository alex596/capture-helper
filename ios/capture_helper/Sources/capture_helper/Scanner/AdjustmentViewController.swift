import UIKit

/// Protocole pour les événements de l'écran d'ajustement
@available(iOS 13.0, *)
protocol AdjustmentViewControllerDelegate: AnyObject {
    func adjustmentViewController(_ controller: AdjustmentViewController, didConfirmWithCorners corners: [CGPoint], originalImage: UIImage)
    func adjustmentViewControllerDidCancel(_ controller: AdjustmentViewController)
}

/// ViewController pour ajuster les coins du document
@available(iOS 13.0, *)
class AdjustmentViewController: UIViewController {

    weak var delegate: AdjustmentViewControllerDelegate?

    /// Image capturée
    private let capturedImage: UIImage

    /// Document détecté (optionnel)
    private let detectedDocument: DocumentDetector.DetectedDocument?

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private lazy var overlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var quadrilateralLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        layer.strokeColor = UIColor.systemBlue.cgColor
        layer.lineWidth = 2
        return layer
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Continuer", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var retakeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Reprendre", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Ajustez les coins si nécessaire"
        label.textColor = .label
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Corner Handles

    private var cornerHandles: [CornerHandle] = []
    private var activeHandle: CornerHandle?

    /// Points des coins en coordonnées de l'image (normalisés 0-1)
    private var cornerPoints: [CGPoint] = []

    // MARK: - Init

    init(image: UIImage, detectedDocument: DocumentDetector.DetectedDocument?) {
        self.capturedImage = image
        self.detectedDocument = detectedDocument
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCornerHandles()
        initializeCorners()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCornerHandlePositions()
        updateQuadrilateralPath()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(overlayView)
        view.addSubview(instructionLabel)
        view.addSubview(retakeButton)
        view.addSubview(confirmButton)

        imageView.image = capturedImage
        overlayView.layer.addSublayer(quadrilateralLayer)

        NSLayoutConstraint.activate([
            // Instruction en haut
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // ScrollView pour l'image
            scrollView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: retakeButton.topAnchor, constant: -16),

            // ImageView dans le scrollView
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            // Overlay par-dessus l'image
            overlayView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            // Boutons en bas
            retakeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            retakeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            retakeButton.heightAnchor.constraint(equalToConstant: 50),
            retakeButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4, constant: -25),

            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            confirmButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4, constant: -25)
        ])
    }

    private func setupCornerHandles() {
        let cornerNames = ["topLeft", "topRight", "bottomRight", "bottomLeft"]

        for (index, name) in cornerNames.enumerated() {
            let handle = CornerHandle()
            handle.tag = index
            handle.accessibilityLabel = name

            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            handle.addGestureRecognizer(panGesture)

            overlayView.addSubview(handle)
            cornerHandles.append(handle)
        }
    }

    private func initializeCorners() {
        if let document = detectedDocument {
            // Utiliser les coins détectés (convertir de Vision vers coordonnées normalisées UIKit)
            cornerPoints = [
                CGPoint(x: document.topLeft.x, y: 1 - document.topLeft.y),
                CGPoint(x: document.topRight.x, y: 1 - document.topRight.y),
                CGPoint(x: document.bottomRight.x, y: 1 - document.bottomRight.y),
                CGPoint(x: document.bottomLeft.x, y: 1 - document.bottomLeft.y)
            ]
        } else {
            // Valeurs par défaut (rectangle légèrement plus petit que l'image)
            let margin: CGFloat = 0.1
            cornerPoints = [
                CGPoint(x: margin, y: margin),           // topLeft
                CGPoint(x: 1 - margin, y: margin),       // topRight
                CGPoint(x: 1 - margin, y: 1 - margin),   // bottomRight
                CGPoint(x: margin, y: 1 - margin)        // bottomLeft
            ]
        }
    }

    // MARK: - Corner Handle Management

    private func updateCornerHandlePositions() {
        guard cornerPoints.count == 4 else { return }

        let imageRect = getImageRectInView()

        for (index, handle) in cornerHandles.enumerated() {
            let normalizedPoint = cornerPoints[index]
            let viewPoint = CGPoint(
                x: imageRect.origin.x + normalizedPoint.x * imageRect.width,
                y: imageRect.origin.y + normalizedPoint.y * imageRect.height
            )
            handle.center = viewPoint
        }
    }

    private func updateQuadrilateralPath() {
        guard cornerHandles.count == 4 else { return }

        let path = UIBezierPath()
        path.move(to: cornerHandles[0].center)

        for i in 1..<cornerHandles.count {
            path.addLine(to: cornerHandles[i].center)
        }
        path.close()

        quadrilateralLayer.path = path.cgPath
        quadrilateralLayer.frame = overlayView.bounds
    }

    private func getImageRectInView() -> CGRect {
        guard let image = imageView.image else {
            return overlayView.bounds
        }

        let imageSize = image.size
        let viewSize = overlayView.bounds.size

        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height

        var drawRect = CGRect.zero

        if imageAspect > viewAspect {
            // Image plus large que la vue
            drawRect.size.width = viewSize.width
            drawRect.size.height = viewSize.width / imageAspect
            drawRect.origin.x = 0
            drawRect.origin.y = (viewSize.height - drawRect.height) / 2
        } else {
            // Image plus haute que la vue
            drawRect.size.height = viewSize.height
            drawRect.size.width = viewSize.height * imageAspect
            drawRect.origin.y = 0
            drawRect.origin.x = (viewSize.width - drawRect.width) / 2
        }

        return drawRect
    }

    // MARK: - Gesture Handling

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view as? CornerHandle else { return }

        let location = gesture.location(in: overlayView)
        let imageRect = getImageRectInView()

        switch gesture.state {
        case .began:
            activeHandle = handle
            handle.setHighlighted(true)

        case .changed:
            // Contraindre le point dans les limites de l'image
            let constrainedX = max(imageRect.minX, min(imageRect.maxX, location.x))
            let constrainedY = max(imageRect.minY, min(imageRect.maxY, location.y))

            handle.center = CGPoint(x: constrainedX, y: constrainedY)

            // Mettre à jour les coordonnées normalisées
            let normalizedX = (constrainedX - imageRect.minX) / imageRect.width
            let normalizedY = (constrainedY - imageRect.minY) / imageRect.height
            cornerPoints[handle.tag] = CGPoint(x: normalizedX, y: normalizedY)

            updateQuadrilateralPath()

        case .ended, .cancelled:
            handle.setHighlighted(false)
            activeHandle = nil

        default:
            break
        }
    }

    // MARK: - Actions

    @objc private func confirmButtonTapped() {
        // Convertir les points normalisés en coordonnées de l'image originale
        let imageSize = capturedImage.size
        let imageCorners = cornerPoints.map { point in
            CGPoint(
                x: point.x * imageSize.width,
                y: point.y * imageSize.height
            )
        }

        delegate?.adjustmentViewController(self, didConfirmWithCorners: imageCorners, originalImage: capturedImage)
    }

    @objc private func retakeButtonTapped() {
        delegate?.adjustmentViewControllerDidCancel(self)
    }
}

// MARK: - UIScrollViewDelegate
@available(iOS 13.0, *)
extension AdjustmentViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

// MARK: - Corner Handle View
@available(iOS 13.0, *)
class CornerHandle: UIView {

    private let outerCircle = UIView()
    private let innerCircle = UIView()

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear

        // Cercle extérieur (zone de touch)
        outerCircle.frame = bounds
        outerCircle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        outerCircle.layer.cornerRadius = 22
        addSubview(outerCircle)

        // Cercle intérieur (indicateur visuel)
        innerCircle.frame = CGRect(x: 12, y: 12, width: 20, height: 20)
        innerCircle.backgroundColor = .systemBlue
        innerCircle.layer.cornerRadius = 10
        innerCircle.layer.borderWidth = 2
        innerCircle.layer.borderColor = UIColor.white.cgColor
        addSubview(innerCircle)
    }

    func setHighlighted(_ highlighted: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.transform = highlighted ? CGAffineTransform(scaleX: 1.3, y: 1.3) : .identity
            self.outerCircle.backgroundColor = highlighted
                ? UIColor.systemBlue.withAlphaComponent(0.5)
                : UIColor.systemBlue.withAlphaComponent(0.3)
        }
    }
}
