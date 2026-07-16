import UIKit

/// Protocole pour les événements de l'écran de feedback qualité
@available(iOS 13.0, *)
protocol QualityFeedbackViewControllerDelegate: AnyObject {
    func qualityFeedbackViewControllerDidRequestRetake(_ controller: QualityFeedbackViewController)
    func qualityFeedbackViewController(_ controller: QualityFeedbackViewController, didAcceptImage image: UIImage)
}

/// ViewController affichant le feedback de qualité et proposant de re-scanner ou conserver
@available(iOS 13.0, *)
class QualityFeedbackViewController: UIViewController {

    weak var delegate: QualityFeedbackViewControllerDelegate?

    private let capturedImage: UIImage
    private let qualityResult: ImageQualityAnalyzer.QualityResult

    // MARK: - UI Components

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()

    private lazy var feedbackContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private lazy var warningIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Qualité insuffisante"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var qualityStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        return stack
    }()

    private lazy var retakeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Reprendre", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var keepButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Conserver quand même", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(keepButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(image: UIImage, qualityResult: ImageQualityAnalyzer.QualityResult) {
        self.capturedImage = image
        self.qualityResult = qualityResult
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContent()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(imageView)
        view.addSubview(feedbackContainer)

        feedbackContainer.addSubview(warningIcon)
        feedbackContainer.addSubview(titleLabel)
        feedbackContainer.addSubview(messageLabel)
        feedbackContainer.addSubview(qualityStackView)
        feedbackContainer.addSubview(retakeButton)
        feedbackContainer.addSubview(keepButton)

        imageView.image = capturedImage

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: feedbackContainer.topAnchor, constant: 20),

            feedbackContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feedbackContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            feedbackContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            warningIcon.topAnchor.constraint(equalTo: feedbackContainer.topAnchor, constant: 24),
            warningIcon.centerXAnchor.constraint(equalTo: feedbackContainer.centerXAnchor),
            warningIcon.widthAnchor.constraint(equalToConstant: 40),
            warningIcon.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: warningIcon.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: feedbackContainer.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: feedbackContainer.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: feedbackContainer.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: feedbackContainer.trailingAnchor, constant: -20),

            qualityStackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            qualityStackView.leadingAnchor.constraint(equalTo: feedbackContainer.leadingAnchor, constant: 20),
            qualityStackView.trailingAnchor.constraint(equalTo: feedbackContainer.trailingAnchor, constant: -20),
            qualityStackView.heightAnchor.constraint(equalToConstant: 60),

            retakeButton.topAnchor.constraint(equalTo: qualityStackView.bottomAnchor, constant: 24),
            retakeButton.leadingAnchor.constraint(equalTo: feedbackContainer.leadingAnchor, constant: 20),
            retakeButton.trailingAnchor.constraint(equalTo: feedbackContainer.trailingAnchor, constant: -20),
            retakeButton.heightAnchor.constraint(equalToConstant: 50),

            keepButton.topAnchor.constraint(equalTo: retakeButton.bottomAnchor, constant: 12),
            keepButton.leadingAnchor.constraint(equalTo: feedbackContainer.leadingAnchor, constant: 20),
            keepButton.trailingAnchor.constraint(equalTo: feedbackContainer.trailingAnchor, constant: -20),
            keepButton.heightAnchor.constraint(equalToConstant: 44),
            keepButton.bottomAnchor.constraint(equalTo: feedbackContainer.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func configureContent() {
        // Message principal
        messageLabel.text = qualityResult.qualityIssue ?? "La qualité de l'image pourrait être meilleure."

        // Indicateurs de qualité
        addQualityIndicator(
            title: "Netteté",
            score: qualityResult.sharpnessScore,
            icon: "camera.metering.center.weighted"
        )

        addQualityIndicator(
            title: "Luminosité",
            score: qualityResult.brightnessScore,
            icon: "sun.max.fill"
        )

        addQualityIndicator(
            title: "Cadrage",
            score: qualityResult.documentCoverage,
            icon: "crop"
        )
    }

    private func addQualityIndicator(title: String, score: Int, icon: String) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = colorForScore(score)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center

        let scoreLabel = UILabel()
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.text = "\(score)%"
        scoreLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        scoreLabel.textColor = colorForScore(score)
        scoreLabel.textAlignment = .center

        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(scoreLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            scoreLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            scoreLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 2),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])

        qualityStackView.addArrangedSubview(container)
    }

    private func colorForScore(_ score: Int) -> UIColor {
        if score >= 70 {
            return .systemGreen
        } else if score >= 40 {
            return .systemYellow
        } else {
            return .systemRed
        }
    }

    // MARK: - Actions

    @objc private func retakeButtonTapped() {
        delegate?.qualityFeedbackViewControllerDidRequestRetake(self)
    }

    @objc private func keepButtonTapped() {
        delegate?.qualityFeedbackViewController(self, didAcceptImage: capturedImage)
    }
}
