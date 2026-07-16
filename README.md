# Capture Helper

Un plugin Flutter pour la numérisation de documents avec compression d'images intégrée, utilisant VisionKit (iOS) et ML Kit Document Scanner (Android).

## 📋 Table des matières

- [Fonctionnalités](#fonctionnalités)
- [Plateformes supportées](#plateformes-supportées)
- [Installation](#installation)
- [Configuration](#configuration)
- [🚀 Démarrage rapide](#-démarrage-rapide)
- [Utilisation](#utilisation)
  - [📸 Scanner une image simple](#-scanner-une-image-simple)
  - [📦 Scanner avec compression automatique](#-scanner-avec-compression-automatique)
  - [🗜️ Compresser une image existante](#%EF%B8%8F-compresser-une-image-existante)
  - [📏 Scanner avec limite de poids](#-scanner-avec-limite-de-poids)
  - [🎯 Guide de qualité de compression](#-guide-de-qualité-de-compression)
  - [📋 Exemple complet](#-exemple-complet-avec-gestion-derreurs)
- [API](#api)
- [Limitations](#limitations)
- [📚 Plus d'exemples](#-plus-dexemples)

## 📚 Documentation complète

- **[CHEATSHEET.md](CHEATSHEET.md)** - Aide-mémoire rapide avec toutes les commandes
- **[EXAMPLES.md](EXAMPLES.md)** - Exemples de code détaillés pour tous les cas d'usage
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Guide de résolution des problèmes
- **[docs/TECHS.md](docs/TECHS.md)** - Documentation technique complète

## Fonctionnalités

- ✅ **Numérisation de documents** avec détection automatique des bords
- ✅ **Support multi-pages** en une seule session
- ✅ **4 modes de capture** : Auto/Manuel × Single/Multi-pages
- ✅ **Auto-capture** avec timer visuel après stabilisation du document
- ✅ **Contrôle qualité** : netteté, luminosité, couverture du document
- ✅ **Ajustement des coins** avec correction de perspective
- ✅ **Compression d'images** avec contrôle de la qualité
- ✅ **Compression PDF** pour réduire la taille des fichiers
- ✅ **Interface native** sur iOS et Android
- ✅ **Gestion automatique des permissions** caméra
- ✅ **Architecture propre** basée sur Pigeon

## Plateformes supportées

| Plateforme | Version minimale | API native |
|------------|------------------|------------|
| iOS        | 13.0+           | VisionKit  |
| Android    | API 21+ (5.0)   | ML Kit     |

## Installation

Ajoutez cette ligne à votre fichier `pubspec.yaml` :

```yaml
dependencies:
  capture_helper:
    path: ../capture_helper
```

Puis exécutez :

```bash
flutter pub get
```

## Configuration

### iOS

Ajoutez la permission caméra dans votre `ios/Runner/Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan documents</string>
```

### Android

Les permissions sont automatiquement ajoutées via le manifest du plugin. Assurez-vous que votre `android/build.gradle` a les bonnes configurations :

```gradle
android {
    compileSdkVersion 36
    minSdkVersion 24
}
```

**⚠️ Important : Version Java**

Ce plugin nécessite Java 17, 21 ou 23. Java 24 n'est pas encore compatible avec Gradle 8.12.

```bash
# Vérifier votre version Java
flutter doctor -v

# Si vous avez Java 24, installer Java 21 (recommandé)
# macOS avec Homebrew :
brew install openjdk@21
flutter config --jdk-dir=/opt/homebrew/opt/openjdk@21
```

Pour plus de détails, consultez [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## 🚀 Démarrage rapide

```dart
import 'package:capture_helper/capture_helper.dart';

// 1. Scanner un document
final result = await CaptureHelper().scanDocument();

// 2. Compresser l'image
if (result.success && result.imagePaths.isNotEmpty) {
  final compressed = await CaptureHelper().compressImage(
    imagePath: result.imagePaths.first,
    quality: 80,
  );
  print('Image compressée : ${compressed.outputPath}');
}
```

## Utilisation

### 📸 Scanner une image simple

Scanner un document et récupérer les images sans compression automatique :

```dart
import 'package:capture_helper/capture_helper.dart';

final captureHelper = CaptureHelper();

// Vérifier d'abord si le scanner est disponible
final isAvailable = await captureHelper.isScanningAvailable();

if (!isAvailable) {
  print('Scanner non disponible sur cet appareil');
  return;
}

// Scanner le document
final result = await captureHelper.scanDocument(
  options: const CaptureHelperScanOptions(
    autoCompress: false,  // Pas de compression automatique
    compressionQuality: 80,
  ),
);

// Vérifier le résultat
if (result.success) {
  print('✅ Scan réussi ! ${result.imageCount} image(s) scannée(s)');

  for (final imagePath in result.imagePaths) {
    print('📄 Image : $imagePath');
  }
} else if (result.wasCancelled) {
  print('❌ Scan annulé par l\'utilisateur');
} else {
  print('❌ Erreur : ${result.errorMessage}');
}
```

### 📦 Scanner avec compression automatique

Scanner et compresser automatiquement les images pendant le scan :

```dart
final result = await captureHelper.scanDocument(
  options: const CaptureHelperScanOptions(
    autoCompress: true,           // Active la compression automatique
    compressionQuality: 70,        // Qualité de compression (0-100)
    outputFormat: OutputFormat.jpeg, // Format de sortie (jpeg ou png)
  ),
);

if (result.success) {
  print('✅ Images scannées et compressées automatiquement');
  print('📁 ${result.imageCount} image(s) dans: ${result.imagePaths}');
}
```

### 🎨 Choisir le format de sortie (JPEG vs PNG)

Le plugin supporte deux formats de sortie :

```dart
// Format JPEG (par défaut) - Plus léger, compression avec perte
final resultJPEG = await captureHelper.scanDocument(
  options: const CaptureHelperScanOptions(
    outputFormat: OutputFormat.jpeg,
    compressionQuality: 80,
  ),
);

// Format PNG - Plus lourd, compression sans perte
// Idéal pour schémas, diagrammes, ou quand la netteté est cruciale
final resultPNG = await captureHelper.scanDocument(
  options: const CaptureHelperScanOptions(
    outputFormat: OutputFormat.png,
    // Note: compressionQuality n'a pas d'effet sur PNG (toujours qualité maximale)
  ),
);
```

**Quand utiliser PNG ?**
- Schémas techniques, diagrammes, graphiques
- Documents avec texte très fin à OCR
- Besoin de qualité maximale sans artefacts
- ⚠️ Fichiers 3-5x plus lourds que JPEG

**Quand utiliser JPEG ?**
- Documents scannés standards (recommandé)
- Photos de documents
- Fichiers plus légers pour le stockage/partage
- Qualité largement suffisante pour la lecture

### 🗜️ Compresser une image existante

Compresser une image déjà scannée pour réduire sa taille :

```dart
// Compresser avec qualité moyenne (recommandé pour usage général)
final compressionResult = await captureHelper.compressImage(
  imagePath: '/path/to/your/image.jpg',
  quality: 80, // Qualité : 0 (min) à 100 (max)
);

if (compressionResult.success) {
  print('✅ Compression réussie !');
  print('📁 Fichier compressé : ${compressionResult.outputPath}');
  print('📊 Statistiques :');
  print('   Taille originale : ${compressionResult.formattedOriginalSize}');
  print('   Taille compressée : ${compressionResult.formattedCompressedSize}');
  print('   Économie : ${compressionResult.formattedSavedBytes}');
  print('   Réduction : ${compressionResult.reductionPercentage.toStringAsFixed(1)}%');
} else {
  print('❌ Erreur de compression : ${compressionResult.errorMessage}');
}
```

### 📏 Scanner avec limite de poids

Pour contrôler la taille des images scannées, utilisez la compression automatique avec une qualité appropriée :

```dart
// Exemple : limiter les images à ~500 KB par page
final result = await captureHelper.scanDocument(
  options: const CaptureHelperScanOptions(
    autoCompress: true,
    compressionQuality: 60,  // Ajuster selon la taille souhaitée
  ),
);

// Vérifier la taille des fichiers générés
if (result.success) {
  for (final imagePath in result.imagePaths) {
    final file = File(imagePath);
    final sizeInBytes = await file.length();
    final sizeInKB = sizeInBytes / 1024;
    print('📄 Image : ${sizeInKB.toStringAsFixed(0)} KB');

    // Si trop grande, compresser davantage
    if (sizeInKB > 500) {
      final compressed = await captureHelper.compressImage(
        imagePath: imagePath,
        quality: 50, // Compression plus agressive
      );
      print('   ➡️ Recompressée à ${compressed.formattedCompressedSize}');
    }
  }
}
```

### 🎯 Guide de qualité de compression

Choisissez la qualité selon votre cas d'usage :

```dart
// Qualité haute (85-100) - Pour impression ou archivage
await captureHelper.compressImage(imagePath: path, quality: 90);

// Qualité moyenne (70-85) - Pour usage général, web
await captureHelper.compressImage(imagePath: path, quality: 80);

// Qualité basse (50-70) - Pour email, partage rapide
await captureHelper.compressImage(imagePath: path, quality: 60);

// Qualité minimale (10-50) - Pour aperçus, miniatures
await captureHelper.compressImage(imagePath: path, quality: 40);
```

### 📋 Exemple complet avec gestion d'erreurs

```dart
import 'dart:io';
import 'package:capture_helper/capture_helper.dart';

Future<void> scanAndCompressDocument() async {
  final captureHelper = CaptureHelper();

  try {
    // 1. Vérifier la disponibilité
    if (!await captureHelper.isScanningAvailable()) {
      throw Exception('Scanner non disponible');
    }

    // 2. Scanner le document
    print('📸 Lancement du scanner...');
    final scanResult = await captureHelper.scanDocument(
      options: const CaptureHelperScanOptions(
        autoCompress: false,
        compressionQuality: 80,
      ),
    );

    if (!scanResult.success) {
      if (scanResult.wasCancelled) {
        print('❌ Scan annulé');
        return;
      }
      throw Exception(scanResult.errorMessage);
    }

    print('✅ ${scanResult.imageCount} image(s) scannée(s)');

    // 3. Compresser chaque image
    for (int i = 0; i < scanResult.imagePaths.length; i++) {
      final imagePath = scanResult.imagePaths[i];
      print('\n🗜️ Compression de l\'image ${i + 1}...');

      final compressionResult = await captureHelper.compressImage(
        imagePath: imagePath,
        quality: 75,
      );

      if (compressionResult.success) {
        print('   ✅ Compressée : ${compressionResult.reductionPercentage.toStringAsFixed(1)}% de réduction');
        print('   📁 Fichier : ${compressionResult.outputPath}');
      } else {
        print('   ⚠️ Échec compression : ${compressionResult.errorMessage}');
      }
    }

    print('\n🎉 Traitement terminé !');

  } catch (e) {
    print('❌ Erreur : $e');
  }
}
```

### 📄 Compression de PDF

Pour compresser un document PDF (iOS uniquement pour l'instant) :

```dart
final pdfResult = await captureHelper.compressPdf(
  pdfPath: '/path/to/document.pdf',
  quality: 75,
);

if (pdfResult.success) {
  print('✅ PDF compressé');
  print('📁 Nouveau fichier : ${pdfResult.outputPath}');
  print('📊 Réduction : ${pdfResult.reductionPercentage.toStringAsFixed(1)}%');
}
```

## API

### CaptureHelper

La classe principale du plugin (singleton).

#### Méthodes

- `Future<bool> isScanningAvailable()` - Vérifie si la numérisation est disponible
- `Future<CaptureHelperScanResult> scanDocument({CaptureHelperScanOptions options})` - Lance la numérisation
- `Future<CaptureHelperCompressionResult> compressImage({required String imagePath, int quality = 80})` - Compresse une image
- `Future<CaptureHelperCompressionResult> compressPdf({required String pdfPath, int quality = 80})` - Compresse un PDF

### CaptureHelperScanOptions

Options de configuration pour la numérisation.

```dart
CaptureHelperScanOptions({
  bool autoCompress = false,
  int compressionQuality = 80,    // 0-100
  OutputFormat outputFormat = OutputFormat.jpeg,

  // Mode de capture (iOS)
  CaptureMode captureMode = CaptureMode.manual,  // auto ou manual
  int pageLimit = 1,              // 1 = single page, >1 = multi-pages

  // Contrôle qualité (iOS)
  int minSharpness = 0,           // 0-100, 0 = désactivé
  int minBrightness = 0,          // 0-100, 0 = désactivé
  int minDocumentCoverage = 15,   // % min du document dans l'écran

  // Auto-capture (iOS)
  double autoCaptureDelay = 1.0,  // Délai en secondes avant capture auto
})
```

#### Modes de capture (iOS)

| Mode | Description |
|------|-------------|
| `CaptureMode.auto` | Capture automatique après stabilisation + bouton manuel disponible |
| `CaptureMode.manual` | Capture uniquement via le bouton (par défaut) |

#### Exemples de configurations

```dart
// Mode automatique single-page
CaptureHelperScanOptions(
  captureMode: CaptureMode.auto,
  pageLimit: 1,
  autoCaptureDelay: 1.5,
)

// Mode manuel multi-pages (jusqu'à 10 pages)
CaptureHelperScanOptions(
  captureMode: CaptureMode.manual,
  pageLimit: 10,
)

// Avec contrôle qualité strict
CaptureHelperScanOptions(
  minSharpness: 50,
  minBrightness: 40,
  minDocumentCoverage: 30,
)
```

### CaptureHelperScanResult

Résultat d'une numérisation.

**Propriétés :**
- `List<String> imagePaths` - Chemins des images scannées
- `bool success` - Indique si l'opération a réussi
- `String? errorMessage` - Message d'erreur éventuel
- `int imageCount` - Nombre d'images scannées
- `bool wasCancelled` - Indique si l'utilisateur a annulé

### CaptureHelperCompressionResult

Résultat d'une compression.

**Propriétés :**
- `String? outputPath` - Chemin du fichier compressé
- `int originalSize` - Taille originale en octets
- `int compressedSize` - Taille compressée en octets
- `bool success` - Indique si l'opération a réussi
- `String? errorMessage` - Message d'erreur éventuel
- `double compressionRatio` - Taux de compression (0.0-1.0)
- `double reductionPercentage` - Pourcentage de réduction
- `int savedBytes` - Octets économisés
- `String formattedOriginalSize` - Taille originale formatée
- `String formattedCompressedSize` - Taille compressée formatée
- `String formattedSavedBytes` - Économie formatée

## Architecture

Le plugin utilise **Pigeon** pour la communication type-safe entre Flutter et le code natif :

```
lib/
├── capture_helper.dart              # API publique
├── src/
│   ├── models/                      # Modèles Dart
│   │   ├── scan_options.dart
│   │   ├── scan_result.dart
│   │   └── compression_result.dart
│   └── generated/                   # Code généré par Pigeon
│       └── document_scanner_api.g.dart

ios/capture_helper/Sources/capture_helper/   # Swift Package (SPM + CocoaPods)
├── CaptureHelperPlugin.swift        # Plugin principal iOS
├── Scanner/                         # Module de scan personnalisé
│   ├── CaptureViewController.swift  # Écran de capture avec overlay
│   ├── AdjustmentViewController.swift # Ajustement des coins
│   ├── PreviewViewController.swift  # Prévisualisation
│   ├── RecapViewController.swift    # Récap multi-pages
│   ├── QualityFeedbackViewController.swift # Feedback qualité
│   ├── DocumentDetector.swift       # Détection Vision/ML
│   ├── DocumentOverlayView.swift    # Overlay de détection
│   ├── ImageQualityAnalyzer.swift   # Analyse qualité
│   ├── PerspectiveCorrector.swift   # Correction perspective
│   ├── DocumentScannerCoordinator.swift # Coordinateur de navigation
│   ├── ScanSessionManager.swift     # Gestion de session
│   └── SinglePageScannerCoordinator.swift
├── Services/
│   ├── ImageCompressionService.swift
│   ├── PDFCompressionService.swift
│   └── PermissionManager.swift
└── Generated/                       # Code généré par Pigeon
    └── DocumentScannerApi.g.swift

android/src/main/kotlin/.../
├── CaptureHelperPlugin.kt          # Plugin principal Android
├── services/
│   ├── DocumentScannerService.kt
│   ├── ImageCompressionService.kt
│   ├── PDFCompressionService.kt
│   └── PermissionManager.kt
└── generated/                       # Code généré par Pigeon
    └── DocumentScannerApi.g.kt
```

### Flow de capture iOS

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ CaptureVC       │───▶│ AdjustmentVC     │───▶│ PreviewVC       │
│ (Détection +    │    │ (Ajuster coins)  │    │ (Confirmer)     │
│  Capture)       │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        │                                              │
        │ (si qualité insuffisante)                    │
        ▼                                              ▼
┌─────────────────┐                           ┌─────────────────┐
│ QualityFeedback │                           │ RecapVC         │
│ (Reprendre ou   │                           │ (Multi-pages)   │
│  Conserver)     │                           │                 │
└─────────────────┘                           └─────────────────┘
```

## Développement

### Régénérer le code Pigeon

```bash
./scripts/generate_pigeon.sh
```

ou manuellement :

```bash
dart run pigeon --input pigeons/document_scanner_api.dart
```

### Exécuter les tests

```bash
flutter test
```

### Exécuter l'exemple

```bash
cd example
flutter run
```

## Limitations

### iOS
- Nécessite iOS 13.0 ou supérieur
- La numérisation ne fonctionne pas sur simulateur (nécessite un appareil physique)
- VisionKit requiert l'accès à la caméra

### Android
- Nécessite Android API 21 (5.0) ou supérieur
- Nécessite Google Play Services pour ML Kit
- La numérisation nécessite la permission CAMERA

## Qualité de compression recommandée

| Qualité | Usage recommandé | Taille du fichier |
|---------|------------------|-------------------|
| 85-100  | Impression, archivage | Grande |
| 70-85   | Usage général, web | Moyenne |
| 50-70   | Email, partage | Petite |
| 10-50   | Aperçu, miniatures | Très petite |

## 📚 Plus d'exemples

### Exemples de code

Consultez [EXAMPLES.md](EXAMPLES.md) pour des exemples détaillés :
- 📏 Scanner avec limite de poids
- 🔄 Compression en masse
- 📑 Scanner multi-pages
- 🎨 Interface utilisateur complète
- ⚡ Compression en arrière-plan
- Et plus encore !

### Application exemple

Consultez le dossier [example](example/) pour une application complète avec :
- Page d'accueil avec bouton de scan
- Page de détails avec visualisation d'images
- Slider de qualité de compression
- Affichage des statistiques de compression

## Licence

Ce projet est sous licence MIT.

## Auteur

**Author:** [Alexis Louis](https://alexislouis.xyz)
Développé avec ❤️ pour faciliter la numérisation de documents dans Flutter.
