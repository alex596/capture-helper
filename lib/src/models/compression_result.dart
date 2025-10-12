/// Résultat d'une opération de compression d'image ou de PDF
class CaptureHelperCompressionResult {
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

  const CaptureHelperCompressionResult({
    this.outputPath,
    required this.originalSize,
    required this.compressedSize,
    required this.success,
    this.errorMessage,
  });

  /// Crée un résultat réussi
  factory CaptureHelperCompressionResult.success({
    required String outputPath,
    required int originalSize,
    required int compressedSize,
  }) {
    return CaptureHelperCompressionResult(
      outputPath: outputPath,
      originalSize: originalSize,
      compressedSize: compressedSize,
      success: true,
    );
  }

  /// Crée un résultat d'échec
  factory CaptureHelperCompressionResult.failure({
    required String errorMessage,
    int originalSize = 0,
  }) {
    return CaptureHelperCompressionResult(
      originalSize: originalSize,
      compressedSize: 0,
      success: false,
      errorMessage: errorMessage,
    );
  }

  /// Taux de compression (0.0 - 1.0)
  /// Par exemple, 0.5 signifie que le fichier est 50% plus petit
  double get compressionRatio {
    if (originalSize == 0) return 0.0;
    return 1.0 - (compressedSize / originalSize);
  }

  /// Pourcentage de réduction de taille (0-100)
  double get reductionPercentage => compressionRatio * 100;

  /// Économie d'espace en octets
  int get savedBytes => originalSize - compressedSize;

  /// Formate la taille en Ko ou Mo
  String formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Taille originale formatée
  String get formattedOriginalSize => formatSize(originalSize);

  /// Taille compressée formatée
  String get formattedCompressedSize => formatSize(compressedSize);

  /// Économie formatée
  String get formattedSavedBytes => formatSize(savedBytes);

  @override
  String toString() =>
      'CaptureHelperCompressionResult(success: $success, originalSize: $formattedOriginalSize, compressedSize: $formattedCompressedSize, reduction: ${reductionPercentage.toStringAsFixed(1)}%)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CaptureHelperCompressionResult &&
        other.outputPath == outputPath &&
        other.originalSize == originalSize &&
        other.compressedSize == compressedSize &&
        other.success == success &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => outputPath.hashCode ^ originalSize.hashCode ^ compressedSize.hashCode ^ success.hashCode ^ errorMessage.hashCode;
}
