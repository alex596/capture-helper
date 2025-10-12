/// Options de configuration pour la numérisation de documents
class CaptureHelperScanOptions {
  /// Si true, compresse automatiquement l'image après la capture
  final bool autoCompress;

  /// Qualité de compression (0-100) si autoCompress est true
  /// - 0 : qualité minimale, fichier le plus petit
  /// - 100 : qualité maximale, fichier le plus grand
  /// - Recommandé : 70-85 pour un bon équilibre qualité/taille
  final int compressionQuality;

  const CaptureHelperScanOptions({
    this.autoCompress = false,
    this.compressionQuality = 80,
  }) : assert(compressionQuality >= 0 && compressionQuality <= 100, 'compressionQuality doit être entre 0 et 100');

  /// Crée une copie avec des valeurs modifiées
  CaptureHelperScanOptions copyWith({
    bool? autoCompress,
    int? compressionQuality,
  }) {
    return CaptureHelperScanOptions(
      autoCompress: autoCompress ?? this.autoCompress,
      compressionQuality: compressionQuality ?? this.compressionQuality,
    );
  }

  @override
  String toString() => 'CaptureHelperScanOptions(autoCompress: $autoCompress, compressionQuality: $compressionQuality)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CaptureHelperScanOptions && other.autoCompress == autoCompress && other.compressionQuality == compressionQuality;
  }

  @override
  int get hashCode => autoCompress.hashCode ^ compressionQuality.hashCode;
}
