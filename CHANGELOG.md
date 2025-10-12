# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [Non publié]

### Ajouté
- Documentation complète en français
- Guide de démarrage rapide dans le README
- Exemples détaillés pour tous les cas d'usage (EXAMPLES.md)
- Aide-mémoire rapide (CHEATSHEET.md)
- Documentation visuelle de l'app exemple (SCREENSHOTS.md)
- Support de la compression d'images sur Android
- Codec Pigeon personnalisé pour la communication Flutter-native
- Logs de débogage dans le plugin Android
- Gestion complète des erreurs et cas limites

### Modifié
- README principal complètement réécrit avec exemples clairs
- README de l'application exemple avec instructions détaillées
- Configuration Java 11 → Java 17 pour meilleure compatibilité
- Plugin Android utilise BasicMessageChannel au lieu de MethodChannel
- Amélioration de la gestion des résultats de scan et compression

### Corrigé
- Erreurs de compilation Android avec Java 24
- NullPointerException dans le DartMessenger
- Canal de communication Pigeon incompatible
- "Document scanning not available" sur Android
- Compression d'images non implémentée sur Android
- Suppression des services Pigeon non utilisés

## [1.0.0] - 2024-10-01

### Ajouté
- Structure initiale du plugin Flutter
- Support iOS avec VisionKit (iOS 13.0+)
- Support Android avec ML Kit Document Scanner (API 21+)
- Architecture Pigeon pour communication type-safe
- Définitions des modèles de données :
  - `ScanOptions` - Options de numérisation
  - `ScanResult` - Résultat de numérisation
  - `CompressionResult` - Résultat de compression
- API publique Flutter :
  - `isScanningAvailable()` - Vérification de disponibilité
  - `scanDocument()` - Numérisation de documents
  - `compressImage()` - Compression d'images
  - `compressPdf()` - Compression de PDF
- Application exemple avec :
  - Page d'accueil avec bouton de scan
  - Page de détails avec visualisation d'images
  - Slider de qualité de compression
  - Affichage des statistiques de compression
- Tests unitaires de base
- Tests d'intégration
- Documentation technique :
  - SPECS.md (Spécifications fonctionnelles)
  - TECHS.md (Guide de développement technique)
  - TROUBLESHOOTING.md (Guide de dépannage)
  - CLAUDE.md (Directives pour Claude Code)
- Scripts de génération Pigeon
- Configuration CI/CD de base

### Fonctionnalités principales
- ✅ Numérisation de documents avec détection automatique des bords
- ✅ Support multi-pages en une seule session
- ✅ Compression d'images avec contrôle de qualité (0-100%)
- ✅ Interface native sur iOS (VisionKit) et Android (ML Kit)
- ✅ Gestion automatique des permissions caméra
- ✅ Sauvegarde sécurisée dans répertoire privé de l'app
- ✅ Format JPEG optimisé

### Limitations connues
- iOS : Nécessite appareil physique (ne fonctionne pas sur simulateur)
- Android : Nécessite Google Play Services
- Format de sortie : JPEG uniquement (PNG en roadmap)
- Un seul scan actif à la fois par application

### Exigences techniques
- Flutter SDK : >=3.3.0
- Dart SDK : >=3.9.0
- iOS : 13.0+
- Android : API 21+ (Android 5.0+)
- Java : 17, 21 ou 23 (Java 24 non supporté)

### Dépendances
- `plugin_platform_interface: ^2.0.2`
- `flutter_lints: ^5.0.0`
- `pigeon: ^22.7.4` (dev)
- iOS : VisionKit framework
- Android : ML Kit Document Scanner (`com.google.android.gms:play-services-mlkit-document-scanner:16.0.0-beta1`)

---

## Notes de version

### Version actuelle (Non publiée)

Cette version corrige les problèmes de compilation Android et ajoute une documentation complète. Le plugin est maintenant **fonctionnel sur iOS et Android** avec toutes les fonctionnalités suivantes :

**✅ Fonctionnel** :
- Scanner des documents (iOS et Android)
- Vérifier la disponibilité du scanner
- Compresser des images (iOS et Android)
- Interface utilisateur de l'app exemple
- Documentation complète

**🚧 En développement** :
- Compression PDF (iOS uniquement)
- Support PNG
- OCR intégré
- Génération PDF à partir d'images

**📋 Roadmap** :
- Version 1.1 : Support PNG, configuration qualité d'image avancée
- Version 1.2 : Intégration OCR optionnelle, génération PDF
- Version 2.0 : Support Web, reconnaissance types de documents

### Migration depuis 0.0.1

Si vous utilisez la version 0.0.1, aucune migration n'est nécessaire. L'API publique reste identique. Assurez-vous simplement d'avoir :
- Java 17+ (pas Java 24)
- Nettoyé et reconstruit votre projet Android

```bash
cd example
flutter clean
flutter pub get
flutter build apk
```

---

## Contributions

Pour contribuer à ce projet :
1. Fork le repository
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/ma-fonctionnalite`)
3. Committez vos changements (`git commit -am 'Ajout de ma fonctionnalité'`)
4. Pushez vers la branche (`git push origin feature/ma-fonctionnalite`)
5. Ouvrez une Pull Request

---

## Liens utiles

- [README](README.md) - Documentation principale
- [EXAMPLES.md](EXAMPLES.md) - Exemples de code détaillés
- [CHEATSHEET.md](CHEATSHEET.md) - Aide-mémoire rapide
- [Application exemple](example/README.md) - Documentation de l'app exemple

---

**Légende** :
- `Ajouté` : Nouvelles fonctionnalités
- `Modifié` : Modifications de fonctionnalités existantes
- `Déprécié` : Fonctionnalités bientôt supprimées
- `Supprimé` : Fonctionnalités supprimées
- `Corrigé` : Corrections de bugs
- `Sécurité` : Correctifs de sécurité
