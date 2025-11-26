export 'src/models/scan_options.dart';
export 'src/models/scan_result.dart';
export 'src/models/compression_result.dart';
export 'src/models/output_format.dart';

import 'package:capture_helper/src/generated/document_scanner_api.g.dart';
import 'package:capture_helper/src/models/scan_options.dart';
import 'package:capture_helper/src/models/scan_result.dart';
import 'package:capture_helper/src/models/compression_result.dart';

/// Plugin Flutter pour la numérisation de documents avec VisionKit (iOS) et ML Kit (Android)
class CaptureHelper {
  static final CaptureHelper _instance = CaptureHelper._internal();
  late final DocumentScannerApi _api;

  factory CaptureHelper() {
    return _instance;
  }

  CaptureHelper._internal() {
    _api = DocumentScannerApi();
  }

  /// Vérifie si la numérisation de documents est disponible sur cet appareil
  ///
  /// Retourne `false` si :
  /// - iOS < 13.0
  /// - Simulateur iOS (VisionKit nécessite un appareil physique)
  /// - Android sans Google Play Services
  Future<bool> isScanningAvailable() async {
    try {
      return await _api.isScanningAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Lance l'interface native de numérisation de documents
  ///
  /// [options] : Options de configuration pour la numérisation
  ///
  /// Retourne un [CaptureHelperScanResult] contenant :
  /// - Liste des chemins des images scannées (si succès)
  /// - Statut de l'opération
  /// - Message d'erreur éventuel
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final result = await CaptureHelper().scanDocument(
  ///   options: CaptureHelperScanOptions(
  ///     autoCompress: true,
  ///     compressionQuality: 85,
  ///   ),
  /// );
  ///
  /// if (result.success) {
  ///   print('Images scannées : ${result.imagePaths}');
  /// } else {
  ///   print('Erreur : ${result.errorMessage}');
  /// }
  /// ```
  Future<CaptureHelperScanResult> scanDocument({
    CaptureHelperScanOptions options = const CaptureHelperScanOptions(),
  }) async {
    try {
      final pigeonOptions = ScanOptions(
        autoCompress: options.autoCompress,
        compressionQuality: options.compressionQuality,
        outputFormat: options.outputFormat.name, // 'jpeg' ou 'png'
      );

      final pigeonResult = await _api.scanDocument(pigeonOptions);

      return CaptureHelperScanResult(
        imagePaths: pigeonResult.imagePaths.where((path) => path != null).cast<String>().toList(),
        success: pigeonResult.success,
        errorMessage: pigeonResult.errorMessage,
      );
    } catch (e) {
      return CaptureHelperScanResult.failure(
        'Failed to scan document: ${e.toString()}',
      );
    }
  }

  /// Compresse une image JPEG
  ///
  /// [imagePath] : Chemin vers l'image à compresser
  /// [quality] : Qualité de compression (0-100)
  ///   - 0 : qualité minimale, fichier le plus petit
  ///   - 100 : qualité maximale, fichier le plus grand
  ///   - Recommandé : 70-85 pour un bon équilibre
  ///
  /// Retourne un [CaptureHelperCompressionResult] contenant :
  /// - Chemin du fichier compressé
  /// - Tailles originale et compressée
  /// - Statistiques de compression
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final result = await CaptureHelper().compressImage(
  ///   imagePath: '/path/to/image.jpg',
  ///   quality: 80,
  /// );
  ///
  /// if (result.success) {
  ///   print('Compression réussie : ${result.reductionPercentage.toStringAsFixed(1)}%');
  ///   print('Taille originale : ${result.formattedOriginalSize}');
  ///   print('Taille compressée : ${result.formattedCompressedSize}');
  /// }
  /// ```
  Future<CaptureHelperCompressionResult> compressImage({
    required String imagePath,
    int quality = 80,
  }) async {
    assert(quality >= 0 && quality <= 100, 'quality doit être entre 0 et 100');

    try {
      final pigeonResult = await _api.compressImage(imagePath, quality);

      return CaptureHelperCompressionResult(
        outputPath: pigeonResult.outputPath,
        originalSize: pigeonResult.originalSize,
        compressedSize: pigeonResult.compressedSize,
        success: pigeonResult.success,
        errorMessage: pigeonResult.errorMessage,
      );
    } catch (e) {
      return CaptureHelperCompressionResult.failure(
        errorMessage: 'Failed to compress image: ${e.toString()}',
      );
    }
  }

  /// Compresse un document PDF
  ///
  /// [pdfPath] : Chemin vers le PDF à compresser
  /// [quality] : Qualité de compression (0-100)
  ///
  /// Retourne un [CaptureHelperCompressionResult] avec les mêmes informations
  /// que [compressImage]
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final result = await CaptureHelper().compressPdf(
  ///   pdfPath: '/path/to/document.pdf',
  ///   quality: 75,
  /// );
  /// ```
  Future<CaptureHelperCompressionResult> compressPdf({
    required String pdfPath,
    int quality = 80,
  }) async {
    assert(quality >= 0 && quality <= 100, 'quality doit être entre 0 et 100');

    try {
      final pigeonResult = await _api.compressPdf(pdfPath, quality);

      return CaptureHelperCompressionResult(
        outputPath: pigeonResult.outputPath,
        originalSize: pigeonResult.originalSize,
        compressedSize: pigeonResult.compressedSize,
        success: pigeonResult.success,
        errorMessage: pigeonResult.errorMessage,
      );
    } catch (e) {
      return CaptureHelperCompressionResult.failure(
        errorMessage: 'Failed to compress PDF: ${e.toString()}',
      );
    }
  }
}
