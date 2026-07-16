import 'package:capture_helper/src/models/output_format.dart';

/// Mode de capture du scanner
enum CaptureMode {
  /// Capture automatique après stabilisation du document + bouton manuel disponible
  auto,

  /// Capture manuelle uniquement (bouton de capture)
  manual,
}

/// Options de configuration pour la numérisation de documents
class CaptureHelperScanOptions {
  /// Mode de capture (auto ou manuel)
  /// - auto : capture automatique après stabilisation + bouton manuel disponible
  /// - manual : capture manuelle uniquement
  final CaptureMode captureMode;

  /// Nombre de pages à scanner
  /// - 1 : mode single-page (se ferme après une capture)
  /// - 0 ou null : mode multi-pages illimité
  /// - 2-10 : mode multi-pages avec limite
  final int pageLimit;

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

  /// Seuil minimum de netteté (0-100)
  /// - 0 : désactivé (pas de vérification de netteté)
  /// - 40 : valeur recommandée
  /// Si l'image est en dessous du seuil, un écran de feedback s'affiche
  final int minSharpnessScore;

  /// Seuil minimum de luminosité (0-100)
  /// - 0 : désactivé (pas de vérification de luminosité)
  /// - 30 : valeur recommandée
  /// Si l'image est en dessous du seuil, un écran de feedback s'affiche
  final int minBrightnessScore;

  /// Surface minimum du document dans l'image (0-100%)
  /// - 0 : désactivé
  /// - 40 : valeur recommandée (document occupe au moins 40% de l'écran)
  final int minDocumentCoverage;

  /// Délai en secondes avant capture automatique (mode auto uniquement)
  /// Défaut : 1.0 seconde
  final double autoCaptureDelay;

  const CaptureHelperScanOptions({
    this.captureMode = CaptureMode.manual,
    this.pageLimit = 1,
    this.autoCompress = false,
    this.compressionQuality = 80,
    this.outputFormat = OutputFormat.jpeg,
    this.minSharpnessScore = 0,
    this.minBrightnessScore = 0,
    this.minDocumentCoverage = 40,
    this.autoCaptureDelay = 1.0,
  })  : assert(compressionQuality >= 0 && compressionQuality <= 100,
            'compressionQuality doit être entre 0 et 100'),
        assert(pageLimit >= 0 && pageLimit <= 10,
            'pageLimit doit être entre 0 et 10'),
        assert(minSharpnessScore >= 0 && minSharpnessScore <= 100,
            'minSharpnessScore doit être entre 0 et 100'),
        assert(minBrightnessScore >= 0 && minBrightnessScore <= 100,
            'minBrightnessScore doit être entre 0 et 100'),
        assert(minDocumentCoverage >= 0 && minDocumentCoverage <= 100,
            'minDocumentCoverage doit être entre 0 et 100'),
        assert(autoCaptureDelay >= 0.5 && autoCaptureDelay <= 5.0,
            'autoCaptureDelay doit être entre 0.5 et 5.0 secondes');

  /// Configuration prédéfinie : scan rapide d'une seule page en mode auto
  static const singlePageAuto = CaptureHelperScanOptions(
    captureMode: CaptureMode.auto,
    pageLimit: 1,
  );

  /// Configuration prédéfinie : scan rapide d'une seule page en mode manuel
  static const singlePageManual = CaptureHelperScanOptions(
    captureMode: CaptureMode.manual,
    pageLimit: 1,
  );

  /// Configuration prédéfinie : scan multi-pages en mode auto
  static const multiPageAuto = CaptureHelperScanOptions(
    captureMode: CaptureMode.auto,
    pageLimit: 0,
  );

  /// Configuration prédéfinie : scan multi-pages en mode manuel
  static const multiPageManual = CaptureHelperScanOptions(
    captureMode: CaptureMode.manual,
    pageLimit: 0,
  );

  /// Crée une copie avec des valeurs modifiées
  CaptureHelperScanOptions copyWith({
    CaptureMode? captureMode,
    int? pageLimit,
    bool? autoCompress,
    int? compressionQuality,
    OutputFormat? outputFormat,
    int? minSharpnessScore,
    int? minBrightnessScore,
    int? minDocumentCoverage,
    double? autoCaptureDelay,
  }) {
    return CaptureHelperScanOptions(
      captureMode: captureMode ?? this.captureMode,
      pageLimit: pageLimit ?? this.pageLimit,
      autoCompress: autoCompress ?? this.autoCompress,
      compressionQuality: compressionQuality ?? this.compressionQuality,
      outputFormat: outputFormat ?? this.outputFormat,
      minSharpnessScore: minSharpnessScore ?? this.minSharpnessScore,
      minBrightnessScore: minBrightnessScore ?? this.minBrightnessScore,
      minDocumentCoverage: minDocumentCoverage ?? this.minDocumentCoverage,
      autoCaptureDelay: autoCaptureDelay ?? this.autoCaptureDelay,
    );
  }

  @override
  String toString() =>
      'CaptureHelperScanOptions(captureMode: $captureMode, pageLimit: $pageLimit, autoCompress: $autoCompress, compressionQuality: $compressionQuality, outputFormat: $outputFormat, minSharpnessScore: $minSharpnessScore, minBrightnessScore: $minBrightnessScore, minDocumentCoverage: $minDocumentCoverage, autoCaptureDelay: $autoCaptureDelay)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CaptureHelperScanOptions &&
        other.captureMode == captureMode &&
        other.pageLimit == pageLimit &&
        other.autoCompress == autoCompress &&
        other.compressionQuality == compressionQuality &&
        other.outputFormat == outputFormat &&
        other.minSharpnessScore == minSharpnessScore &&
        other.minBrightnessScore == minBrightnessScore &&
        other.minDocumentCoverage == minDocumentCoverage &&
        other.autoCaptureDelay == autoCaptureDelay;
  }

  @override
  int get hashCode =>
      captureMode.hashCode ^
      pageLimit.hashCode ^
      autoCompress.hashCode ^
      compressionQuality.hashCode ^
      outputFormat.hashCode ^
      minSharpnessScore.hashCode ^
      minBrightnessScore.hashCode ^
      minDocumentCoverage.hashCode ^
      autoCaptureDelay.hashCode;
}
