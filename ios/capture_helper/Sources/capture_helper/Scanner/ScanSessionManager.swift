import UIKit

/// Représente une page scannée
@available(iOS 13.0, *)
struct ScannedPage {
    let image: UIImage
    let quality: ImageQualityAnalyzer.QualityResult
    let timestamp: Date

    init(image: UIImage, quality: ImageQualityAnalyzer.QualityResult) {
        self.image = image
        self.quality = quality
        self.timestamp = Date()
    }
}

/// Gestionnaire de session de scan multi-pages
@available(iOS 13.0, *)
class ScanSessionManager {

    // MARK: - Properties

    /// Pages scannées dans la session
    private(set) var pages: [ScannedPage] = []

    /// Limite de pages (0 = illimité)
    let pageLimit: Int

    /// Mode de capture
    let captureMode: CaptureMode

    /// Format de sortie
    let outputFormat: String

    /// Configuration de capture
    let captureConfiguration: CaptureConfiguration

    // MARK: - Computed Properties

    /// Nombre de pages actuellement scannées
    var pageCount: Int {
        return pages.count
    }

    /// Vérifie si la limite de pages est atteinte
    var isLimitReached: Bool {
        guard pageLimit > 0 else { return false }
        return pages.count >= pageLimit
    }

    /// Numéro de la prochaine page
    var nextPageNumber: Int {
        return pages.count + 1
    }

    /// Vérifie si le mode est single-page
    var isSinglePageMode: Bool {
        return pageLimit == 1
    }

    /// Vérifie si c'est un mode multi-pages
    var isMultiPageMode: Bool {
        return pageLimit != 1
    }

    // MARK: - Init

    init(pageLimit: Int, captureMode: CaptureMode, outputFormat: String, captureConfiguration: CaptureConfiguration) {
        self.pageLimit = pageLimit
        self.captureMode = captureMode
        self.outputFormat = outputFormat
        self.captureConfiguration = captureConfiguration
    }

    /// Crée un manager depuis les options Pigeon
    convenience init(options: ScanOptions) {
        let mode: CaptureMode = options.scanMode == .auto ? .auto : .manual

        var config = CaptureConfiguration()
        config.mode = mode
        config.autoCaptureDelay = options.autoCaptureDelay
        config.minSharpness = Int(options.minSharpnessScore)
        config.minBrightness = Int(options.minBrightnessScore)
        config.minDocumentCoverage = Int(options.minDocumentCoverage)

        self.init(
            pageLimit: Int(options.pageLimit),
            captureMode: mode,
            outputFormat: options.outputFormat,
            captureConfiguration: config
        )
    }

    // MARK: - Page Management

    /// Ajoute une page à la session
    func addPage(_ page: ScannedPage) {
        pages.append(page)
    }

    /// Ajoute une page depuis une image et un résultat de qualité
    func addPage(image: UIImage, quality: ImageQualityAnalyzer.QualityResult) {
        let page = ScannedPage(image: image, quality: quality)
        pages.append(page)
    }

    /// Supprime une page à l'index donné
    func removePage(at index: Int) {
        guard index >= 0 && index < pages.count else { return }
        pages.remove(at: index)
    }

    /// Remplace une page à l'index donné
    func replacePage(at index: Int, with page: ScannedPage) {
        guard index >= 0 && index < pages.count else { return }
        pages[index] = page
    }

    /// Remplace une page à l'index donné avec une image et qualité
    func replacePage(at index: Int, image: UIImage, quality: ImageQualityAnalyzer.QualityResult) {
        let page = ScannedPage(image: image, quality: quality)
        replacePage(at: index, with: page)
    }

    /// Réinitialise la session
    func reset() {
        pages.removeAll()
    }

    /// Récupère une page à l'index donné
    func page(at index: Int) -> ScannedPage? {
        guard index >= 0 && index < pages.count else { return nil }
        return pages[index]
    }

    // MARK: - Export

    /// Exporte toutes les pages vers des fichiers temporaires
    func exportPages() -> [URL] {
        var urls: [URL] = []
        let tempDirectory = FileManager.default.temporaryDirectory
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)

        for (index, page) in pages.enumerated() {
            let fileExtension: String
            let imageData: Data?

            if outputFormat == "png" {
                fileExtension = "png"
                imageData = page.image.pngData()
            } else {
                fileExtension = "jpg"
                imageData = page.image.jpegData(compressionQuality: 1.0)
            }

            let filename = "scan_\(timestamp)_\(index).\(fileExtension)"
            let fileURL = tempDirectory.appendingPathComponent(filename)

            if let data = imageData {
                do {
                    try data.write(to: fileURL)
                    urls.append(fileURL)
                } catch {
                    print("Erreur sauvegarde page \(index): \(error)")
                }
            }
        }

        return urls
    }

    /// Génère des miniatures pour toutes les pages
    func generateThumbnails(size: CGSize = CGSize(width: 80, height: 100)) -> [UIImage] {
        return pages.map { page in
            return generateThumbnail(for: page.image, size: size)
        }
    }

    private func generateThumbnail(for image: UIImage, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let aspectRatio = image.size.width / image.size.height
            let targetRatio = size.width / size.height

            var drawRect: CGRect
            if aspectRatio > targetRatio {
                // Image plus large - ajuster la hauteur
                let height = size.width / aspectRatio
                drawRect = CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
            } else {
                // Image plus haute - ajuster la largeur
                let width = size.height * aspectRatio
                drawRect = CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
            }

            image.draw(in: drawRect)
        }
    }
}
