import AVFoundation
import UIKit

/// Gestionnaire de permissions pour la caméra
class PermissionManager {
    enum PermissionError: Error {
        case cameraNotAuthorized
        case cameraRestricted
        case cameraNotAvailable

        var localizedDescription: String {
            switch self {
            case .cameraNotAuthorized:
                return "Camera permission not granted"
            case .cameraRestricted:
                return "Camera access is restricted"
            case .cameraNotAvailable:
                return "Camera is not available on this device"
            }
        }
    }

    /// Vérifie et demande la permission de la caméra si nécessaire
    static func requestCameraPermission(completion: @escaping (Result<Void, Error>) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            completion(.success(()))

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(.success(()))
                    } else {
                        completion(.failure(PermissionError.cameraNotAuthorized))
                    }
                }
            }

        case .denied:
            completion(.failure(PermissionError.cameraNotAuthorized))

        case .restricted:
            completion(.failure(PermissionError.cameraRestricted))

        @unknown default:
            completion(.failure(PermissionError.cameraNotAvailable))
        }
    }

    /// Vérifie si la permission caméra est accordée
    static func isCameraAuthorized() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
}
