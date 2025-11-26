import Flutter
import UIKit

public class CaptureHelperPlugin: NSObject, FlutterPlugin, DocumentScannerApi {
    private var scannerService: DocumentScannerService?
    private let imageCompressionService = ImageCompressionService()
    private let pdfCompressionService = PDFCompressionService()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = CaptureHelperPlugin()
        DocumentScannerApiSetup.setUp(binaryMessenger: registrar.messenger(), api: plugin)
    }

    // MARK: - DocumentScannerApi

    func scanDocument(
        options: ScanOptions,
        completion: @escaping (Result<ScanResult, Error>) -> Void
    ) {
        // Vérifier les permissions
        PermissionManager.requestCameraPermission { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.performScan(options: options, completion: completion)
            case .failure(let error):
                let scanResult = ScanResult(
                    imagePaths: [],
                    success: false,
                    errorMessage: error.localizedDescription
                )
                completion(.success(scanResult))
            }
        }
    }

    private func performScan(
        options: ScanOptions,
        completion: @escaping (Result<ScanResult, Error>) -> Void
    ) {
        // Obtenir le view controller racine
        guard let viewController = getRootViewController() else {
            let scanResult = ScanResult(
                imagePaths: [],
                success: false,
                errorMessage: "No view controller available"
            )
            completion(.success(scanResult))
            return
        }

        // Créer le service de numérisation
        if #available(iOS 13.0, *) {
            let scanner = DocumentScannerService(
                presentingViewController: viewController,
                outputFormat: options.outputFormat
            )
            self.scannerService = scanner

            scanner.scanDocument { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let urls):
                    var imagePaths = urls.map { $0.path }

                    // Compression automatique si demandée
                    if options.autoCompress {
                        imagePaths = self.compressScannedImages(
                            imagePaths,
                            quality: Int(options.compressionQuality)
                        )
                    }

                    let scanResult = ScanResult(
                        imagePaths: imagePaths,
                        success: true,
                        errorMessage: nil
                    )
                    completion(.success(scanResult))

                case .failure(let error):
                    let scanResult = ScanResult(
                        imagePaths: [],
                        success: false,
                        errorMessage: error.localizedDescription
                    )
                    completion(.success(scanResult))
                }

                self.scannerService = nil
            }
        } else {
            let scanResult = ScanResult(
                imagePaths: [],
                success: false,
                errorMessage: "Document scanning requires iOS 13.0 or later"
            )
            completion(.success(scanResult))
        }
    }

    func compressImage(
        imagePath: String,
        quality: Int64,
        completion: @escaping (Result<CompressionResult, Error>) -> Void
    ) {
        let result = imageCompressionService.compressImage(
            at: imagePath,
            quality: Int(quality)
        )

        switch result {
        case .success(let info):
            let compressionResult = CompressionResult(
                outputPath: info.outputURL.path,
                originalSize: Int64(info.originalSize),
                compressedSize: Int64(info.compressedSize),
                success: true,
                errorMessage: nil
            )
            completion(.success(compressionResult))

        case .failure(let error):
            let compressionResult = CompressionResult(
                outputPath: nil,
                originalSize: 0,
                compressedSize: 0,
                success: false,
                errorMessage: error.localizedDescription
            )
            completion(.success(compressionResult))
        }
    }

    func compressPdf(
        pdfPath: String,
        quality: Int64,
        completion: @escaping (Result<CompressionResult, Error>) -> Void
    ) {
        let result = pdfCompressionService.compressPDF(
            at: pdfPath,
            quality: Int(quality)
        )

        switch result {
        case .success(let info):
            let compressionResult = CompressionResult(
                outputPath: info.outputURL.path,
                originalSize: Int64(info.originalSize),
                compressedSize: Int64(info.compressedSize),
                success: true,
                errorMessage: nil
            )
            completion(.success(compressionResult))

        case .failure(let error):
            let compressionResult = CompressionResult(
                outputPath: nil,
                originalSize: 0,
                compressedSize: 0,
                success: false,
                errorMessage: error.localizedDescription
            )
            completion(.success(compressionResult))
        }
    }

    func isScanningAvailable() throws -> Bool {
        if #available(iOS 13.0, *) {
            return DocumentScannerService.isScanningAvailable()
        }
        return false
    }

    // MARK: - Helper Methods

    private func getRootViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.rootViewController
        } else {
            return UIApplication.shared.keyWindow?.rootViewController
        }
    }

    private func compressScannedImages(_ imagePaths: [String], quality: Int) -> [String] {
        var compressedPaths: [String] = []

        for imagePath in imagePaths {
            let result = imageCompressionService.compressImage(at: imagePath, quality: quality)

            switch result {
            case .success(let info):
                compressedPaths.append(info.outputURL.path)
            case .failure:
                // En cas d'échec, garder l'image originale
                compressedPaths.append(imagePath)
            }
        }

        return compressedPaths
    }
}
