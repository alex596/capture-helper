/// Résultat d'une opération de numérisation de documents
class CaptureHelperScanResult {
  /// Liste des chemins des images scannées
  /// Chaque chemin pointe vers un fichier JPEG stocké localement
  final List<String> imagePaths;

  /// Indique si l'opération a réussi
  final bool success;

  /// Message d'erreur si applicable
  final String? errorMessage;

  const CaptureHelperScanResult({
    required this.imagePaths,
    required this.success,
    this.errorMessage,
  });

  /// Crée un résultat réussi
  factory CaptureHelperScanResult.success(List<String> imagePaths) {
    return CaptureHelperScanResult(
      imagePaths: imagePaths,
      success: true,
    );
  }

  /// Crée un résultat d'échec
  factory CaptureHelperScanResult.failure(String errorMessage) {
    return CaptureHelperScanResult(
      imagePaths: [],
      success: false,
      errorMessage: errorMessage,
    );
  }

  /// Crée un résultat d'annulation par l'utilisateur
  factory CaptureHelperScanResult.cancelled() {
    return const CaptureHelperScanResult(
      imagePaths: [],
      success: false,
      errorMessage: 'User cancelled document scanning',
    );
  }

  /// Nombre d'images scannées
  int get imageCount => imagePaths.length;

  /// Vérifie si l'utilisateur a annulé
  bool get wasCancelled => !success && errorMessage?.contains('cancel') == true;

  @override
  String toString() => 'CaptureHelperScanResult(success: $success, imageCount: $imageCount, errorMessage: $errorMessage)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CaptureHelperScanResult &&
        other.success == success &&
        other.errorMessage == errorMessage &&
        _listEquals(other.imagePaths, imagePaths);
  }

  @override
  int get hashCode => success.hashCode ^ errorMessage.hashCode ^ imagePaths.hashCode;

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
