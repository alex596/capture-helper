import UIKit
import PDFKit

/// Service gérant la compression de documents PDF
class PDFCompressionService {
    enum CompressionError: Error {
        case fileNotFound
        case invalidPDFData
        case compressionFailed
        case saveFailed

        var localizedDescription: String {
            switch self {
            case .fileNotFound:
                return "PDF file not found"
            case .invalidPDFData:
                return "Invalid PDF data"
            case .compressionFailed:
                return "Failed to compress PDF"
            case .saveFailed:
                return "Failed to save compressed PDF"
            }
        }
    }

    /// Résultat de la compression
    struct CompressionInfo {
        let outputURL: URL
        let originalSize: Int
        let compressedSize: Int
    }

    /// Compresse un document PDF en réduisant la qualité des images
    /// - Parameters:
    ///   - pdfPath: Chemin vers le PDF source
    ///   - quality: Qualité de compression (0-100)
    /// - Returns: Informations sur la compression
    func compressPDF(at pdfPath: String, quality: Int) -> Result<CompressionInfo, Error> {
        let fileURL = URL(fileURLWithPath: pdfPath)

        // Vérifier que le fichier existe
        guard FileManager.default.fileExists(atPath: pdfPath) else {
            return .failure(CompressionError.fileNotFound)
        }

        // Obtenir la taille originale
        guard let originalSize = try? FileManager.default.attributesOfItem(atPath: pdfPath)[.size] as? Int else {
            return .failure(CompressionError.fileNotFound)
        }

        // Charger le PDF
        guard let pdfDocument = PDFDocument(url: fileURL) else {
            return .failure(CompressionError.invalidPDFData)
        }

        // Créer un nouveau PDF avec compression
        let outputURL = createOutputURL(from: fileURL, suffix: "_compressed")

        // Convertir la qualité de 0-100 vers 0.0-1.0
        let compressionQuality = CGFloat(quality) / 100.0

        do {
            // Créer le contexte PDF
            let pdfBounds = pdfDocument.page(at: 0)?.bounds(for: .mediaBox) ?? CGRect(x: 0, y: 0, width: 612, height: 792)

            let pdfData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfData, pdfBounds, nil)

            // Parcourir toutes les pages
            for pageIndex in 0..<pdfDocument.pageCount {
                guard let page = pdfDocument.page(at: pageIndex) else { continue }

                let pageBounds = page.bounds(for: .mediaBox)
                UIGraphicsBeginPDFPageWithInfo(pageBounds, nil)

                guard let context = UIGraphicsGetCurrentContext() else { continue }

                // Fond blanc
                context.setFillColor(UIColor.white.cgColor)
                context.fill(pageBounds)

                // Rendre la page en image avec compression
                let renderer = UIGraphicsImageRenderer(bounds: pageBounds)
                let image = renderer.image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(pageBounds)
                    context.saveGState()
                    page.draw(with: .mediaBox, to: context)
                    context.restoreGState()
                }

                // Compresser et dessiner l'image
                if let compressedData = image.jpegData(compressionQuality: compressionQuality),
                   let compressedImage = UIImage(data: compressedData) {
                    compressedImage.draw(in: pageBounds)
                }
            }

            UIGraphicsEndPDFContext()

            // Sauvegarder
            try pdfData.write(to: outputURL)

            let compressedSize = pdfData.length

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
