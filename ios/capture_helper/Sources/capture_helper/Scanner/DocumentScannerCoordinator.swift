import UIKit

/// Résultat final du scan
@available(iOS 13.0, *)
struct DocumentScanResult {
    let imageURLs: [URL]
    let success: Bool
    let errorMessage: String?

    static func success(urls: [URL]) -> DocumentScanResult {
        return DocumentScanResult(imageURLs: urls, success: true, errorMessage: nil)
    }

    static func failure(message: String) -> DocumentScanResult {
        return DocumentScanResult(imageURLs: [], success: false, errorMessage: message)
    }

    static func cancelled() -> DocumentScanResult {
        return DocumentScanResult(imageURLs: [], success: false, errorMessage: "Scan annulé par l'utilisateur")
    }
}

/// Coordinateur principal gérant le flow complet de scan
@available(iOS 13.0, *)
class DocumentScannerCoordinator: NSObject {

    // MARK: - Properties

    private weak var presentingViewController: UIViewController?
    private var completion: ((DocumentScanResult) -> Void)?

    private var navigationController: UINavigationController?
    private let perspectiveCorrector = PerspectiveCorrector()

    private var sessionManager: ScanSessionManager!
    private var rescanIndex: Int? = nil

    // MARK: - Init

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        super.init()
    }

    // MARK: - Public Methods

    /// Démarre le flow de scan avec les options données
    func startScanning(with options: ScanOptions, completion: @escaping (DocumentScanResult) -> Void) {
        self.completion = completion
        self.sessionManager = ScanSessionManager(options: options)
        self.rescanIndex = nil

        showCaptureScreen()
    }

    // MARK: - Navigation

    private func showCaptureScreen() {
        let captureVC = CaptureViewController()
        captureVC.delegate = self
        captureVC.configuration = sessionManager.captureConfiguration
        captureVC.currentPageNumber = sessionManager.nextPageNumber
        captureVC.totalPages = sessionManager.pageLimit

        if rescanIndex != nil {
            // Mode re-scan : page spécifique
            captureVC.currentPageNumber = (rescanIndex ?? 0) + 1
        }

        if navigationController == nil {
            navigationController = UINavigationController(rootViewController: captureVC)
            navigationController?.modalPresentationStyle = .fullScreen
            navigationController?.isNavigationBarHidden = true

            presentingViewController?.present(navigationController!, animated: true)
        } else {
            navigationController?.isNavigationBarHidden = true
            navigationController?.pushViewController(captureVC, animated: true)
        }
    }

    private func showAdjustmentScreen(image: UIImage, detectedDocument: DocumentDetector.DetectedDocument?, quality: ImageQualityAnalyzer.QualityResult) {
        let adjustmentVC = AdjustmentViewController(image: image, detectedDocument: detectedDocument)
        adjustmentVC.delegate = self

        // Stocker la qualité pour utilisation ultérieure
        adjustmentVC.associatedQuality = quality

        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.pushViewController(adjustmentVC, animated: true)
    }

    private func showQualityFeedback(image: UIImage, quality: ImageQualityAnalyzer.QualityResult) {
        let feedbackVC = QualityFeedbackViewController(image: image, qualityResult: quality)
        feedbackVC.delegate = self

        navigationController?.isNavigationBarHidden = true
        navigationController?.pushViewController(feedbackVC, animated: true)
    }

    private func showPreviewScreen(correctedImage: UIImage, quality: ImageQualityAnalyzer.QualityResult) {
        // Si mode single-page, afficher le preview classique
        if sessionManager.isSinglePageMode {
            let previewVC = PreviewViewController(correctedImage: correctedImage)
            previewVC.delegate = self
            previewVC.associatedQuality = quality

            navigationController?.pushViewController(previewVC, animated: true)
        } else {
            // Mode multi-pages : ajouter la page et afficher le récap
            if let index = rescanIndex {
                sessionManager.replacePage(at: index, image: correctedImage, quality: quality)
                rescanIndex = nil
            } else {
                sessionManager.addPage(image: correctedImage, quality: quality)
            }

            showRecapScreen()
        }
    }

    private func showRecapScreen() {
        // Vérifier si un RecapViewController existe déjà dans la stack
        if let existingRecap = navigationController?.viewControllers.first(where: { $0 is RecapViewController }) as? RecapViewController {
            existingRecap.updatePages(sessionManager.pages)
            navigationController?.popToViewController(existingRecap, animated: true)
        } else {
            let recapVC = RecapViewController(pages: sessionManager.pages, pageLimit: sessionManager.pageLimit)
            recapVC.delegate = self

            navigationController?.isNavigationBarHidden = false
            navigationController?.pushViewController(recapVC, animated: true)
        }
    }

    // MARK: - Image Processing

    private func processAndCorrectImage(image: UIImage, corners: [CGPoint]) -> UIImage? {
        guard corners.count == 4 else { return nil }

        return perspectiveCorrector.correctPerspective(
            image: image,
            topLeft: corners[0],
            topRight: corners[1],
            bottomLeft: corners[3],
            bottomRight: corners[2]
        )
    }

    // MARK: - Finish Methods

    private func finishWithSuccess() {
        let urls = sessionManager.exportPages()

        navigationController?.dismiss(animated: true) { [weak self] in
            self?.completion?(DocumentScanResult.success(urls: urls))
            self?.cleanup()
        }
    }

    private func finishWithCancel() {
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.completion?(DocumentScanResult.cancelled())
            self?.cleanup()
        }
    }

    private func finishWithError(_ message: String) {
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.completion?(DocumentScanResult.failure(message: message))
            self?.cleanup()
        }
    }

    private func cleanup() {
        navigationController = nil
        completion = nil
        sessionManager = nil
        rescanIndex = nil
    }

    private func restartCapture() {
        // Retirer les écrans jusqu'à la capture ou en créer un nouveau
        if let captureVC = navigationController?.viewControllers.first(where: { $0 is CaptureViewController }) {
            navigationController?.popToViewController(captureVC, animated: true)
        } else {
            showCaptureScreen()
        }
    }
}

// MARK: - CaptureViewControllerDelegate
@available(iOS 13.0, *)
extension DocumentScannerCoordinator: CaptureViewControllerDelegate {

    func captureViewController(_ controller: CaptureViewController, didCaptureImage image: UIImage, withDocument document: DocumentDetector.DetectedDocument?, quality: ImageQualityAnalyzer.QualityResult) {

        // Vérifier la qualité si les seuils sont configurés
        let hasQualityThresholds = sessionManager.captureConfiguration.minSharpness > 0 ||
                                   sessionManager.captureConfiguration.minBrightness > 0

        if hasQualityThresholds && !quality.isAcceptable {
            // Afficher l'écran de feedback qualité
            showQualityFeedback(image: image, quality: quality)
        } else {
            // Passer à l'ajustement des coins
            showAdjustmentScreen(image: image, detectedDocument: document, quality: quality)
        }
    }

    func captureViewControllerDidCancel(_ controller: CaptureViewController) {
        // En mode multi-pages avec des pages déjà scannées, revenir au récap
        if sessionManager.isMultiPageMode && sessionManager.pageCount > 0 {
            rescanIndex = nil
            showRecapScreen()
        } else {
            finishWithCancel()
        }
    }
}

// MARK: - QualityFeedbackViewControllerDelegate
@available(iOS 13.0, *)
extension DocumentScannerCoordinator: QualityFeedbackViewControllerDelegate {

    func qualityFeedbackViewControllerDidRequestRetake(_ controller: QualityFeedbackViewController) {
        // Revenir à la capture
        restartCapture()
    }

    func qualityFeedbackViewController(_ controller: QualityFeedbackViewController, didAcceptImage image: UIImage) {
        // L'utilisateur accepte malgré la qualité insuffisante
        // Re-analyser la qualité pour avoir les scores
        let analyzer = ImageQualityAnalyzer(thresholds: .disabled)
        let quality = analyzer.analyzeQuality(of: image)

        showAdjustmentScreen(image: image, detectedDocument: nil, quality: quality)
    }
}

// MARK: - AdjustmentViewControllerDelegate
@available(iOS 13.0, *)
extension DocumentScannerCoordinator: AdjustmentViewControllerDelegate {

    func adjustmentViewController(_ controller: AdjustmentViewController, didConfirmWithCorners corners: [CGPoint], originalImage: UIImage) {
        let quality = controller.associatedQuality ?? ImageQualityAnalyzer.QualityResult.evaluate(
            sharpness: 50, brightness: 50, coverage: 50,
            minSharpness: 0, minBrightness: 0, minCoverage: 0
        )

        if let correctedImage = processAndCorrectImage(image: originalImage, corners: corners) {
            showPreviewScreen(correctedImage: correctedImage, quality: quality)
        } else {
            // Si la correction échoue, utiliser l'image originale
            showPreviewScreen(correctedImage: originalImage, quality: quality)
        }
    }

    func adjustmentViewControllerDidCancel(_ controller: AdjustmentViewController) {
        restartCapture()
    }
}

// MARK: - PreviewViewControllerDelegate
@available(iOS 13.0, *)
extension DocumentScannerCoordinator: PreviewViewControllerDelegate {

    func previewViewController(_ controller: PreviewViewController, didConfirmImage image: UIImage) {
        let quality = controller.associatedQuality ?? ImageQualityAnalyzer.QualityResult.evaluate(
            sharpness: 50, brightness: 50, coverage: 50,
            minSharpness: 0, minBrightness: 0, minCoverage: 0
        )

        if sessionManager.isSinglePageMode {
            // Mode single-page : sauvegarder et terminer
            sessionManager.addPage(image: image, quality: quality)
            finishWithSuccess()
        } else {
            // Mode multi-pages : ajouter et afficher récap
            if let index = rescanIndex {
                sessionManager.replacePage(at: index, image: image, quality: quality)
                rescanIndex = nil
            } else {
                sessionManager.addPage(image: image, quality: quality)
            }
            showRecapScreen()
        }
    }

    func previewViewControllerDidRequestRetake(_ controller: PreviewViewController) {
        restartCapture()
    }
}

// MARK: - RecapViewControllerDelegate
@available(iOS 13.0, *)
extension DocumentScannerCoordinator: RecapViewControllerDelegate {

    func recapViewController(_ controller: RecapViewController, didConfirmPages pages: [ScannedPage]) {
        finishWithSuccess()
    }

    func recapViewControllerDidRequestAddPage(_ controller: RecapViewController) {
        rescanIndex = nil
        showCaptureScreen()
    }

    func recapViewController(_ controller: RecapViewController, didRequestRescanPageAt index: Int) {
        rescanIndex = index
        showCaptureScreen()
    }

    func recapViewControllerDidCancel(_ controller: RecapViewController) {
        finishWithCancel()
    }
}

// MARK: - Extensions pour stocker la qualité
@available(iOS 13.0, *)
extension AdjustmentViewController {
    private struct AssociatedKeys {
        static var quality = "associatedQuality"
    }

    var associatedQuality: ImageQualityAnalyzer.QualityResult? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.quality) as? ImageQualityAnalyzer.QualityResult
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.quality, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

@available(iOS 13.0, *)
extension PreviewViewController {
    private struct AssociatedKeys {
        static var quality = "associatedQuality"
    }

    var associatedQuality: ImageQualityAnalyzer.QualityResult? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.quality) as? ImageQualityAnalyzer.QualityResult
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.quality, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
