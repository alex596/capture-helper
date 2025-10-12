import UIKit

/// Service gérant la compression d'images JPEG
class ImageCompressionService {
    enum CompressionError: Error {
        case fileNotFound
        case invalidImageData
        case compressionFailed
        case saveFailed

        var localizedDescription: String {
            switch self {
            case .fileNotFound:
                return "Image file not found"
            case .invalidImageData:
                return "Invalid image data"
            case .compressionFailed:
                return "Failed to compress image"
            case .saveFailed:
                return "Failed to save compressed image"
            }
        }
    }

    /// Résultat de la compression
    struct CompressionInfo {
        let outputURL: URL
        let originalSize: Int
        let compressedSize: Int
    }

    /// Compresse une image JPEG
    /// - Parameters:
    ///   - imagePath: Chemin vers l'image source
    ///   - quality: Qualité de compression (0-100)
    /// - Returns: Informations sur la compression
    func compressImage(at imagePath: String, quality: Int) -> Result<CompressionInfo, Error> {
        let fileURL = URL(fileURLWithPath: imagePath)

        // Vérifier que le fichier existe
        guard FileManager.default.fileExists(atPath: imagePath) else {
            return .failure(CompressionError.fileNotFound)
        }

        // Obtenir la taille originale
        guard let originalSize = try? FileManager.default.attributesOfItem(atPath: imagePath)[.size] as? Int else {
            return .failure(CompressionError.fileNotFound)
        }

        // Charger l'image
        guard let image = UIImage(contentsOfFile: imagePath) else {
            return .failure(CompressionError.invalidImageData)
        }

        // Convertir la qualité de 0-100 vers 0.0-1.0
        let compressionQuality = CGFloat(quality) / 100.0

        // Compresser l'image
        guard let compressedData = image.jpegData(compressionQuality: compressionQuality) else {
            return .failure(CompressionError.compressionFailed)
        }

        // Créer le fichier de sortie
        let outputURL = createOutputURL(from: fileURL, suffix: "_compressed")

        // Sauvegarder
        do {
            try compressedData.write(to: outputURL)

            let compressedSize = compressedData.count

            return .success(CompressionInfo(
                outputURL: outputURL,
                originalSize: originalSize,
                compressedSize: compressedSize
            ))
        } catch {
            return .failure(CompressionError.saveFailed)
        }
    }

    /// Crée une URL de sortie avec un suffixe
    private func createOutputURL(from sourceURL: URL, suffix: String) -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let filename = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension

        let newFilename = "\(filename)\(suffix).\(ext)"
        return directory.appendingPathComponent(newFilename)
    }
}
