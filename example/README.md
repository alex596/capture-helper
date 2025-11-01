# Capture Helper - Application Exemple

Application de démonstration complète du plugin **Capture Helper** pour Flutter.

## 📱 Fonctionnalités de l'app

Cette application exemple montre toutes les fonctionnalités du plugin :

### Page d'accueil
- ✅ Vérification de la disponibilité du scanner
- 📸 Bouton pour lancer la numérisation
- 📊 Affichage du statut et des messages d'erreur
- 🎯 Liste des fonctionnalités du plugin

### Page de détails
- 🖼️ Visualisation des images scannées
- 📄 Navigation entre les pages (si multi-pages)
- 📊 Affichage des informations de fichier (taille, nom)
- 🎚️ Slider de qualité de compression (10-100%)
- 🗜️ Bouton de compression avec feedback visuel
- 📈 Statistiques de compression détaillées :
  - Taille originale vs compressée
  - Pourcentage de réduction
  - Espace économisé

## 🚀 Lancer l'application

### Prérequis

- Flutter SDK 3.3.0+
- **iOS** : Xcode 14+, appareil physique avec iOS 13.0+
- **Android** : Android Studio, appareil avec API 21+ et Google Play Services

### Installation

```bash
# Installer les dépendances
flutter pub get

# Lancer sur iOS
flutter run -d ios

# Lancer sur Android
flutter run -d android
```

### Important pour iOS

⚠️ **Le scanner ne fonctionne PAS sur simulateur iOS** car VisionKit nécessite un appareil physique avec caméra.

```bash
# Lister les appareils disponibles
flutter devices

# Lancer sur un iPhone connecté
flutter run -d <device-id>
```

### Important pour Android

⚠️ **Google Play Services requis** pour ML Kit Document Scanner.

Si vous testez sur émulateur :
1. Utilisez un émulateur avec Google Play Store
2. Vérifiez que Google Play Services est à jour

## 📂 Structure du code

```
example/
├── lib/
│   ├── main.dart                    # Page d'accueil
│   └── pages/
│       └── scan_details_page.dart   # Page de détails avec compression
├── integration_test/
│   └── plugin_integration_test.dart # Tests d'intégration
└── README.md                        # Ce fichier
```

## 💡 Exemples de code

### Scanner un document (main.dart)

```dart
Future<void> _scanDocument() async {
  final result = await _captureHelper.scanDocument(
    options: const CaptureHelperScanOptions(
      autoCompress: false,
      compressionQuality: 80,
    ),
  );

  if (result.success && result.imagePaths.isNotEmpty) {
    // Naviguer vers la page de détails
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanDetailsPage(
          imagePaths: result.imagePaths,
        ),
      ),
    );
  }
}
```

### Compresser une image (scan_details_page.dart)

```dart
Future<void> _compressImage() async {
  final result = await _captureHelper.compressImage(
    imagePath: currentImagePath,
    quality: _compressionQuality.toInt(),
  );

  if (result.success) {
    // Afficher les statistiques
    print('Original: ${result.formattedOriginalSize}');
    print('Compressé: ${result.formattedCompressedSize}');
    print('Réduction: ${result.reductionPercentage.toStringAsFixed(1)}%');
  }
}
```

## 🧪 Tests

### Tests d'intégration

```bash
# Lancer les tests d'intégration sur appareil connecté
cd example
flutter test integration_test/
```

### Tests manuels

1. **Test de scan simple**
   - Cliquer sur "Scan Document"
   - Scanner une page
   - Vérifier que l'image s'affiche

2. **Test multi-pages**
   - Scanner plusieurs pages
   - Naviguer entre les pages avec les flèches

3. **Test de compression**
   - Ajuster le slider de qualité
   - Cliquer sur "Compress Image"
   - Vérifier les statistiques affichées

4. **Test de qualité**
   - Tester différents niveaux : 90%, 75%, 60%, 40%
   - Comparer les tailles de fichiers

## 🎯 Cas d'usage démontrés

### 1. Vérification de disponibilité
Avant d'utiliser le scanner, vérifier qu'il est disponible sur l'appareil.

### 2. Gestion des erreurs
Tous les cas d'erreur sont gérés :
- Scanner non disponible
- Utilisateur annule
- Erreurs de scan/compression

### 3. Interface utilisateur réactive
- Loading states pendant le scan/compression
- Feedback visuel avec SnackBars
- Désactivation des boutons pendant les opérations

### 4. Visualisation d'images
Affichage des images avec `Image.file()` et gestion des erreurs.

### 5. Compression interactive
Slider pour ajuster la qualité en temps réel avec descriptions.

## 📊 Niveaux de qualité testés

L'application démontre différents niveaux de qualité :

| Slider | Qualité | Usage | Résultat |
|--------|---------|-------|----------|
| 90-100 | Haute | Archivage | Qualité maximale, grande taille |
| 70-85 | Bonne | Usage général | Équilibre qualité/taille |
| 50-70 | Moyenne | Email, partage | Bonne compression |
| 10-50 | Basse | Aperçu | Très compressé |

## 🐛 Dépannage

### "Scanner non disponible"

**iOS** :
- Vérifiez que vous êtes sur un appareil physique (pas simulateur)
- Vérifiez iOS >= 13.0

**Android** :
- Vérifiez Google Play Services installé
- Vérifiez API >= 21

### "Permission caméra refusée"

**iOS** :
- Allez dans Réglages > Capture Helper Example > Caméra
- Activez la permission

**Android** :
- Allez dans Paramètres > Apps > Capture Helper Example > Autorisations
- Activez la caméra

### L'app crash au scan

**iOS** :
- Vérifiez que `NSCameraUsageDescription` est dans Info.plist
- Vérifiez que l'appareil a assez de mémoire

**Android** :
- Vérifiez les logs : `flutter logs`
- Assurez-vous que Google Play Services est à jour

## 📸 Captures d'écran

Pour voir à quoi ressemble l'application, consultez [SCREENSHOTS.md](SCREENSHOTS.md) avec :
- Maquettes des écrans
- Flux utilisateur complet
- Exemples de messages
- Guide de design

## 📚 Documentation complète

Pour plus d'informations sur le plugin :

- [README principal](../README.md) - Documentation complète du plugin
- [EXAMPLES.md](../EXAMPLES.md) - Plus d'exemples de code
- [CHEATSHEET.md](../CHEATSHEET.md) - Aide-mémoire rapide
- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - Guide de dépannage

## 🎨 Personnalisation

Cette app exemple utilise Material Design 3. Pour personnaliser :

```dart
// main.dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  useMaterial3: true,
),
```

## 📝 Notes

- Les images scannées sont sauvegardées dans le répertoire privé de l'app
- Les fichiers compressés sont créés avec un nouveau nom (`compressed_*.jpg`)
- Les fichiers temporaires ne sont pas automatiquement supprimés
- Pour une app de production, pensez à nettoyer les fichiers temporaires

## 🤝 Contribution

Cette app exemple sert de référence. Si vous trouvez des bugs ou avez des suggestions :

1. Ouvrez une issue sur GitHub
2. Proposez une pull request avec améliorations

## 📄 Licence

MIT License - Voir [LICENSE](../LICENSE) pour plus de détails.
