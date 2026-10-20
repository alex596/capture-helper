import Foundation

/// Répertoire de sortie des fichiers produits par le plugin (scans et compressions)
///
/// Les fichiers sont écrits dans `Library/Caches/capture_helper/` : ils sont privés à l'app,
/// exclus des sauvegardes iCloud et peuvent être purgés par le système en cas de manque d'espace.
/// L'application hôte doit copier les fichiers qu'elle souhaite conserver.
enum OutputDirectory {
    static let name = "capture_helper"

    private static var directoryURL: URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesDirectory.appendingPathComponent(name, isDirectory: true)
    }

    /// Retourne le répertoire de sortie, en le créant si nécessaire
    static func url() -> URL {
        let directory = directoryURL
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Supprime le répertoire de sortie et tout son contenu
    ///
    /// Retourne `true` si le répertoire a été supprimé ou n'existait pas.
    static func clear() -> Bool {
        let directory = directoryURL
        guard FileManager.default.fileExists(atPath: directory.path) else { return true }

        do {
            try FileManager.default.removeItem(at: directory)
            return true
        } catch {
            return false
        }
    }
}
