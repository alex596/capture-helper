import UIKit

/// Service gérant la compression d'images JPEG et PNG
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

    /// Compresse une image JPEG ou PNG
    /// - Parameters:
    ///   - imagePath: Chemin vers l'image source
    ///   - quality: Qualité de compression (0-100), utilisé seulement pour JPEG
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

        // Déterminer le format basé sur l'extension
        let fileExtension = fileURL.pathExtension.lowercased()
        let isPNG = fileExtension == "png"

        // Compresser selon le format
        let compressedData: Data?
        if isPNG {
            // PNG : compression sans perte, pas de paramètre qualité
            compressedData = image.pngData()
        } else {
            // JPEG : compression avec qualité
            let compressionQuality = CGFloat(quality) / 100.0
            compressedData = image.jpegData(compressionQuality: compressionQuality)
        }

        guard let data = compressedData else {
            return .failure(CompressionError.compressionFailed)
        }

        // Créer le fichier de sortie
        let outputURL = createOutputURL(from: fileURL, suffix: "_compressed")

        // Sauvegarder
        do {
            try data.write(to: outputURL)

            let compressedSize = data.count

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
