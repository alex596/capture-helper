/// Format de sortie pour les images scannées
enum OutputFormat {
  /// Format JPEG - Compression avec perte, fichiers plus légers
  /// Recommandé pour les documents scannés standards
  jpeg,

  /// Format PNG - Compression sans perte, fichiers plus lourds
  /// Recommandé pour les schémas, diagrammes, ou quand la netteté est cruciale
  png,
}
