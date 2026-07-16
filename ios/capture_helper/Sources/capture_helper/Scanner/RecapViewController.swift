import UIKit

/// Protocole pour les événements du récapitulatif
@available(iOS 13.0, *)
protocol RecapViewControllerDelegate: AnyObject {
    /// L'utilisateur a validé les pages
    func recapViewController(_ controller: RecapViewController, didConfirmPages pages: [ScannedPage])

    /// L'utilisateur veut ajouter une nouvelle page
    func recapViewControllerDidRequestAddPage(_ controller: RecapViewController)

    /// L'utilisateur veut re-scanner une page spécifique
    func recapViewController(_ controller: RecapViewController, didRequestRescanPageAt index: Int)

    /// L'utilisateur a annulé
    func recapViewControllerDidCancel(_ controller: RecapViewController)
}

/// ViewController affichant le récapitulatif des pages scannées
@available(iOS 13.0, *)
class RecapViewController: UIViewController {

    weak var delegate: RecapViewControllerDelegate?

    private var pages: [ScannedPage]
    private let pageLimit: Int
    private let thumbnailSize = CGSize(width: 80, height: 100)

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Documents scannés"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private lazy var pageCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(PageThumbnailCell.self, forCellWithReuseIdentifier: "PageCell")
        cv.register(AddPageCell.self, forCellWithReuseIdentifier: "AddCell")
        return cv
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Ajouter une page", for: .normal)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Valider", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Annuler", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "doc.text.viewfinder")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Aucun document scanné"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center

        view.addSubview(imageView)
        view.addSubview(label)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        return view
    }()

    // MARK: - Init

    init(pages: [ScannedPage], pageLimit: Int) {
        self.pages = pages
        self.pageLimit = pageLimit
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }

    // MARK: - Public Methods

    /// Met à jour les pages affichées
    func updatePages(_ newPages: [ScannedPage]) {
        self.pages = newPages
        collectionView.reloadData()
        updateUI()
    }

    /// Ajoute une page
    func addPage(_ page: ScannedPage) {
        pages.append(page)
        collectionView.reloadData()
        updateUI()

        // Scroll vers la nouvelle page
        let indexPath = IndexPath(item: pages.count - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    /// Remplace une page à l'index donné
    func replacePage(at index: Int, with page: ScannedPage) {
        guard index >= 0 && index < pages.count else { return }
        pages[index] = page
        collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground

        navigationItem.title = "Récapitulatif"
        navigationItem.hidesBackButton = true

        view.addSubview(titleLabel)
        view.addSubview(pageCountLabel)
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(addButton)
        view.addSubview(confirmButton)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            pageCountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            pageCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pageCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            collectionView.topAnchor.constraint(equalTo: pageCountLabel.bottomAnchor, constant: 30),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 160),

            emptyStateView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),

            addButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 20),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -12),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),

            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func updateUI() {
        let count = pages.count

        if pageLimit > 0 {
            pageCountLabel.text = "\(count) / \(pageLimit) page\(count > 1 ? "s" : "")"
        } else {
            pageCountLabel.text = "\(count) page\(count > 1 ? "s" : "")"
        }

        emptyStateView.isHidden = count > 0
        collectionView.isHidden = count == 0

        // Masquer le bouton d'ajout si limite atteinte
        let limitReached = pageLimit > 0 && count >= pageLimit
        addButton.isHidden = limitReached

        // Désactiver la validation si aucune page
        confirmButton.isEnabled = count > 0
        confirmButton.alpha = count > 0 ? 1.0 : 0.5
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        delegate?.recapViewControllerDidRequestAddPage(self)
    }

    @objc private func confirmButtonTapped() {
        delegate?.recapViewController(self, didConfirmPages: pages)
    }

    @objc private func cancelButtonTapped() {
        showCancelConfirmation()
    }

    private func showCancelConfirmation() {
        if pages.isEmpty {
            delegate?.recapViewControllerDidCancel(self)
            return
        }

        let alert = UIAlertController(
            title: "Annuler le scan ?",
            message: "Les \(pages.count) page(s) scannée(s) seront perdues.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Continuer", style: .cancel))
        alert.addAction(UIAlertAction(title: "Annuler le scan", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.recapViewControllerDidCancel(self)
        })

        present(alert, animated: true)
    }

    private func showPageOptions(at index: Int) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Re-scanner", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.recapViewController(self, didRequestRescanPageAt: index)
        })

        alert.addAction(UIAlertAction(title: "Supprimer", style: .destructive) { [weak self] _ in
            self?.deletePage(at: index)
        })

        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))

        if let popover = alert.popoverPresentationController {
            let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
            popover.sourceView = cell
            popover.sourceRect = cell?.bounds ?? .zero
        }

        present(alert, animated: true)
    }

    private func deletePage(at index: Int) {
        pages.remove(at: index)
        collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        updateUI()
    }
}

// MARK: - UICollectionViewDataSource
@available(iOS 13.0, *)
extension RecapViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PageCell", for: indexPath) as! PageThumbnailCell
        let page = pages[indexPath.item]
        cell.configure(with: page.image, pageNumber: indexPath.item + 1, quality: page.quality)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
@available(iOS 13.0, *)
extension RecapViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showPageOptions(at: indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
@available(iOS 13.0, *)
extension RecapViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 140)
    }
}

// MARK: - PageThumbnailCell

@available(iOS 13.0, *)
class PageThumbnailCell: UICollectionViewCell {

    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor.separator.cgColor
        return iv
    }()

    private lazy var pageNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()

    private lazy var qualityIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(pageNumberLabel)
        contentView.addSubview(qualityIndicator)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 120),

            pageNumberLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 4),
            pageNumberLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 4),
            pageNumberLabel.widthAnchor.constraint(equalToConstant: 20),
            pageNumberLabel.heightAnchor.constraint(equalToConstant: 20),

            qualityIndicator.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -4),
            qualityIndicator.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -4),
            qualityIndicator.widthAnchor.constraint(equalToConstant: 10),
            qualityIndicator.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    func configure(with image: UIImage, pageNumber: Int, quality: ImageQualityAnalyzer.QualityResult) {
        imageView.image = image
        pageNumberLabel.text = "\(pageNumber)"

        if quality.isAcceptable {
            qualityIndicator.backgroundColor = .systemGreen
        } else {
            qualityIndicator.backgroundColor = .systemYellow
        }
    }
}

// MARK: - AddPageCell

@available(iOS 13.0, *)
class AddPageCell: UICollectionViewCell {

    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemGray4.cgColor
        view.layer.borderStyle = .none
        return view
    }()

    private lazy var plusIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "plus")
        iv.tintColor = .systemGray2
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Ajouter"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(plusIcon)
        containerView.addSubview(label)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 120),

            plusIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            plusIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -10),
            plusIcon.widthAnchor.constraint(equalToConstant: 30),
            plusIcon.heightAnchor.constraint(equalToConstant: 30),

            label.topAnchor.constraint(equalTo: plusIcon.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }
}

// Extension for dashed border
extension CALayer {
    var borderStyle: CAShapeLayer.LineStyle {
        get { return .none }
        set {
            if newValue == .dashed {
                let shapeLayer = CAShapeLayer()
                shapeLayer.strokeColor = borderColor
                shapeLayer.fillColor = UIColor.clear.cgColor
                shapeLayer.lineWidth = borderWidth
                shapeLayer.lineDashPattern = [6, 3]
                shapeLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
                addSublayer(shapeLayer)
                borderWidth = 0
            }
        }
    }
}

extension CAShapeLayer {
    enum LineStyle {
        case none
        case dashed
    }
}
