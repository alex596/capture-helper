import 'package:capture_helper/src/models/output_format.dart';

/// Options de configuration pour la numérisation de documents
class CaptureHelperScanOptions {
  /// Si true, compresse automatiquement l'image après la capture
  final bool autoCompress;

  /// Qualité de compression (0-100) si autoCompress est true
  /// - 0 : qualité minimale, fichier le plus petit
  /// - 100 : qualité maximale, fichier le plus grand
  /// - Recommandé : 70-85 pour un bon équilibre qualité/taille
  final int compressionQuality;

  /// Format de sortie pour les images scannées
  /// - JPEG : Plus léger, compression avec perte (défaut)
  /// - PNG : Plus lourd, compression sans perte
  final OutputFormat outputFormat;

  const CaptureHelperScanOptions({
    this.autoCompress = false,
    this.compressionQuality = 80,
    this.outputFormat = OutputFormat.jpeg,
  }) : assert(compressionQuality >= 0 && compressionQuality <= 100, 'compressionQuality doit être entre 0 et 100');

  /// Crée une copie avec des valeurs modifiées
  CaptureHelperScanOptions copyWith({
    bool? autoCompress,
    int? compressionQuality,
    OutputFormat? outputFormat,
  }) {
    return CaptureHelperScanOptions(
      autoCompress: autoCompress ?? this.autoCompress,
      compressionQuality: compressionQuality ?? this.compressionQuality,
      outputFormat: outputFormat ?? this.outputFormat,
    );
  }

  @override
  String toString() =>
      'CaptureHelperScanOptions(autoCompress: $autoCompress, compressionQuality: $compressionQuality, outputFormat: $outputFormat)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CaptureHelperScanOptions &&
        other.autoCompress == autoCompress &&
        other.compressionQuality == compressionQuality &&
        other.outputFormat == outputFormat;
  }

  @override
  int get hashCode => autoCompress.hashCode ^ compressionQuality.hashCode ^ outputFormat.hashCode;
}
