# 🚀 Capture Helper - Aide-mémoire rapide

Guide de référence rapide pour `capture_helper`.

## Installation

```yaml
# pubspec.yaml
dependencies:
  capture_helper: ^1.2.0
```

```bash
flutter pub get
```

## Import

```dart
import 'package:capture_helper/capture_helper.dart';
```

## Commandes essentielles

### ✅ Vérifier la disponibilité

```dart
final isAvailable = await CaptureHelper().isScanningAvailable();
```

### 📸 Scanner un document

```dart
// Simple
final result = await CaptureHelper().scanDocument();

// Avec options
final result = await CaptureHelper().scanDocument(
  options: CaptureHelperScanOptions(
    autoCompress: true,
    compressionQuality: 80,
    outputFormat: OutputFormat.jpeg, // ou OutputFormat.png
    useAutomaticCapture: false,      // capture manuelle (Android uniquement)
    pageLimit: 3,                    // 0 = illimité
  ),
);
```

### 🗜️ Compresser une image

```dart
final result = await CaptureHelper().compressImage(
  imagePath: '/path/to/image.jpg',
  quality: 80, // 0-100
);
```

### 📄 Compresser un PDF

```dart
final result = await CaptureHelper().compressPdf(
  pdfPath: '/path/to/document.pdf',
  quality: 75,
);
```

### 🧹 Nettoyer les fichiers temporaires

```dart
// Les fichiers produits sont dans le cache (capture_helper/) : copiez ceux à conserver, puis
await CaptureHelper().clearTemporaryFiles();
```

## Résultats

### ScanResult

```dart
if (result.success) {
  result.imagePaths;     // List<String>
  result.imageCount;     // int
} else if (result.wasCancelled) {
  // Utilisateur a annulé
} else {
  result.errorMessage;   // String?
}
```

### CompressionResult

```dart
if (result.success) {
  result.outputPath;              // String?
  result.originalSize;            // int
  result.compressedSize;          // int
  result.reductionPercentage;     // double
  result.formattedOriginalSize;   // String
  result.formattedCompressedSize; // String
  result.formattedSavedBytes;     // String
} else {
  result.errorMessage;            // String?
}
```

## Guide de qualité

| Qualité | Usage | Taille |
|---------|-------|--------|
| 90-100 | Archivage, impression | Grande |
| 70-85 | Usage général, web | Moyenne |
| 50-70 | Email, partage | Petite |
| 10-50 | Aperçu, miniatures | Mini |

## Exemples rapides

### Scanner simple

```dart
final result = await CaptureHelper().scanDocument();
if (result.success) {
  print('Images : ${result.imagePaths}');
}
```

### Scanner + Compresser

```dart
final scan = await CaptureHelper().scanDocument();
if (scan.success) {
  for (final path in scan.imagePaths) {
    final compressed = await CaptureHelper().compressImage(
      imagePath: path,
      quality: 80,
    );
    print('Compressé : ${compressed.outputPath}');
  }
}
```

### Limite de taille

```dart
final scan = await CaptureHelper().scanDocument(
  options: CaptureHelperScanOptions(
    autoCompress: true,
    compressionQuality: 60, // Ajuster selon besoin
  ),
);
```

## Gestion d'erreurs

```dart
try {
  final result = await CaptureHelper().scanDocument();

  if (!result.success) {
    if (result.wasCancelled) {
      print('Annulé');
    } else {
      print('Erreur : ${result.errorMessage}');
    }
  }
} catch (e) {
  print('Exception : $e');
}
```

## Configuration

### iOS (Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>Pour scanner des documents</string>
```

### Android (automatique)

Permission ajoutée automatiquement :
- `CAMERA` (seule permission requise, les images sont stockées dans le répertoire privé de l'app)

## Contraintes

| Plateforme | Min Version | Notes |
|------------|-------------|-------|
| Flutter | 3.44+ | Dart 3.12+ |
| iOS | 13.0+ | VisionKit, appareil physique requis, SPM et CocoaPods |
| Android | API 24+ | ML Kit, Google Play Services requis |

## Liens utiles

- [README complet](README.md)
- [Exemples détaillés](EXAMPLES.md)
- [Historique des versions](CHANGELOG.md)
- [Spécifications fonctionnelles](doc/SPECS.md)

---

💡 **Astuce** : Pour plus d'exemples, consultez [EXAMPLES.md](EXAMPLES.md)
