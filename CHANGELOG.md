# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [1.0.1] - 2025-10-19

Downgrade sdk: ^3.9.0 -> ^3.8.0

## [1.0.0] - 2025-01-19

Version initiale du plugin avec support complet iOS et Android.

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
- Format de sortie : JPEG uniquement
- Un seul scan actif à la fois

### Roadmap

- **Version 1.1** : Support PNG, configuration qualité avancée
- **Version 1.2** : OCR optionnel, génération PDF
- **Version 2.0** : Support Web, reconnaissance de documents
