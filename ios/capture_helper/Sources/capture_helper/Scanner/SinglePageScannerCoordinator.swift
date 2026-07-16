import UIKit

/// Résultat du scan single page
@available(iOS 13.0, *)
struct SinglePageScanResult {
    let image: UIImage
    let outputURL: URL
}

/// Coordinateur gérant le flow complet de capture single page
@available(iOS 13.0, *)
class SinglePageScannerCoordinator: NSObject {

    // MARK: - Types

    enum ScanError: Error, Equatable {
        case cancelled
        case captureError(String)
        case processingError(String)
        case savingError(String)

        var localizedDescription: String {
            switch self {
            case .cancelled:
                return "Scan annulé par l'utilisateur"
            case .captureError(let message):
                return "Erreur de capture: \(message)"
            case .processingError(let message):
                return "Erreur de traitement: \(message)"
            case .savingError(let message):
                return "Erreur de sauvegarde: \(message)"
            }
        }
    }

    // MARK: - Properties

    private weak var presentingViewController: UIViewController?
    private var completion: ((Result<SinglePageScanResult, Error>) -> Void)?

    private var navigationController: UINavigationController?
    private let perspectiveCorrector = PerspectiveCorrector()

    /// Format de sortie (jpeg ou png)
    var outputFormat: String = "jpeg"

    // MARK: - Init

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        super.init()
    }

    // MARK: - Public Methods

    /// Démarre le flow de scan single page
    func startScanning(completion: @escaping (Result<SinglePageScanResult, Error>) -> Void) {
        self.completion = completion

        let captureVC = CaptureViewController()
        captureVC.delegate = self

        navigationController = UINavigationController(rootViewController: captureVC)
        navigationController?.modalPresentationStyle = .fullScreen
        navigationController?.isNavigationBarHidden = true

        presentingViewController?.present(navigationController!, animated: true)
    }

    // MARK: - Private Methods

    private func showAdjustmentScreen(image: UIImage, detectedDocument: DocumentDetector.DetectedDocument?) {
        let adjustmentVC = AdjustmentViewController(image: image, detectedDocument: detectedDocument)
        adjustmentVC.delegate = self

        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.pushViewController(adjustmentVC, animated: true)
    }

    private func showPreviewScreen(correctedImage: UIImage) {
        let previewVC = PreviewViewController(correctedImage: correctedImage)
        previewVC.delegate = self

        navigationController?.pushViewController(previewVC, animated: true)
    }

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

    private func saveImage(_ image: UIImage) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)

        let fileExtension: String
        let imageData: Data?

        if outputFormat == "png" {
            fileExtension = "png"
            imageData = image.pngData()
        } else {
            fileExtension = "jpg"
            imageData = image.jpegData(compressionQuality: 1.0)
        }

        let filename = "scan_\(timestamp)_0.\(fileExtension)"
        let fileURL = tempDirectory.appendingPathComponent(filename)

        guard let data = imageData else { return nil }

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Erreur sauvegarde image: \(error)")
            return nil
        }
    }

    private func finishWithSuccess(image: UIImage) {
        guard let url = saveImage(image) else {
            finishWithError(.savingError("Impossible de sauvegarder l'image"))
            return
        }

        let result = SinglePageScanResult(image: image, outputURL: url)

        navigationController?.dismiss(animated: true) { [weak self] in
            self?.completion?(.success(result))
            self?.cleanup()
        }
    }

    private func finishWithError(_ error: ScanError) {
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.completion?(.failure(error))
            self?.cleanup()
        }
    }

    private func finishWithCancel() {
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.completion?(.failure(ScanError.cancelled))
            self?.cleanup()
        }
    }

    private func cleanup() {
        navigationController = nil
        completion = nil
    }

    private func restartCapture() {
        // Revenir à l'écran de capture
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - CaptureViewControllerDelegate
@available(iOS 13.0, *)
extension SinglePageScannerCoordinator: CaptureViewControllerDelegate {

    func captureViewController(_ controller: CaptureViewController, didCaptureImage image: UIImage, withDocument document: DocumentDetector.DetectedDocument?, quality: ImageQualityAnalyzer.QualityResult) {
        showAdjustmentScreen(image: image, detectedDocument: document)
    }

    func captureViewControllerDidCancel(_ controller: CaptureViewController) {
        finishWithCancel()
    }
}

// MARK: - AdjustmentViewControllerDelegate
@available(iOS 13.0, *)
extension SinglePageScannerCoordinator: AdjustmentViewControllerDelegate {

    func adjustmentViewController(_ controller: AdjustmentViewController, didConfirmWithCorners corners: [CGPoint], originalImage: UIImage) {
        // Appliquer la correction de perspective
        if let correctedImage = processAndCorrectImage(image: originalImage, corners: corners) {
            showPreviewScreen(correctedImage: correctedImage)
        } else {
            // Si la correction échoue, utiliser l'image originale
            showPreviewScreen(correctedImage: originalImage)
        }
    }

    func adjustmentViewControllerDidCancel(_ controller: AdjustmentViewController) {
        restartCapture()
    }
}

// MARK: - PreviewViewControllerDelegate
@available(iOS 13.0, *)
extension SinglePageScannerCoordinator: PreviewViewControllerDelegate {

    func previewViewController(_ controller: PreviewViewController, didConfirmImage image: UIImage) {
        finishWithSuccess(image: image)
    }

    func previewViewControllerDidRequestRetake(_ controller: PreviewViewController) {
        restartCapture()
    }
}
