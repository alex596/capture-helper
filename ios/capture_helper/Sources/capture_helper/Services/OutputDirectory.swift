import Foundation

/// Répertoire de sortie des fichiers produits par le plugin (scans et compressions)
///
/// Les fichiers sont écrits dans `Library/Caches/capture_helper/` : ils sont privés à l'app,
/// exclus des sauvegardes iCloud et peuvent être purgés par le système en cas de manque d'espace.
/// L'application hôte doit copier les fichiers qu'elle souhaite conserver.
enum OutputDirectory {
    static let name = "capture_helper"

    /// Retourne le répertoire de sortie, en le créant si nécessaire
    static func url() -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let directory = cachesDirectory.appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
