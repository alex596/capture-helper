# Capture Helper - Documentation technique

Ce document décrit l'implémentation actuelle du plugin `capture_helper` (version 1.2.0) : architecture,
communication Flutter ↔ natif, comportement de chaque plateforme, outillage et règles de maintenance.

Pour l'utilisation du plugin, voir le [README](../README.md). Pour l'historique, voir le
[CHANGELOG](../CHANGELOG.md). Pour les spécifications fonctionnelles, voir [SPECS.md](SPECS.md).

## 📋 Vue d'ensemble

`capture_helper` fournit la numérisation de documents et la compression d'images/PDF en s'appuyant
exclusivement sur les APIs natives :

- **iOS** : VisionKit (`VNDocumentCameraViewController`) et PDFKit
- **Android** : ML Kit Document Scanner (`GmsDocumentScanning`)
- **Communication** : [Pigeon](https://pub.dev/packages/pigeon), code généré et type-safe

Tout le traitement est local : aucune donnée n'est envoyée vers un serveur.

## 🧰 Prérequis et versions

| Élément | Version |
|---------|---------|
| Flutter | 3.44+ |
| Dart | 3.12+ |
| iOS | 13.0+ (appareil physique pour scanner) |
| Android | API 24+ (`minSdk`), `compileSdk` 36, Google Play Services |
| Java (build Android) | 17+ (21 recommandé) |
| Pigeon | 29.x |
| ML Kit Document Scanner | `play-services-mlkit-document-scanner:16.0.0` |

Versions utilisées par l'application exemple : AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1.

## 🏗️ Architecture

```
capture_helper/
├── lib/
│   ├── capture_helper.dart                   # API publique : singleton CaptureHelper
│   └── src/
│       ├── models/
│       │   ├── scan_options.dart             # CaptureHelperScanOptions
│       │   ├── scan_result.dart              # CaptureHelperScanResult
│       │   ├── compression_result.dart       # CaptureHelperCompressionResult
│       │   └── output_format.dart            # OutputFormat (jpeg, png)
│       └── generated/
│           └── document_scanner_api.g.dart   # Généré par Pigeon
├── pigeons/
│   └── document_scanner_api.dart             # Source de vérité de l'API native
├── scripts/
│   └── generate_pigeon.sh                    # Régénération du code Pigeon
├── android/
│   ├── build.gradle                          # AGP 9, Kotlin intégré
│   └── src/
│       ├── main/AndroidManifest.xml          # Permission CAMERA
│       ├── main/kotlin/com/flutter/plugin/helper/capture_helper/
│       │   ├── CaptureHelperPlugin.kt        # Implémente DocumentScannerApi
│       │   └── generated/DocumentScannerApi.g.kt
│       └── test/kotlin/.../CaptureHelperPluginTest.kt
├── ios/
│   ├── capture_helper.podspec                # Intégration CocoaPods
│   └── capture_helper/                       # Swift Package (SPM)
│       ├── Package.swift
│       └── Sources/capture_helper/
│           ├── CaptureHelperPlugin.swift     # Implémente DocumentScannerApi
│           ├── PrivacyInfo.xcprivacy
│           ├── Services/
│           │   ├── DocumentScannerService.swift
│           │   ├── ImageCompressionService.swift
│           │   ├── OutputDirectory.swift     # Répertoire de sortie (cache)
│           │   ├── PDFCompressionService.swift
│           │   └── PermissionManager.swift
│           └── Generated/DocumentScannerApi.g.swift
├── test/capture_helper_test.dart             # Tests Dart
├── example/                                  # Application de démonstration
└── .github/workflows/ci.yml                  # Intégration continue
```

### Flux d'un scan

```
App Flutter
  └─ CaptureHelper().scanDocument(options)
       └─ DocumentScannerApi.scanDocument(ScanOptions)        (Dart généré)
            └─ BasicMessageChannel "dev.flutter.pigeon.capture_helper.DocumentScannerApi.scanDocument"
                 ├─ iOS     : CaptureHelperPlugin.scanDocument → permission caméra → VisionKit
                 └─ Android : CaptureHelperPlugin.scanDocument → ML Kit (startIntentSenderForResult)
            ◄─ ScanResult(imagePaths, success, errorMessage)
       ◄─ CaptureHelperScanResult
```

## 🕊️ API Pigeon

Fichier source : `pigeons/document_scanner_api.dart`.

```dart
class ScanOptions {
  final bool autoCompress;        // Compression après le scan
  final int compressionQuality;   // 0-100
  final String outputFormat;      // 'jpeg' ou 'png'
  final bool useAutomaticCapture; // Capture automatique (Android uniquement)
  final int pageLimit;            // 0 = illimité
}

class ScanResult {
  final List<String?> imagePaths;
  final bool success;
  final String? errorMessage;
}

class CompressionResult {
  final String? outputPath;
  final int originalSize;
  final int compressedSize;
  final bool success;
  final String? errorMessage;
}

@HostApi()
abstract class DocumentScannerApi {
  @asyncCallback
  ScanResult scanDocument(ScanOptions options);

  @asyncCallback
  CompressionResult compressImage(String imagePath, int quality);

  @asyncCallback
  CompressionResult compressPdf(String pdfPath, int quality);

  bool isScanningAvailable();
}
```

Fichiers générés (ne jamais les modifier à la main) :

| Plateforme | Fichier |
|------------|---------|
| Dart | `lib/src/generated/document_scanner_api.g.dart` |
| Kotlin | `android/src/main/kotlin/com/flutter/plugin/helper/capture_helper/generated/DocumentScannerApi.g.kt` (package `...capture_helper.generated`) |
| Swift | `ios/capture_helper/Sources/capture_helper/Generated/DocumentScannerApi.g.swift` |

### Règles Pigeon

- **Modifier l'API** : éditer `pigeons/document_scanner_api.dart`, puis lancer `./scripts/generate_pigeon.sh`.
- **`@asyncCallback` plutôt que `@async`** : depuis Pigeon 28, `@async` génère des `suspend fun` Kotlin
  (dépendance aux coroutines) et des signatures `async throws` en Swift. `@asyncCallback` conserve les
  signatures à callback, `(Result<T>) -> Unit` en Kotlin et `completion:` en Swift.
- **Toujours passer par l'interface générée** : les deux plateformes implémentent `DocumentScannerApi` et
  l'enregistrent avec `DocumentScannerApi.setUp(...)` / `DocumentScannerApiSetup.setUp(...)`. Ne pas
  réintroduire de `BasicMessageChannel` ni de codec écrit à la main : avant la 1.2.0, un codec Kotlin
  maison décodait mal `[ScanOptions]`, et toutes les options de scan étaient ignorées sur Android.
- **Dépendance `meta`** : le code Dart généré importe `package:meta`, qui doit rester déclaré dans les
  `dependencies` du `pubspec.yaml` (sinon `flutter pub publish` échoue).

## 🎯 Couche Dart

### `CaptureHelper`

Singleton (`CaptureHelper()` retourne toujours la même instance) qui encapsule `DocumentScannerApi`.

| Méthode | Comportement |
|---------|--------------|
| `isScanningAvailable()` | Retourne `false` en cas d'exception |
| `scanDocument({options})` | Convertit `CaptureHelperScanOptions` → `ScanOptions` ; toute exception (dont `PlatformException`) est convertie en `CaptureHelperScanResult.failure('Failed to scan document: …')` |
| `compressImage({imagePath, quality})` | `assert` sur `quality` (0-100) ; exception → `CaptureHelperCompressionResult.failure` |
| `compressPdf({pdfPath, quality})` | Idem |

Les méthodes publiques **ne lèvent jamais d'exception** : l'appelant teste toujours `success` et
`errorMessage`.

### Modèles

- **`CaptureHelperScanOptions`** : valeurs par défaut `autoCompress: false`, `compressionQuality: 80`,
  `outputFormat: OutputFormat.jpeg`, `useAutomaticCapture: true`, `pageLimit: 0`. Des `assert` vérifient
  que `compressionQuality` est entre 0 et 100 et que `pageLimit` vaut au moins 0. Implémente `copyWith`, `==`
  et `hashCode`.
- **`CaptureHelperScanResult`** : `imagePaths`, `success`, `errorMessage`, `imageCount`. `wasCancelled`
  est déduit du message d'erreur (`!success` et message contenant `cancel`) : les messages d'annulation
  natifs doivent donc conserver ce mot.
- **`CaptureHelperCompressionResult`** : tailles en octets, plus `compressionRatio`, `reductionPercentage`,
  `savedBytes` et des tailles formatées (`formattedOriginalSize`…).

## 🍎 Implémentation iOS

### Enregistrement

`CaptureHelperPlugin.register(with:)` appelle `DocumentScannerApiSetup.setUp(binaryMessenger:api:)`.

### Déroulé d'un scan

1. **Permission caméra** (`PermissionManager`) : `AVCaptureDevice.authorizationStatus(for: .video)`.
   Si le statut est `.notDetermined`, la permission est demandée avec `requestAccess`. Un refus ou une
   restriction renvoie un `ScanResult` en échec.
2. **View controller de présentation** : fenêtre `isKeyWindow` des `UIWindowScene` connectées, puis
   remontée des `presentedViewController` jusqu'au contrôleur au premier plan. Cette recherche est
   compatible avec le cycle de vie UIScene et permet de présenter le scanner par-dessus un écran modal.
3. **VisionKit** : `DocumentScannerService` présente un `VNDocumentCameraViewController`. La capture
   automatique ne peut pas être désactivée sur iOS : `useAutomaticCapture` est ignoré.
4. **Résultat** : seules les `pageLimit` premières pages sont conservées (VisionKit ne permet pas de
   bloquer la prise de vue au-delà).
5. **Enregistrement** : dans le répertoire de sortie du plugin (voir [Stockage des fichiers](#-stockage-des-fichiers)),
   nommé `scan_<timestamp>_<index>.jpg` (JPEG qualité 1.0) ou `.png`.
6. **Compression automatique** : si `autoCompress` vaut `true`, chaque image passe par
   `ImageCompressionService`. En cas d'échec, l'image d'origine est conservée.

### Compression

- **Image** (`ImageCompressionService`) : JPEG recompressé avec `quality / 100`. Pour un PNG, la qualité
  est sans effet (compression sans perte). Le fichier de sortie `<nom source>_compressed.<ext>` est écrit
  dans le répertoire de sortie du plugin, quel que soit l'emplacement de la source.
- **PDF** (`PDFCompressionService`) : chaque page est rendue en image (`UIGraphicsImageRenderer`),
  recompressée en JPEG, puis réassemblée dans un nouveau PDF (`UIGraphicsBeginPDFContextToData`). Le texte
  du PDF n'est donc plus sélectionnable après compression.

### Distribution : SPM et CocoaPods

Le plugin doit rester compatible avec les deux gestionnaires de dépendances :

- **Swift Package Manager** (par défaut depuis Flutter 3.44) : `ios/capture_helper/Package.swift`, produit
  `capture-helper`, cible `capture_helper`, dépendance `FlutterFramework` (`../FlutterFramework`).
- **CocoaPods** : `ios/capture_helper.podspec`, sources `capture_helper/Sources/capture_helper/**/*.swift`,
  et privacy manifest embarqué via le bundle `capture_helper_privacy`.

Toute nouvelle source Swift va dans `ios/capture_helper/Sources/capture_helper/`.

### Privacy manifest

`PrivacyInfo.xcprivacy` déclare :
- aucun tracking ni donnée collectée ;
- `NSPrivacyAccessedAPICategoryFileTimestamp`, raison `C617.1` : `FileManager.attributesOfItem` sert à
  lire la taille des fichiers du conteneur de l'app pendant la compression.

Toute nouvelle API « required reason » (horodatage, espace disque, `UserDefaults`…) doit y être déclarée.

L'application hôte doit définir `NSCameraUsageDescription` dans son `Info.plist`.

## 🤖 Implémentation Android

### Enregistrement et cycle de vie

- `onAttachedToEngine` conserve l'`applicationContext` et appelle `DocumentScannerApi.setUp(messenger, this)`.
- `ActivityAware` : l'activité et l'`ActivityPluginBinding` sont conservées pour lancer le scanner. Le
  `ActivityResultListener` est retiré au détachement.

### Déroulé d'un scan

1. **Contrôles** : sans activité, `FlutterError("NO_ACTIVITY")` ; si un scan est déjà en cours,
   `FlutterError("ALREADY_ACTIVE")`.
2. **Configuration ML Kit** (`GmsDocumentScannerOptions.Builder`) :
   - `setGalleryImportAllowed(false)`
   - `setResultFormats(RESULT_FORMAT_JPEG, RESULT_FORMAT_PDF)`
   - `setPageLimit(pageLimit)` seulement si `pageLimit > 0` (sinon ML Kit n'est limité que par les
     ressources de l'appareil)
   - `setScannerMode(SCANNER_MODE_FULL)` si `useAutomaticCapture`, sinon `SCANNER_MODE_BASE`
3. **Lancement** : `getStartScanIntent(activity)` puis `startIntentSenderForResult(..., REQUEST_CODE_SCAN = 100)`.
4. **Résultat** (`onActivityResult`) : chaque page (`imageUri`) est décodée en `Bitmap` puis réencodée en
   JPEG qualité 100 ou en PNG, dans le répertoire de sortie du plugin, sous le nom
   `scan_<timestamp>_<index>.jpg|png`.
5. **Compression automatique** : si `autoCompress` vaut `true`, chaque image passe par la même logique
   que `compressImage`. En cas d'échec, l'image d'origine est conservée (même comportement qu'iOS).

> ⚠️ **Points d'attention**
> - `SCANNER_MODE_BASE` désactive les filtres et le nettoyage d'image de ML Kit. La documentation
>   ML Kit n'indique pas qu'il désactive la capture automatique : ce comportement doit être vérifié
>   sur un appareil.

### Compression

- **Image** : `BitmapFactory.decodeFile` puis `Bitmap.compress` (JPEG avec la qualité demandée, PNG sans
  perte), dans le répertoire de sortie du plugin, sous le nom `<nom source>_compressed.jpg|png` (même
  nommage qu'iOS).
- **PDF** : non supporté. `compressPdf` retourne un `CompressionResult` en échec
  (`"PDF compression is not supported on Android"`).

### Configuration Gradle

- `android/build.gradle` : AGP 9.1.0 et KGP 2.4.0 dans le `buildscript`, **sans** plugin `kotlin-android`
  (Kotlin intégré à AGP 9). La cible JVM est définie avec `kotlin { compilerOptions { jvmTarget = JVM_17 } }`.
- Le plugin compile avec `android.builtInKotlin=true` comme `false` dans l'application hôte.
- Seule permission : `android.permission.CAMERA` (`uses-feature camera` non requis). Pas de permission de
  stockage, car les fichiers restent dans le répertoire privé de l'app.

## 💾 Stockage des fichiers

Tous les fichiers produits par le plugin (pages scannées et fichiers compressés) sont écrits dans un
sous-dossier dédié du **cache** de l'application :

| Plateforme | Répertoire | Implémentation |
|------------|-----------|----------------|
| iOS | `Library/Caches/capture_helper/` | `OutputDirectory.url()` |
| Android | `cacheDir/capture_helper/` | `CaptureHelperPlugin.outputDirectory(context)` |

**Pourquoi le cache ?**
- Le plugin renvoie des **chemins de fichiers** destinés à être consommés tout de suite (envoi, affichage,
  génération de PDF…). C'est la convention des plugins qui renvoient des fichiers (`image_picker`,
  `file_picker`).
- **Pas d'accumulation** : le système peut purger le cache en cas de manque d'espace, et l'utilisateur
  peut le vider. Les fichiers ne s'entassent pas indéfiniment si l'app oublie de les supprimer.
- **Confidentialité** : des documents sensibles (pièces d'identité, contrats) ne restent pas stockés
  durablement sans que l'app l'ait décidé. Sur iOS, `Caches` est aussi exclu des sauvegardes iCloud.
- **Même comportement sur les deux plateformes**, grâce au sous-dossier dédié, qui pourra aussi être
  vidé par une future API de nettoyage.
- Sur iOS, `Caches` a été préféré à `tmp/`, que le système peut vider dès que l'app est suspendue.

**Conséquence pour l'application hôte** : elle doit **copier** les fichiers qu'elle veut conserver,
par exemple dans `getApplicationDocumentsDirectory()` (package `path_provider`).

Avant la 1.2.0, iOS écrivait dans `tmp/` (et à côté de la source pour les compressions), et Android dans
`filesDir`, de façon persistante.

## 📊 Comportements par plateforme

| Fonctionnalité | iOS | Android |
|----------------|-----|---------|
| `useAutomaticCapture: false` | Ignoré (capture toujours automatique) | `SCANNER_MODE_BASE` (à vérifier) |
| `pageLimit: N` | Le scanner reste ouvert ; seules les N premières pages sont retournées | Le scanner se ferme après N pages |
| `outputFormat: png` | ✅ | ✅ |
| `autoCompress: true` | ✅ | ✅ |
| `compressImage` | ✅ | ✅ |
| `compressPdf` | ✅ (pages rastérisées) | ❌ Échec explicite |
| Emplacement des fichiers produits | `Library/Caches/capture_helper/` | `cacheDir/capture_helper/` |
| Import depuis la galerie | Non | Désactivé |

## ⚠️ Messages d'erreur

| Message | Plateforme | Cause |
|---------|-----------|-------|
| `Document scanning not supported on this device` | iOS | VisionKit indisponible (simulateur) |
| `User cancelled document scanning` | iOS | Annulation par l'utilisateur |
| `User cancelled` | Android | Annulation par l'utilisateur |
| `No images were scanned` / `No pages scanned` | iOS / Android | Aucune page retournée |
| `No view controller available` / `Failed to present scanner` | iOS | Impossible de présenter le scanner |
| `Failed to scan document: PlatformException(NO_ACTIVITY, …)` | Android | Plugin non attaché à une activité |
| `Failed to scan document: PlatformException(ALREADY_ACTIVE, …)` | Android | Scan déjà en cours |
| `Failed to scan document: PlatformException(SCAN_ERROR, …)` | Android | Échec d'initialisation de ML Kit (Google Play Services) |
| `Failed to save images: …` | Android | Erreur d'écriture des pages |
| `Source file does not exist` | Les deux | Chemin invalide passé à `compressImage` |
| `PDF compression is not supported on Android` | Android | `compressPdf` appelé sur Android |

## 🛠️ Outillage

```bash
flutter pub get
flutter analyze                       # 0 issue attendu
dart format .                         # les *.g.dart sont exclus du contrôle CI
flutter test                          # tests Dart
./scripts/generate_pigeon.sh          # après toute modification de pigeons/

# Application exemple
cd example && flutter run
cd example && flutter build apk --debug
cd example && flutter build ios --no-codesign --debug      # via SPM

# Tests unitaires Kotlin (après un premier build Android de l'exemple)
cd example/android && ./gradlew :capture_helper:testDebugUnitTest

# Validation CocoaPods
pod lib lint ios/capture_helper.podspec --configuration=Debug --skip-tests --use-modular-headers --use-libraries --allow-warnings

# Validation avant publication
flutter pub publish --dry-run
```

**Tester CocoaPods** : l'exemple est migré en SPM et ne peut plus servir à valider CocoaPods. Il faut
utiliser une application de test qui consomme le plugin en `path:`, avec dans son `pubspec.yaml` :

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

### Intégration continue

`.github/workflows/ci.yml`, déclenchée sur les pull requests et les pushs sur `main` :

| Job | Contenu |
|-----|---------|
| `dart` | Formatage, `flutter analyze`, `flutter test` sur Flutter 3.44.x et stable, plus `pub publish --dry-run` sur stable |
| `android` | Build APK de l'exemple (JDK 21) et tests unitaires Kotlin |
| `ios` | Build iOS de l'exemple (SPM) et `pod lib lint` |

## 🧪 Tests

| Fichier | Portée |
|---------|--------|
| `test/capture_helper_test.dart` | Modèles Dart (options, résultats, formatage, ratios) et singleton |
| `android/src/test/.../CaptureHelperPluginTest.kt` | `isScanningAvailable`, `scanDocument` sans activité, `compressImage` sur un fichier absent, `compressPdf` |
| `example/integration_test/plugin_integration_test.dart` | Disponibilité de l'API sur appareil |

La numérisation réelle demande une interaction utilisateur et un **appareil physique** : elle se valide
manuellement avec l'application exemple, sur iOS et Android, avant chaque publication.

## 🔒 Sécurité et confidentialité

- **Traitement 100 % local** : aucun appel réseau.
- **Permissions minimales** : caméra uniquement.
- **Stockage privé et temporaire** : les fichiers restent dans le cache de l'app
  (`capture_helper/`). Le système peut les purger, et l'application hôte copie ceux qu'elle veut garder.
- **Privacy manifest iOS** à jour (voir plus haut).
- **Contact public** : `support@alexislouis.xyz`. Aucune adresse personnelle ne doit apparaître dans les
  fichiers du package (podspec, README…).

## 📝 Limitations connues et pistes d'évolution

### Limitations
- iOS : capture automatique non désactivable et `pageLimit` appliqué après coup (limites de VisionKit).
- Les fichiers produits sont temporaires (cache) : l'application doit les copier pour les conserver.
- Android : `compressPdf` non implémenté.
- Un seul scan actif à la fois.

### Pistes
- API `clearTemporaryFiles()` pour vider le répertoire `capture_helper/` du cache.
- Compression PDF sur Android (`PdfRenderer` + `PdfDocument`).
- OCR optionnel, génération de PDF à partir des scans.
