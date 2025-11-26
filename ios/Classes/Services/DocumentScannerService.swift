import UIKit
import VisionKit

/// Service gérant la numérisation de documents via VisionKit
@available(iOS 13.0, *)
class DocumentScannerService: NSObject {
    private weak var presentingViewController: UIViewController?
    private var scanCompletion: ((Result<[URL], Error>) -> Void)?
    private var outputFormat: String = "jpeg"

    enum ScanError: Error {
        case notAvailable
        case cancelled
        case noImagesScanned
        case presentationFailed

        var localizedDescription: String {
            switch self {
            case .notAvailable:
                return "Document scanning not supported on this device"
            case .cancelled:
                return "User cancelled document scanning"
            case .noImagesScanned:
                return "No images were scanned"
            case .presentationFailed:
                return "Failed to present scanner"
            }
        }
    }

    init(presentingViewController: UIViewController?, outputFormat: String = "jpeg") {
        self.presentingViewController = presentingViewController
        self.outputFormat = outputFormat
        super.init()
    }

    /// Vérifie si VisionKit est disponible
    static func isScanningAvailable() -> Bool {
        if #available(iOS 13.0, *) {
            return VNDocumentCameraViewController.isSupported
        }
        return false
    }

    /// Lance la numérisation de documents
    func scanDocument(completion: @escaping (Result<[URL], Error>) -> Void) {
        guard Self.isScanningAvailable() else {
            completion(.failure(ScanError.notAvailable))
            return
        }

        guard let viewController = presentingViewController else {
            completion(.failure(ScanError.presentationFailed))
            return
        }

        scanCompletion = completion

        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self

        DispatchQueue.main.async {
            viewController.present(scanner, animated: true)
        }
    }

    /// Sauvegarde une image VNDocumentCameraScan dans un fichier temporaire
    private func saveImage(_ image: UIImage, index: Int) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)

        // Déterminer l'extension et les données selon le format
        let (fileExtension, imageData): (String, Data?)

        if outputFormat == "png" {
            fileExtension = "png"
            imageData = image.pngData()
        } else {
            fileExtension = "jpg"
            imageData = image.jpegData(compressionQuality: 1.0)
        }

        let filename = "scan_\(timestamp)_\(index).\(fileExtension)"
        let fileURL = tempDirectory.appendingPathComponent(filename)

        guard let data = imageData else {
            return nil
        }

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate
@available(iOS 13.0, *)
extension DocumentScannerService: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            var imageURLs: [URL] = []

            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                if let url = self.saveImage(image, index: i) {
                    imageURLs.append(url)
                }
            }

            if imageURLs.isEmpty {
                self.scanCompletion?(.failure(ScanError.noImagesScanned))
            } else {
                self.scanCompletion?(.success(imageURLs))
            }

            self.scanCompletion = nil
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.scanCompletion?(.failure(ScanError.cancelled))
            self?.scanCompletion = nil
        }
    }

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFailWithError error: Error
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.scanCompletion?(.failure(error))
            self?.scanCompletion = nil
        }
    }
}
