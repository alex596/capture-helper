import UIKit
import Vision
import AVFoundation

/// Détecteur de documents utilisant Vision framework
@available(iOS 13.0, *)
class DocumentDetector {

    /// Points détectés du document (coins en coordonnées normalisées 0-1)
    struct DetectedDocument {
        let topLeft: CGPoint
        let topRight: CGPoint
        let bottomLeft: CGPoint
        let bottomRight: CGPoint
        let confidence: Float

        /// Convertit les points normalisés en points dans une vue donnée
        func points(in viewSize: CGSize) -> [CGPoint] {
            return [
                CGPoint(x: topLeft.x * viewSize.width, y: (1 - topLeft.y) * viewSize.height),
                CGPoint(x: topRight.x * viewSize.width, y: (1 - topRight.y) * viewSize.height),
                CGPoint(x: bottomRight.x * viewSize.width, y: (1 - bottomRight.y) * viewSize.height),
                CGPoint(x: bottomLeft.x * viewSize.width, y: (1 - bottomLeft.y) * viewSize.height)
            ]
        }

        /// Vérifie si le document est suffisamment stable pour la capture
        var isStable: Bool {
            return confidence > 0.5
        }
    }

    private var lastDetectionTime: Date = Date()
    private let minDetectionInterval: TimeInterval = 0.05 // 50ms entre chaque détection pour plus de fluidité

    /// Détecte un document dans un sample buffer (pour le flux vidéo en temps réel)
    func detectDocument(in sampleBuffer: CMSampleBuffer, completion: @escaping (DetectedDocument?) -> Void) {
        // Limiter la fréquence de détection
        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) >= minDetectionInterval else {
            // Ne pas appeler completion pour éviter de reset l'état
            return
        }
        lastDetectionTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        // Utiliser le meilleur détecteur disponible selon la version iOS
        if #available(iOS 15.0, *) {
            detectWithDocumentSegmentation(pixelBuffer: pixelBuffer, completion: completion)
        } else {
            detectWithRectangles(pixelBuffer: pixelBuffer, completion: completion)
        }
    }

    /// Détecte un document dans une UIImage (pour l'image capturée)
    func detectDocument(in image: UIImage, completion: @escaping (DetectedDocument?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        if #available(iOS 15.0, *) {
            detectWithDocumentSegmentation(cgImage: cgImage, completion: completion)
        } else {
            detectWithRectangles(cgImage: cgImage, completion: completion)
        }
    }

    // MARK: - iOS 15+ : VNDetectDocumentSegmentationRequest (meilleure précision)

    @available(iOS 15.0, *)
    private func detectWithDocumentSegmentation(pixelBuffer: CVPixelBuffer, completion: @escaping (DetectedDocument?) -> Void) {
        let request = VNDetectDocumentSegmentationRequest()

        // .right correspond à l'orientation de la caméra arrière en mode portrait
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
                self.handleDocumentSegmentationResult(request: request, completion: completion)
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    @available(iOS 15.0, *)
    private func detectWithDocumentSegmentation(cgImage: CGImage, completion: @escaping (DetectedDocument?) -> Void) {
        let request = VNDetectDocumentSegmentationRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
                self.handleDocumentSegmentationResult(request: request, completion: completion)
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    @available(iOS 15.0, *)
    private func handleDocumentSegmentationResult(request: VNDetectDocumentSegmentationRequest, completion: @escaping (DetectedDocument?) -> Void) {
        // VNDetectDocumentSegmentationRequest retourne des VNRectangleObservation
        guard let document = request.results?.first else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        let detected = DetectedDocument(
            topLeft: document.topLeft,
            topRight: document.topRight,
            bottomLeft: document.bottomLeft,
            bottomRight: document.bottomRight,
            confidence: document.confidence
        )

        DispatchQueue.main.async {
            completion(detected)
        }
    }

    // MARK: - iOS 13-14 : VNDetectRectanglesRequest (fallback)

    private func detectWithRectangles(pixelBuffer: CVPixelBuffer, completion: @escaping (DetectedDocument?) -> Void) {
        let request = createRectangleRequest()
        // .right correspond à l'orientation de la caméra arrière en mode portrait
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
                self.handleRectangleResult(request: request, completion: completion)
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    private func detectWithRectangles(cgImage: CGImage, completion: @escaping (DetectedDocument?) -> Void) {
        let request = createRectangleRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
                self.handleRectangleResult(request: request, completion: completion)
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    private func createRectangleRequest() -> VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest()

        // Configuration pour iOS 13-14
        request.minimumAspectRatio = 0.2
        request.maximumAspectRatio = 5.0
        request.minimumSize = 0.05
        request.maximumObservations = 1
        request.minimumConfidence = 0.3
        request.quadratureTolerance = 30

        return request
    }

    private func handleRectangleResult(request: VNDetectRectanglesRequest, completion: @escaping (DetectedDocument?) -> Void) {
        guard let document = request.results?.first else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        let detected = DetectedDocument(
            topLeft: document.topLeft,
            topRight: document.topRight,
            bottomLeft: document.bottomLeft,
            bottomRight: document.bottomRight,
            confidence: document.confidence
        )

        DispatchQueue.main.async {
            completion(detected)
        }
    }
}
