import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/document_scanner_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/capture_helper/Sources/capture_helper/Generated/DocumentScannerApi.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut: 'android/src/main/kotlin/com/flutter/plugin/helper/capture_helper/generated/DocumentScannerApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.flutter.plugin.helper.capture_helper.generated'),
  ),
)
/// Options pour la numérisation de documents
class ScanOptions {
  /// Si true, compresse automatiquement l'image après la capture
  final bool autoCompress;

  /// Qualité de compression (0-100) si autoCompress est true
  final int compressionQuality;

  /// Format de sortie : 'jpeg' ou 'png'
  final String outputFormat;

  /// Si true, capture automatiquement dès que le document est détecté
  /// Si false, l'utilisateur doit appuyer sur le bouton pour capturer
  final bool useAutomaticCapture;

  /// Nombre maximum de pages à scanner (0 = illimité)
  final int pageLimit;

  ScanOptions({
    required this.autoCompress,
    required this.compressionQuality,
    required this.outputFormat,
    required this.useAutomaticCapture,
    required this.pageLimit,
  });
}

/// Résultat d'une numérisation de documents
class ScanResult {
  /// Liste des chemins des images scannées
  final List<String?> imagePaths;

  /// Indique si l'opération a réussi
  final bool success;

  /// Message d'erreur si applicable
  final String? errorMessage;

  ScanResult({
    required this.imagePaths,
    required this.success,
    this.errorMessage,
  });
}

/// Résultat d'une compression
class CompressionResult {
  /// Chemin du fichier compressé
  final String? outputPath;

  /// Taille originale en octets
  final int originalSize;

  /// Taille compressée en octets
  final int compressedSize;

  /// Indique si l'opération a réussi
  final bool success;

  /// Message d'erreur si applicable
  final String? errorMessage;

  CompressionResult({
    this.outputPath,
    required this.originalSize,
    required this.compressedSize,
    required this.success,
    this.errorMessage,
  });
}

/// API native pour la numérisation de documents
@HostApi()
abstract class DocumentScannerApi {
  /// Lance l'interface de numérisation de documents
  @asyncCallback
  ScanResult scanDocument(ScanOptions options);

  /// Compresse une image
  @asyncCallback
  CompressionResult compressImage(String imagePath, int quality);

  /// Compresse un PDF
  @asyncCallback
  CompressionResult compressPdf(String pdfPath, int quality);

  /// Vérifie si la numérisation est disponible sur l'appareil
  bool isScanningAvailable();
}
