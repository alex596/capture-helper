import UIKit
import Accelerate
import CoreImage

/// Analyseur de qualité d'image pour les documents scannés
@available(iOS 13.0, *)
class ImageQualityAnalyzer {

    /// Résultat de l'analyse de qualité
    struct QualityResult {
        /// Score de netteté (0-100)
        let sharpnessScore: Int

        /// Score de luminosité (0-100)
        let brightnessScore: Int

        /// Pourcentage de couverture du document (0-100)
        let documentCoverage: Int

        /// Si l'image passe tous les critères
        let isAcceptable: Bool

        /// Message décrivant le problème principal (si non acceptable)
        let qualityIssue: String?

        /// Crée un résultat en vérifiant les seuils
        static func evaluate(
            sharpness: Int,
            brightness: Int,
            coverage: Int,
            minSharpness: Int,
            minBrightness: Int,
            minCoverage: Int
        ) -> QualityResult {
            var issues: [String] = []

            if minSharpness > 0 && sharpness < minSharpness {
                issues.append("Image floue")
            }

            if minBrightness > 0 {
                if brightness < 30 {
                    issues.append("Image trop sombre")
                } else if brightness > 90 {
                    issues.append("Image surexposée")
                }
            }

            if minCoverage > 0 && coverage < minCoverage {
                issues.append("Document trop petit dans l'image")
            }

            let isAcceptable = issues.isEmpty
            let qualityIssue = issues.first

            return QualityResult(
                sharpnessScore: sharpness,
                brightnessScore: brightness,
                documentCoverage: coverage,
                isAcceptable: isAcceptable,
                qualityIssue: qualityIssue
            )
        }
    }

    /// Seuils de qualité configurables
    struct QualityThresholds {
        var minSharpness: Int = 40
        var minBrightness: Int = 30
        var minCoverage: Int = 15  // 15% permet de scanner de plus loin

        static let `default` = QualityThresholds()
        static let disabled = QualityThresholds(minSharpness: 0, minBrightness: 0, minCoverage: 0)
    }

    private var thresholds: QualityThresholds

    init(thresholds: QualityThresholds = .default) {
        self.thresholds = thresholds
    }

    /// Configure les seuils de qualité
    func setThresholds(minSharpness: Int, minBrightness: Int, minCoverage: Int) {
        thresholds.minSharpness = minSharpness
        thresholds.minBrightness = minBrightness
        thresholds.minCoverage = minCoverage
    }

    /// Analyse la qualité d'une image
    func analyzeQuality(of image: UIImage, documentBounds: CGRect? = nil) -> QualityResult {
        // Redimensionner l'image pour une analyse rapide
        let analysisImage = resizeForAnalysis(image, maxSize: 300)

        let sharpness = calculateSharpness(of: analysisImage)
        let brightness = calculateBrightness(of: analysisImage)
        let coverage = calculateDocumentCoverage(documentBounds: documentBounds, imageSize: image.size)

        return QualityResult.evaluate(
            sharpness: sharpness,
            brightness: brightness,
            coverage: coverage,
            minSharpness: thresholds.minSharpness,
            minBrightness: thresholds.minBrightness,
            minCoverage: thresholds.minCoverage
        )
    }

    /// Redimensionne l'image pour une analyse rapide
    private func resizeForAnalysis(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)

        if ratio >= 1 { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Analyse rapide pendant la capture (sur le buffer vidéo)
    func analyzeQualityFast(pixelBuffer: CVPixelBuffer, documentCoverage: Int) -> QualityResult {
        let sharpness = calculateSharpnessFast(pixelBuffer: pixelBuffer)
        let brightness = calculateBrightnessFast(pixelBuffer: pixelBuffer)

        return QualityResult.evaluate(
            sharpness: sharpness,
            brightness: brightness,
            coverage: documentCoverage,
            minSharpness: thresholds.minSharpness,
            minBrightness: thresholds.minBrightness,
            minCoverage: thresholds.minCoverage
        )
    }

    // MARK: - Calcul de netteté (Laplacian Variance)

    /// Calcule le score de netteté d'une image (0-100)
    private func calculateSharpness(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }

        // Convertir en niveaux de gris
        let width = cgImage.width
        let height = cgImage.height

        guard width > 0 && height > 0 else { return 0 }

        // Créer un buffer pour l'image en niveaux de gris
        var pixelData = [UInt8](repeating: 0, count: width * height)

        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return 0 }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Calculer la variance du Laplacien
        let variance = calculateLaplacianVariance(pixels: pixelData, width: width, height: height)

        // Normaliser le score (0-100)
        // Une variance > 500 est généralement très nette
        let normalizedScore = min(100, Int(variance / 5))
        return normalizedScore
    }

    /// Version rapide pour le buffer vidéo
    private func calculateSharpnessFast(pixelBuffer: CVPixelBuffer) -> Int {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // Échantillonner une région centrale (plus rapide)
        let sampleSize = 200
        let startX = max(0, (width - sampleSize) / 2)
        let startY = max(0, (height - sampleSize) / 2)
        let endX = min(width, startX + sampleSize)
        let endY = min(height, startY + sampleSize)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return 50 }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        var sum: Double = 0
        var sumSq: Double = 0
        var count = 0

        // Calculer la variance sur l'échantillon (approximation rapide)
        for y in stride(from: startY, to: endY, by: 4) {
            for x in stride(from: startX, to: endX, by: 4) {
                let offset = y * bytesPerRow + x * 4
                let pixel = baseAddress.load(fromByteOffset: offset, as: UInt8.self)
                let value = Double(pixel)
                sum += value
                sumSq += value * value
                count += 1
            }
        }

        guard count > 0 else { return 50 }

        let mean = sum / Double(count)
        let variance = (sumSq / Double(count)) - (mean * mean)

        // Normaliser
        return min(100, Int(variance / 20))
    }

    /// Calcule la variance du Laplacien
    private func calculateLaplacianVariance(pixels: [UInt8], width: Int, height: Int) -> Double {
        // Kernel Laplacien simplifié
        let kernel: [Int] = [0, 1, 0, 1, -4, 1, 0, 1, 0]

        var sum: Double = 0
        var sumSq: Double = 0
        var count = 0

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                var laplacian = 0

                for ky in -1...1 {
                    for kx in -1...1 {
                        let idx = (y + ky) * width + (x + kx)
                        let kernelIdx = (ky + 1) * 3 + (kx + 1)
                        laplacian += Int(pixels[idx]) * kernel[kernelIdx]
                    }
                }

                let value = Double(abs(laplacian))
                sum += value
                sumSq += value * value
                count += 1
            }
        }

        guard count > 0 else { return 0 }

        let mean = sum / Double(count)
        let variance = (sumSq / Double(count)) - (mean * mean)

        return variance
    }

    // MARK: - Calcul de luminosité

    /// Calcule le score de luminosité d'une image (0-100)
    private func calculateBrightness(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 50 }

        let width = cgImage.width
        let height = cgImage.height

        guard width > 0 && height > 0 else { return 50 }

        // Échantillonner l'image
        let sampleSize = min(100, min(width, height))
        let stepX = width / sampleSize
        let stepY = height / sampleSize

        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 50 }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var totalBrightness: Double = 0
        var count = 0

        for y in stride(from: 0, to: height, by: stepY) {
            for x in stride(from: 0, to: width, by: stepX) {
                let offset = (y * width + x) * 4
                let r = Double(pixelData[offset])
                let g = Double(pixelData[offset + 1])
                let b = Double(pixelData[offset + 2])

                // Luminosité perceptuelle
                let brightness = 0.299 * r + 0.587 * g + 0.114 * b
                totalBrightness += brightness
                count += 1
            }
        }

        guard count > 0 else { return 50 }

        let averageBrightness = totalBrightness / Double(count)
        return Int(averageBrightness / 2.55) // Convertir 0-255 en 0-100
    }

    /// Version rapide pour le buffer vidéo
    private func calculateBrightnessFast(pixelBuffer: CVPixelBuffer) -> Int {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return 50 }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        var totalBrightness: Double = 0
        var count = 0

        // Échantillonner
        let stepX = max(1, width / 50)
        let stepY = max(1, height / 50)

        for y in stride(from: 0, to: height, by: stepY) {
            for x in stride(from: 0, to: width, by: stepX) {
                let offset = y * bytesPerRow + x * 4

                let b = Double(baseAddress.load(fromByteOffset: offset, as: UInt8.self))
                let g = Double(baseAddress.load(fromByteOffset: offset + 1, as: UInt8.self))
                let r = Double(baseAddress.load(fromByteOffset: offset + 2, as: UInt8.self))

                let brightness = 0.299 * r + 0.587 * g + 0.114 * b
                totalBrightness += brightness
                count += 1
            }
        }

        guard count > 0 else { return 50 }

        let averageBrightness = totalBrightness / Double(count)
        return Int(averageBrightness / 2.55)
    }

    // MARK: - Calcul de couverture du document

    /// Calcule le pourcentage de l'image occupé par le document (0-100)
    private func calculateDocumentCoverage(documentBounds: CGRect?, imageSize: CGSize) -> Int {
        guard let bounds = documentBounds else { return 0 }
        guard imageSize.width > 0 && imageSize.height > 0 else { return 0 }

        let imageArea = imageSize.width * imageSize.height
        let documentArea = bounds.width * bounds.height

        let coverage = (documentArea / imageArea) * 100
        return Int(min(100, max(0, coverage)))
    }

    /// Calcule la couverture à partir des points du document (coordonnées normalisées)
    func calculateDocumentCoverage(
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomLeft: CGPoint,
        bottomRight: CGPoint
    ) -> Int {
        // Calculer l'aire du quadrilatère avec la formule du lacet
        let points = [topLeft, topRight, bottomRight, bottomLeft]

        var area: CGFloat = 0
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            area += points[i].x * points[j].y
            area -= points[j].x * points[i].y
        }
        area = abs(area) / 2

        // L'aire est en coordonnées normalisées (0-1), donc max = 1
        let coverage = area * 100
        return Int(min(100, max(0, coverage)))
    }
}
