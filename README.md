# Capture Helper

Un plugin Flutter pour la numérisation de documents avec compression d'images intégrée, utilisant VisionKit (iOS) et ML Kit Document Scanner (Android).

## 📋 Table des matières

- [Capture Helper](#capture-helper)
  - [📋 Table des matières](#-table-des-matières)
  - [📚 Documentation complète](#-documentation-complète)
  - [Fonctionnalités](#fonctionnalités)
  - [Plateformes supportées](#plateformes-supportées)
  - [Installation](#installation)
  - [Configuration](#configuration)
    - [iOS](#ios)
    - [Android](#android)
  - [🚀 Démarrage rapide](#-démarrage-rapide)
  - [Utilisation](#utilisation)
    - [📸 Scanner une image simple](#-scanner-une-image-simple)
    - [📦 Scanner avec compression automatique](#-scanner-avec-compression-automatique)
    - [🎨 Choisir le format de sortie (JPEG vs PNG)](#-choisir-le-format-de-sortie-jpeg-vs-png)
    - [🎯 Scanner avec limite de pages](#-scanner-avec-limite-de-pages)
    - [📸 Scanner avec capture manuelle](#-scanner-avec-capture-manuelle)
    - [🔄 Exemple complet avec toutes les options](#-exemple-complet-avec-toutes-les-options)
    - [🗜️ Compresser une image existante](#️-compresser-une-image-existante)
    - [📏 Scanner avec limite de poids](#-scanner-avec-limite-de-poids)
    - [🎯 Guide de qualité de compression](#-guide-de-qualité-de-compression)
    - [📋 Exemple complet avec gestion d'erreurs](#-exemple-complet-avec-gestion-derreurs)
    - [📄 Compression de PDF](#-compression-de-pdf)
    - [💾 Stockage des fichiers](#-stockage-des-fichiers)
  - [API](#api)
    - [CaptureHelper](#capturehelper)
      - [Méthodes](#méthodes)
    - [CaptureHelperScanOptions](#capturehelperscanoptions)
    - [CaptureHelperScanResult](#capturehelperscanresult)
    - [CaptureHelperCompressionResult](#capturehelpercompressionresult)
  - [Architecture](#architecture)
  - [Développement](#développement)
    - [Régénérer le code Pigeon](#régénérer-le-code-pigeon)
    - [Exécuter les tests](#exécuter-les-tests)
    - [Swift Package Manager et CocoaPods](#swift-package-manager-et-cocoapods)
    - [Exécuter l'exemple](#exécuter-lexemple)
  - [Limitations](#limitations)
    - [iOS](#ios-1)
    - [Android](#android-1)
  - [Qualité de compression recommandée](#qualité-de-compression-recommandée)
  - [📚 Plus d'exemples](#-plus-dexemples)
    - [Exemples de code](#exemples-de-code)
    - [Application exemple](#application-exemple)
  - [Licence](#licence)
  - [Auteur](#auteur)

## 📚 Documentation complète

- **[CHEATSHEET.md](CHEATSHEET.md)** - Aide-mémoire rapide avec toutes les commandes
- **[EXAMPLES.md](EXAMPLES.md)** - Exemples de code détaillés pour tous les cas d'usage
- **[CHANGELOG.md](CHANGELOG.md)** - Historique des versions
- **[doc/SPECS.md](doc/SPECS.md)** - Spécifications fonctionnelles
- **[doc/TECHS.md](doc/TECHS.md)** - Documentation technique (architecture, comportements par plateforme, outillage)

## Fonctionnalités

- ✅ **Numérisation de documents** avec détection automatique des bords
- ✅ **Support multi-pages** en une seule session
- ✅ **Compression d'images** avec contrôle de la qualité
- ✅ **Compression PDF** pour réduire la taille des fichiers
- ✅ **Interface native** sur iOS et Android
- ✅ **Gestion automatique des permissions** caméra
- ✅ **Architecture propre** basée sur Pigeon

## Plateformes supportées

| Plateforme | Version minimale | API native |
|------------|------------------|------------|
| Flutter    | 3.44+ (Dart 3.12+) | -        |
| iOS        | 13.0+           | VisionKit  |
| Android    | API 24+ (7.0)   | ML Kit     |

Sur iOS, le plugin supporte **Swift Package Manager** (par défaut depuis Flutter 3.44) et **CocoaPods**.

## Installation

Ajoutez cette ligne à votre fichier `pubspec.yaml` :

```yaml
dependencies:
  capture_helper: ^1.2.0
```

Ou via la ligne de commande :

```bash
flutter pub add capture_helper
```

## Configuration

### iOS

Ajoutez la permission caméra dans votre `ios/Runner/Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan documents</string>
```

### Android

La permission caméra est automatiquement ajoutée via le manifest du plugin. Assurez-vous que votre `android/app/build.gradle.kts` respecte le `minSdk` requis :

```kotlin
android {
    defaultConfig {
        minSdk = 24 // ou flutter.minSdkVersion (24 par défaut depuis Flutter 3.44)
    }
}
```

**Compatibilité Gradle / Kotlin**

- Le plugin utilise le Kotlin intégré d'AGP 9 et fonctionne avec `android.builtInKotlin=true` comme `false`.
- Java 17 minimum est requis (Java 21 recommandé). Vérifiez avec `flutter doctor -v` et, si besoin :

```bash
flutter config --jdk-dir=/chemin/vers/jdk-21
```

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

### 🎯 Scanner avec limite de pages

```dart
// Limiter à 2 pages maximum
final result = await captureHelper.scanDocument(
  options: const CaptureHelperScanOptions(
    pageLimit: 2,  // Le scanner se ferme après 2 pages (Android)
  ),
);

if (result.success) {
  print('✅ ${result.imageCount} page(s) scannée(s) (max: 2)');

  // iOS : VisionKit ne permet pas d'arrêter la capture à N pages,
  // les pages en trop sont ignorées et comptées dans ignoredPageCount
  if (result.hasIgnoredPages) {
    print('⚠️ ${result.ignoredPageCount} page(s) ignorée(s) (limite : 2)');
  }
}
```

> 💡 Sur iOS, pensez à indiquer la limite à l'utilisateur avant d'ouvrir le scanner
> (« 2 pages maximum ») : VisionKit le laisse capturer plus de pages que la limite.

### 📸 Scanner avec capture manuelle

```dart
// L'utilisateur doit appuyer sur le bouton pour capturer (Android uniquement)
final result = await captureHelper.scanDocument(
  options: const CaptureHelperScanOptions(
    useAutomaticCapture: false,  // Désactive la capture automatique
  ),
);

// Note: Sur iOS, la capture automatique est toujours activée (limitation VisionKit)
```

### 🔄 Exemple complet avec toutes les options

```dart
final result = await captureHelper.scanDocument(
  options: const CaptureHelperScanOptions(
    autoCompress: true,              // Compresser automatiquement
    compressionQuality: 75,          // Qualité moyenne
    outputFormat: OutputFormat.jpeg, // Format JPEG
    useAutomaticCapture: false,      // Capture manuelle (Android)
    pageLimit: 5,                    // Maximum 5 pages
  ),
);

if (result.success) {
  print('✅ ${result.imageCount} page(s) scannée(s)');
  print('📄 Limite: 5 pages');
  print('📸 Mode: Capture manuelle');
}
```

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

### 💾 Stockage des fichiers

Le plugin renvoie des **chemins de fichiers**. Tous les fichiers produits (pages scannées et fichiers
compressés) sont écrits dans le **cache** de l'application :

| Plateforme | Répertoire |
|------------|-----------|
| iOS | `Library/Caches/capture_helper/` |
| Android | `cacheDir/capture_helper/` |

Ces fichiers sont **temporaires** : le système peut les supprimer en cas de manque d'espace. Pour conserver
un document, copiez-le dans un répertoire persistant, par exemple avec
[`path_provider`](https://pub.dev/packages/path_provider) :

```dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final result = await CaptureHelper().scanDocument();
if (result.success) {
  final documentsDir = await getApplicationDocumentsDirectory();
  for (final imagePath in result.imagePaths) {
    await File(imagePath).copy(p.join(documentsDir.path, p.basename(imagePath)));
  }
}
```

Une fois les fichiers envoyés ou copiés, libérez l'espace avec `clearTemporaryFiles()` :

```dart
await CaptureHelper().clearTemporaryFiles(); // vide le dossier capture_helper/ du cache
```

## API

### CaptureHelper

La classe principale du plugin (singleton).

#### Méthodes

- `Future<bool> isScanningAvailable()` - Vérifie si la numérisation est disponible
- `Future<CaptureHelperScanResult> scanDocument({CaptureHelperScanOptions options})` - Lance la numérisation
- `Future<CaptureHelperCompressionResult> compressImage({required String imagePath, int quality = 80})` - Compresse une image
- `Future<CaptureHelperCompressionResult> compressPdf({required String pdfPath, int quality = 80})` - Compresse un PDF
- `Future<bool> clearTemporaryFiles()` - Supprime tous les fichiers produits par le plugin (dossier `capture_helper/` du cache)

### CaptureHelperScanOptions

Options de configuration pour la numérisation.

```dart
CaptureHelperScanOptions({
  bool autoCompress = false,          // Compression automatique après scan
  int compressionQuality = 80,         // Qualité de compression (0-100)
  OutputFormat outputFormat = OutputFormat.jpeg, // Format de sortie (jpeg/png)
  bool useAutomaticCapture = true,     // Capture auto quand document détecté
  int pageLimit = 0,                   // Limite de pages (0 = illimité)
})
```

**Nouvelles options :**

- **`useAutomaticCapture`** :
  - `true` (défaut) : La photo est prise automatiquement dès que le document est détecté
  - `false` : L'utilisateur doit appuyer manuellement sur le bouton pour capturer
  - ⚠️ **Note iOS** : VisionKit ne supporte pas la désactivation de la capture automatique. Cette option est ignorée sur iOS.
  - ✅ **Android** : Utilise `SCANNER_MODE_BASE` (mode manuel) ou `SCANNER_MODE_FULL` (mode auto)

- **`pageLimit`** :
  - `0` (défaut) : Aucune limite, l'utilisateur peut scanner autant de pages qu'il veut
  - `N > 0` : Limite le nombre de pages à N. Sur Android, le scanner se ferme automatiquement après N pages
  - ⚠️ **Note iOS** : VisionKit ne ferme pas automatiquement le scanner. Le plugin limite le nombre de pages retournées et indique le nombre de pages ignorées dans `ignoredPageCount`.

### CaptureHelperScanResult

Résultat d'une numérisation.

**Propriétés :**
- `List<String> imagePaths` - Chemins des images scannées
- `bool success` - Indique si l'opération a réussi
- `String? errorMessage` - Message d'erreur éventuel
- `int imageCount` - Nombre d'images scannées
- `int ignoredPageCount` - Pages capturées mais ignorées car au-delà de `pageLimit` (iOS uniquement, toujours 0 sur Android)
- `bool hasIgnoredPages` - Indique si des pages ont été ignorées
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

ios/
├── capture_helper.podspec           # Intégration CocoaPods
└── capture_helper/                  # Swift Package (SPM)
    ├── Package.swift
    └── Sources/capture_helper/
        ├── CaptureHelperPlugin.swift   # Plugin principal iOS
        ├── PrivacyInfo.xcprivacy       # Privacy manifest
        ├── Services/
        │   ├── DocumentScannerService.swift
        │   ├── ImageCompressionService.swift
        │   ├── OutputDirectory.swift
        │   ├── PDFCompressionService.swift
        │   └── PermissionManager.swift
        └── Generated/                  # Code généré par Pigeon
            └── DocumentScannerApi.g.swift

android/src/main/kotlin/.../
├── CaptureHelperPlugin.kt           # Plugin principal Android (implémente DocumentScannerApi)
└── generated/                       # Code généré par Pigeon
    └── DocumentScannerApi.g.kt

pigeons/
└── document_scanner_api.dart        # Définition de l'API Pigeon (source de vérité)
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
# Tests Dart
flutter test

# Tests unitaires Kotlin (après un premier build de l'exemple)
cd example/android && ./gradlew :capture_helper:testDebugUnitTest

# Validation du podspec CocoaPods
pod lib lint ios/capture_helper.podspec --configuration=Debug --skip-tests --use-modular-headers --use-libraries --allow-warnings
```

### Swift Package Manager et CocoaPods

Le plugin doit rester compatible avec les deux gestionnaires :

- **SPM** (par défaut depuis Flutter 3.44) : `cd example && flutter build ios --no-codesign`
- **CocoaPods** : tester dans une app avec `enable-swift-package-manager: false` dans la section `flutter: config:` du `pubspec.yaml`
  (l'exemple étant migré en SPM, il ne peut plus servir à tester CocoaPods)

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
- Nécessite Android API 24 (7.0) ou supérieur
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

**Contact :** [support@alexislouis.xyz](mailto:support@alexislouis.xyz)