# 📚 Exemples d'utilisation - Capture Helper

Ce fichier contient des exemples pratiques pour tous les cas d'usage courants.

## 📋 Table des matières

- [Scanner simplement](#scanner-simplement)
- [Scanner et compresser](#scanner-et-compresser)
- [Contrôler la taille des fichiers](#contrôler-la-taille-des-fichiers)
- [Scanner plusieurs pages](#scanner-plusieurs-pages)
- [Compresser en masse](#compresser-en-masse)
- [Interface utilisateur complète](#interface-utilisateur-complète)

---

## Scanner simplement

Le cas le plus basique : scanner un document et récupérer les chemins des images.

```dart
import 'package:capture_helper/capture_helper.dart';

Future<List<String>> scanSimple() async {
  final helper = CaptureHelper();

  // Vérifier la disponibilité
  if (!await helper.isScanningAvailable()) {
    throw Exception('Scanner non disponible');
  }

  // Scanner
  final result = await helper.scanDocument();

  if (result.success) {
    return result.imagePaths;
  } else {
    throw Exception(result.errorMessage ?? 'Erreur inconnue');
  }
}

// Utilisation
try {
  final images = await scanSimple();
  print('Images scannées : $images');
} catch (e) {
  print('Erreur : $e');
}
```

---

## Scanner et compresser

Scanner un document et compresser automatiquement toutes les images.

```dart
import 'package:capture_helper/capture_helper.dart';

Future<Map<String, dynamic>> scanEtCompresser({int qualite = 75}) async {
  final helper = CaptureHelper();

  // 1. Scanner le document
  final scanResult = await helper.scanDocument(
    options: CaptureHelperScanOptions(
      autoCompress: false,
      compressionQuality: qualite,
    ),
  );

  if (!scanResult.success) {
    throw Exception(scanResult.errorMessage);
  }

  // 2. Compresser chaque image
  final List<Map<String, dynamic>> resultatsCompression = [];

  for (final imagePath in scanResult.imagePaths) {
    final compressionResult = await helper.compressImage(
      imagePath: imagePath,
      quality: qualite,
    );

    if (compressionResult.success) {
      resultatsCompression.add({
        'original': imagePath,
        'compresse': compressionResult.outputPath,
        'tailleOriginale': compressionResult.formattedOriginalSize,
        'tailleCompressee': compressionResult.formattedCompressedSize,
        'reduction': compressionResult.reductionPercentage,
      });
    }
  }

  return {
    'nombreImages': scanResult.imageCount,
    'compressions': resultatsCompression,
  };
}

// Utilisation
try {
  final resultat = await scanEtCompresser(qualite: 80);
  print('${resultat['nombreImages']} images traitées');

  for (final compression in resultat['compressions']) {
    print('Image : ${compression['original']}');
    print('  → Compressée : ${compression['compresse']}');
    print('  → Réduction : ${compression['reduction'].toStringAsFixed(1)}%');
  }
} catch (e) {
  print('Erreur : $e');
}
```

---

## Contrôler la taille des fichiers

Garantir que les images ne dépassent pas une certaine taille.

```dart
import 'dart:io';
import 'package:capture_helper/capture_helper.dart';

Future<List<String>> scanAvecLimiteTaille({
  required int tailleLimiteKB,
  int qualiteInitiale = 80,
}) async {
  final helper = CaptureHelper();

  // Scanner
  final scanResult = await helper.scanDocument(
    options: CaptureHelperScanOptions(
      autoCompress: true,
      compressionQuality: qualiteInitiale,
    ),
  );

  if (!scanResult.success) {
    throw Exception(scanResult.errorMessage);
  }

  // Vérifier et compresser si nécessaire
  final List<String> imagesFinal = [];

  for (final imagePath in scanResult.imagePaths) {
    final file = File(imagePath);
    int tailleActuelleKB = (await file.length()) ~/ 1024;
    String cheminFinal = imagePath;

    // Si trop grande, compresser progressivement
    int qualite = qualiteInitiale;
    while (tailleActuelleKB > tailleLimiteKB && qualite > 10) {
      qualite -= 10; // Réduire la qualité par paliers

      final compressionResult = await helper.compressImage(
        imagePath: imagePath,
        quality: qualite,
      );

      if (compressionResult.success) {
        cheminFinal = compressionResult.outputPath!;
        tailleActuelleKB = (compressionResult.compressedSize) ~/ 1024;
        print('Image compressée à qualité $qualite : $tailleActuelleKB KB');
      }
    }

    if (tailleActuelleKB <= tailleLimiteKB) {
      imagesFinal.add(cheminFinal);
      print('✅ Image dans la limite : $tailleActuelleKB KB');
    } else {
      print('⚠️ Impossible d\'atteindre la limite pour cette image');
      imagesFinal.add(cheminFinal);
    }
  }

  return imagesFinal;
}

// Utilisation
try {
  // Limiter à 500 KB par image
  final images = await scanAvecLimiteTaille(tailleLimiteKB: 500);
  print('${images.length} images générées dans la limite de taille');
} catch (e) {
  print('Erreur : $e');
}
```

---

## Scanner plusieurs pages

Interface pour scanner plusieurs documents successivement.

```dart
import 'package:capture_helper/capture_helper.dart';

class ScannerMultiPages {
  final helper = CaptureHelper();
  final List<String> toutesLesImages = [];

  Future<void> ajouterPages() async {
    final result = await helper.scanDocument();

    if (result.success) {
      toutesLesImages.addAll(result.imagePaths);
      print('${result.imageCount} nouvelles pages ajoutées');
      print('Total : ${toutesLesImages.length} pages');
    } else if (!result.wasCancelled) {
      throw Exception(result.errorMessage);
    }
  }

  Future<void> compresserTout({int qualite = 80}) async {
    print('Compression de ${toutesLesImages.length} pages...');

    for (int i = 0; i < toutesLesImages.length; i++) {
      print('Compression page ${i + 1}/${toutesLesImages.length}...');

      final result = await helper.compressImage(
        imagePath: toutesLesImages[i],
        quality: qualite,
      );

      if (result.success) {
        // Remplacer par la version compressée
        toutesLesImages[i] = result.outputPath!;
      }
    }

    print('✅ Compression terminée');
  }

  void vider() {
    toutesLesImages.clear();
  }
}

// Utilisation
void main() async {
  final scanner = ScannerMultiPages();

  try {
    // Scanner première série de pages
    await scanner.ajouterPages();

    // Scanner deuxième série de pages
    await scanner.ajouterPages();

    // Compresser tout
    await scanner.compresserTout(qualite: 75);

    print('Document final : ${scanner.toutesLesImages.length} pages');

  } catch (e) {
    print('Erreur : $e');
  }
}
```

---

## Compresser en masse

Compresser plusieurs images avec différents niveaux de qualité.

```dart
import 'package:capture_helper/capture_helper.dart';

Future<void> compresserEnMasse({
  required List<String> cheminImages,
  List<int> qualites = const [90, 75, 60, 40],
}) async {
  final helper = CaptureHelper();

  for (final imagePath in cheminImages) {
    print('\n📄 Traitement : $imagePath');

    for (final qualite in qualites) {
      final result = await helper.compressImage(
        imagePath: imagePath,
        quality: qualite,
      );

      if (result.success) {
        print('  Q$qualite : ${result.formattedCompressedSize} '
              '(-${result.reductionPercentage.toStringAsFixed(0)}%)');
      }
    }
  }
}

// Utilisation
try {
  await compresserEnMasse(
    cheminImages: ['/path/image1.jpg', '/path/image2.jpg'],
    qualites: [90, 80, 70, 60, 50],
  );
} catch (e) {
  print('Erreur : $e');
}
```

---

## Interface utilisateur complète

Exemple d'intégration dans une vraie application Flutter.

```dart
import 'package:flutter/material.dart';
import 'package:capture_helper/capture_helper.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final _helper = CaptureHelper();
  bool _isScanning = false;
  bool _isAvailable = false;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _helper.isScanningAvailable();
    setState(() => _isAvailable = available);
  }

  Future<void> _scanDocument() async {
    setState(() => _isScanning = true);

    try {
      final result = await _helper.scanDocument(
        options: const CaptureHelperScanOptions(
          autoCompress: true,
          compressionQuality: 80,
        ),
      );

      if (result.success) {
        setState(() => _images.addAll(result.imagePaths));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.imageCount} image(s) scannée(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (!result.wasCancelled) {
        _showError(result.errorMessage ?? 'Erreur inconnue');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _compressImage(String path) async {
    try {
      final result = await _helper.compressImage(
        imagePath: path,
        quality: 70,
      );

      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Compressé : ${result.reductionPercentage.toStringAsFixed(1)}% de réduction',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de documents'),
      ),
      body: Column(
        children: [
          // Bouton scan
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isAvailable && !_isScanning ? _scanDocument : null,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner),
              label: Text(_isScanning ? 'Scan en cours...' : 'Scanner un document'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
          ),

          // Liste des images
          Expanded(
            child: _images.isEmpty
                ? const Center(
                    child: Text('Aucune image scannée'),
                  )
                : ListView.builder(
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final path = _images[index];
                      return ListTile(
                        leading: const Icon(Icons.image),
                        title: Text('Image ${index + 1}'),
                        subtitle: Text(path.split('/').last),
                        trailing: IconButton(
                          icon: const Icon(Icons.compress),
                          onPressed: () => _compressImage(path),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎯 Conseils pratiques

### Choisir la qualité de compression

| Cas d'usage | Qualité recommandée | Résultat attendu |
|-------------|---------------------|------------------|
| Archivage légal | 90-100 | Qualité maximale |
| Documents importants | 80-90 | Très bonne qualité |
| Usage quotidien | 70-80 | Bon équilibre |
| Email / Partage | 60-70 | Fichier léger |
| Aperçu rapide | 40-60 | Très léger |

### Gestion des erreurs courantes

```dart
try {
  final result = await CaptureHelper().scanDocument();

  if (!result.success) {
    if (result.wasCancelled) {
      print('👤 Annulé par l\'utilisateur');
    } else if (result.errorMessage?.contains('not available') == true) {
      print('❌ Scanner non disponible sur cet appareil');
    } else if (result.errorMessage?.contains('permission') == true) {
      print('🔒 Permission caméra refusée');
    } else {
      print('⚠️ Erreur : ${result.errorMessage}');
    }
  }
} catch (e) {
  print('💥 Exception : $e');
}
```

### Performance

Pour de meilleures performances :

1. **Compresser en arrière-plan** : Utilisez `compute()` pour les grosses images
2. **Nettoyer les fichiers temporaires** : Supprimez les images originales après compression
3. **Limiter la résolution** : Utilisez une qualité plus basse pour les documents textuels

```dart
import 'package:flutter/foundation.dart';

// Compression en arrière-plan
Future<void> compresserEnArrierePlan(String path) async {
  final result = await compute(_compressImageIsolate, {
    'path': path,
    'quality': 80,
  });
  print('Compressé en arrière-plan : $result');
}

Future<String?> _compressImageIsolate(Map<String, dynamic> params) async {
  final helper = CaptureHelper();
  final result = await helper.compressImage(
    imagePath: params['path'],
    quality: params['quality'],
  );
  return result.success ? result.outputPath : null;
}
```

---

Pour plus d'exemples, consultez le dossier [example](example/) du projet.
