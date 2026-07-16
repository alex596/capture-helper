import UIKit

/// Protocole pour les événements de l'écran de preview finale
@available(iOS 13.0, *)
protocol PreviewViewControllerDelegate: AnyObject {
    func previewViewController(_ controller: PreviewViewController, didConfirmImage image: UIImage)
    func previewViewControllerDidRequestRetake(_ controller: PreviewViewController)
}

/// ViewController pour la preview finale avec options "Utiliser" / "Reprendre"
@available(iOS 13.0, *)
class PreviewViewController: UIViewController {

    weak var delegate: PreviewViewControllerDelegate?

    /// Image corrigée à afficher
    private let correctedImage: UIImage

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black
        return scrollView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()

    private lazy var bottomBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        return view
    }()

    private lazy var retakeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Reprendre", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var useButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Utiliser", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(useButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Aperçu"
        label.textColor = .label
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 13)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    init(correctedImage: UIImage) {
        self.correctedImage = correctedImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateImageInfo()
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(bottomBar)
        bottomBar.addSubview(retakeButton)
        bottomBar.addSubview(useButton)
        bottomBar.addSubview(titleLabel)
        bottomBar.addSubview(infoLabel)

        imageView.image = correctedImage

        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            // ImageView dans le scrollView
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            // Bottom bar
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Title
            titleLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),

            // Info label
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            infoLabel.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            infoLabel.leadingAnchor.constraint(greaterThanOrEqualTo: bottomBar.leadingAnchor, constant: 60),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: bottomBar.trailingAnchor, constant: -60),

            // Boutons
            retakeButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            retakeButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 16),
            retakeButton.bottomAnchor.constraint(equalTo: bottomBar.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            retakeButton.heightAnchor.constraint(equalToConstant: 44),

            useButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            useButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 16),
            useButton.bottomAnchor.constraint(equalTo: bottomBar.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            useButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Ajouter un double-tap pour zoomer
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
    }

    private func updateImageInfo() {
        let width = Int(correctedImage.size.width)
        let height = Int(correctedImage.size.height)
        infoLabel.text = "\(width) x \(height) pixels"
    }

    // MARK: - Actions

    @objc private func retakeButtonTapped() {
        delegate?.previewViewControllerDidRequestRetake(self)
    }

    @objc private func useButtonTapped() {
        delegate?.previewViewController(self, didConfirmImage: correctedImage)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            let zoomRect = CGRect(
                x: location.x - 50,
                y: location.y - 50,
                width: 100,
                height: 100
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate
@available(iOS 13.0, *)
extension PreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
