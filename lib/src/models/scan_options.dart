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

  /// Si true, capture automatiquement dès que le document est détecté
  /// Si false, l'utilisateur doit appuyer sur le bouton pour capturer
  /// Par défaut : true
  final bool useAutomaticCapture;

  /// Nombre maximum de pages à scanner
  /// - 0 : illimité (défaut)
  /// - N > 0 : limite à N pages, puis ferme automatiquement le scanner
  final int pageLimit;

  const CaptureHelperScanOptions({
    this.autoCompress = false,
    this.compressionQuality = 80,
    this.outputFormat = OutputFormat.jpeg,
    this.useAutomaticCapture = true,
    this.pageLimit = 0,
  }) : assert(compressionQuality >= 0 && compressionQuality <= 100, 'compressionQuality doit être entre 0 et 100'),
       assert(pageLimit >= 0, 'pageLimit doit être >= 0');

  /// Crée une copie avec des valeurs modifiées
  CaptureHelperScanOptions copyWith({
    bool? autoCompress,
    int? compressionQuality,
    OutputFormat? outputFormat,
    bool? useAutomaticCapture,
    int? pageLimit,
  }) {
    return CaptureHelperScanOptions(
      autoCompress: autoCompress ?? this.autoCompress,
      compressionQuality: compressionQuality ?? this.compressionQuality,
      outputFormat: outputFormat ?? this.outputFormat,
      useAutomaticCapture: useAutomaticCapture ?? this.useAutomaticCapture,
      pageLimit: pageLimit ?? this.pageLimit,
    );
  }

  @override
  String toString() =>
      'CaptureHelperScanOptions(autoCompress: $autoCompress, compressionQuality: $compressionQuality, outputFormat: $outputFormat, useAutomaticCapture: $useAutomaticCapture, pageLimit: $pageLimit)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CaptureHelperScanOptions &&
        other.autoCompress == autoCompress &&
        other.compressionQuality == compressionQuality &&
        other.outputFormat == outputFormat &&
        other.useAutomaticCapture == useAutomaticCapture &&
        other.pageLimit == pageLimit;
  }

  @override
  int get hashCode =>
      autoCompress.hashCode ^ compressionQuality.hashCode ^ outputFormat.hashCode ^ useAutomaticCapture.hashCode ^ pageLimit.hashCode;
}
