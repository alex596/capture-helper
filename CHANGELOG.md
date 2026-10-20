# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [1.2.0] - 2026-10-20

### Ajouts
- **Capture automatique/manuelle** : Nouveau paramètre `useAutomaticCapture` dans `CaptureHelperScanOptions`
  - `true` (défaut) : La photo est prise automatiquement dès que le document est détecté
  - `false` : L'utilisateur doit appuyer manuellement sur le bouton pour capturer
  - ✅ **Android** : Pleinement fonctionnel (utilise `SCANNER_MODE_BASE` pour le mode manuel)
  - ⚠️ **iOS** : Option ignorée car VisionKit ne supporte pas la désactivation de la capture automatique

- **Limite de pages** : Nouveau paramètre `pageLimit` dans `CaptureHelperScanOptions`
  - `0` (défaut) : Aucune limite, l'utilisateur peut scanner autant de pages qu'il souhaite
  - `N > 0` : Limite le scanner à N pages maximum
  - ✅ **Android** : Le scanner se ferme automatiquement après N pages
  - ⚠️ **iOS** : Le scanner ne se ferme pas automatiquement, mais seules les N premières pages sont retournées

### Corrections
- **Android** : Les options de scan (`outputFormat`, `useAutomaticCapture`, `pageLimit`) étaient ignorées
  car le message Pigeon (`[ScanOptions]`) n'était pas décodé correctement. Le format PNG est désormais
  bien pris en compte sur Android.
- **Android** : Suppression de la limite implicite de pages, `pageLimit = 0` signifie réellement « illimité »

### Améliorations
- **Interface exemple** : Ajout de contrôles UI pour tester les nouvelles options
  - Commutateur pour activer/désactiver la capture automatique
  - Slider pour définir la limite de pages (0-10)
  - Interface avec carte d'options de scan

### Détails techniques
- **Android** : Configuration dynamique du scanner mode selon `useAutomaticCapture`
- **iOS** : Amélioration de la gestion de la limite de pages dans `DocumentScannerService`
- **Pigeon** : Mise à jour des définitions d'API pour inclure les nouvelles options

## [1.1.1]
- **Flutter** : Mise à jour du sample

## [1.1.0]

### Ajouts
- **Support PNG** : Nouveau paramètre `outputFormat` dans `CaptureHelperScanOptions`
  - Permet de choisir entre JPEG (par défaut) et PNG
  - JPEG : Plus léger, compression avec perte
  - PNG : Plus lourd, compression sans perte, idéal pour schémas/diagrammes
- Nouvel enum `OutputFormat` avec valeurs `jpeg` et `png`

### Améliorations
- Compression d'images supporte maintenant PNG et JPEG automatiquement
- Détection automatique du format d'image lors de la compression

## [1.0.2]
- **iOS** : Fix crash au premier scan sur appareil réel
  - Ajout de `DispatchQueue.main.async` dans le callback de permission caméra
- **Android** : Ajout explicite de la permission CAMERA dans AndroidManifest.xml
  - Améliore la clarté et la compatibilité

## [1.0.1]

- **Flutter** : Downgrade sdk: ^3.9.0 -> ^3.8.0

## [1.0.0]
### iOS | Android | Flutter

- Version initiale du plugin avec support complet iOS et Android.

### Fonctionnalités

#### Scanner de documents
- Numérisation de documents avec détection automatique des bords
- Support multi-pages en une seule session
- Interface native sur iOS (VisionKit) et Android (ML Kit)
- Gestion automatique des permissions caméra
- Sauvegarde sécurisée dans le répertoire privé de l'application

#### Compression d'images
- Compression d'images avec contrôle de qualité (0-100%)
- Format JPEG optimisé
- Statistiques de compression (taille originale/compressée, ratio)

#### API publique
- `isScanningAvailable()` - Vérification de disponibilité du scanner
- `scanDocument()` - Numérisation de documents avec options
- `compressImage()` - Compression d'images JPEG
- `compressPdf()` - Compression de fichiers PDF (iOS uniquement)

#### Documentation
- README complet avec guide de démarrage rapide
- EXAMPLES.md avec 6 exemples détaillés
- CHEATSHEET.md pour référence rapide
- SPECS.md - Spécifications fonctionnelles
- TECHS.md - Guide de développement technique
- TROUBLESHOOTING.md - Guide de dépannage

#### Application exemple
- Interface complète avec démonstration des fonctionnalités
- Page d'accueil avec scan de documents
- Page de détails avec visualisation et compression
- Slider de qualité interactif
- Affichage des statistiques en temps réel

#### Architecture technique
- Communication type-safe avec Pigeon
- Codec personnalisé pour gestion des données
- BasicMessageChannel pour iOS et Android
- Tests unitaires et d'intégration
- Scripts de génération automatique

### Exigences

- Flutter SDK : >=3.3.0
- Dart SDK : >=3.8.0
- iOS : 13.0+ (appareil physique requis, pas de simulateur)
- Android : API 21+ avec Google Play Services
- Java : 17, 21 ou 23

### Dépendances

- `plugin_platform_interface: ^2.0.2`
- `flutter_lints: ^5.0.0`
- `pigeon: ^22.7.4` (dev)
- iOS : VisionKit framework
- Android : ML Kit Document Scanner v16.0.0-beta1

### Limitations

- iOS ne fonctionne que sur appareil physique
- Android nécessite Google Play Services
- Un seul scan actif à la fois

### Roadmap

- **Version 1.1** : ✅ Support PNG (complété)
- **Version 1.2** : Configuration qualité avancée (maxPageCount, allowGalleryImport, résolution), OCR optionnel, génération PDF
- **Version 2.0** : Support Web, reconnaissance de documents
