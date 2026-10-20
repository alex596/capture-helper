# Plugin Flutter Document Scanner - Guide de développement complet

> ⚠️ **Document de conception initial (historique).** Ce guide décrit l'approche envisagée avant
> l'implémentation (pont Objective-C, Pigeon 17, `minSdkVersion 21`, `ios/Classes`…) et n'est plus
> à jour. Pour l'état actuel du plugin (Pigeon 29, Flutter 3.44+, API 24+, Swift Package Manager),
> se référer au [README](../README.md) et au [CHANGELOG](../CHANGELOG.md).


## 📋 Vue d'ensemble du projet

Ce plugin Flutter offre des capacités de scan de documents en utilisant les technologies natives :
- **iOS** : VisionKit avec VNDocumentCameraViewController
- **Android** : ML Kit Document Scanner
- **Communication** : Pigeon pour une communication type-safe entre Flutter et les plateformes natives

### Fonctionnalités principales
- Scan manuel ou automatique de documents
- Support du scan de document unique ou multiple
- Sauvegarde automatique des images scannées
- Interface native pour chaque plateforme
- Gestion complète des erreurs

## 🏗️ Architecture du projet

```
document_scanner_plugin/
├── lib/
│   ├── document_scanner_plugin.dart           # API publique principale
│   └── src/
│       ├── document_scanner_method_channel.dart
│       ├── generated/
│       │   └── document_scanner_api.g.dart    # Généré par Pigeon
│       └── models/
│           ├── scan_result.dart
│           └── scan_options.dart
├── android/
│   ├── build.gradle
│   └── src/main/kotlin/com/yourcompany/document_scanner_plugin/
│       ├── DocumentScannerPlugin.kt
│       └── Messages.g.kt                      # Généré par Pigeon
├── ios/
│   ├── document_scanner_plugin.podspec
│   └── Classes/
│       ├── DocumentScannerPlugin.swift
│       ├── DocumentScannerPlugin.m            # Pont Objective-C
│       ├── DocumentScannerPlugin.h
│       └── Messages.g.swift                   # Généré par Pigeon
├── pigeons/
│   └── document_scanner_api.dart              # Définitions API Pigeon
├── scripts/
│   └── generate_pigeon.sh                     # Script de génération
├── pubspec.yaml
└── example/
    └── lib/
        └── main.dart
```

## 🚀 Étapes de développement

### 1. Configuration initiale

#### 1.1 Créer la structure du plugin
```bash
flutter create --template=plugin --platforms android,ios document_scanner_plugin
cd document_scanner_plugin
```

#### 1.2 Mettre à jour pubspec.yaml
```yaml
name: document_scanner_plugin
description: Plugin Flutter pour scanner des documents avec VisionKit (iOS) et ML Kit (Android)
version: 1.0.0
homepage: https://github.com/yourcompany/document_scanner_plugin

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.3.0"

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  pigeon: ^17.0.0

flutter:
  plugin:
    platforms:
      android:
        package: com.yourcompany.document_scanner_plugin
        pluginClass: DocumentScannerPlugin
      ios:
        pluginClass: DocumentScannerPlugin
```

### 2. Configuration Pigeon

#### 2.1 Créer pigeons/document_scanner_api.dart
```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/document_scanner_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/yourcompany/document_scanner_plugin/Messages.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Classes/Messages.g.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'document_scanner_plugin',
))

class ScanOptions {
  final bool allowMultipleDocuments;
  final bool useAutomaticCapture;
  
  ScanOptions({
    required this.allowMultipleDocuments,
    required this.useAutomaticCapture,
  });
}

class ScanResult {
  final List<String> imagePaths;
  final bool success;
  final String? errorMessage;
  
  ScanResult({
    required this.imagePaths,
    required this.success,
    this.errorMessage,
  });
}

@HostApi()
abstract class DocumentScannerApi {
  @async
  ScanResult scanDocuments(ScanOptions options);
}
```

#### 2.2 Script de génération scripts/generate_pigeon.sh
```bash
#!/bin/bash
echo "🔄 Génération des fichiers Pigeon..."

dart run pigeon --input pigeons/document_scanner_api.dart

if [ $? -eq 0 ]; then
    echo "✅ Fichiers Pigeon générés avec succès!"
else
    echo "❌ Erreur lors de la génération des fichiers Pigeon"
    exit 1
fi
```

### 3. Implémentation Flutter (Dart)

#### 3.1 API publique principale - lib/document_scanner_plugin.dart
```dart
library document_scanner_plugin;

export 'src/models/scan_result.dart';
export 'src/models/scan_options.dart';

import 'src/document_scanner_method_channel.dart';
import 'src/models/scan_result.dart';
import 'src/models/scan_options.dart';

abstract class DocumentScannerPlugin {
  static DocumentScannerPluginPlatform get instance => _instance;
  static DocumentScannerPluginPlatform _instance = MethodChannelDocumentScanner();
  
  /// Lance le scan de documents avec les options spécifiées
  /// 
  /// [allowMultipleDocuments] : Permet de scanner plusieurs documents
  /// [useAutomaticCapture] : Active la capture automatique (recommandé)
  /// 
  /// Retourne [ScanResult] contenant les chemins des images et le statut
  static Future<ScanResult> scanDocuments({
    bool allowMultipleDocuments = false,
    bool useAutomaticCapture = true,
  }) {
    return instance.scanDocuments(ScanOptions(
      allowMultipleDocuments: allowMultipleDocuments,
      useAutomaticCapture: useAutomaticCapture,
    ));
  }
}

abstract class DocumentScannerPluginPlatform {
  Future<ScanResult> scanDocuments(ScanOptions options);
}
```

#### 3.2 Modèles de données

**lib/src/models/scan_options.dart**
```dart
/// Options de configuration pour le scan de documents
class ScanOptions {
  /// Permet de scanner plusieurs documents en une session
  final bool allowMultipleDocuments;
  
  /// Active la capture automatique (détection des bords)
  final bool useAutomaticCapture;
  
  const ScanOptions({
    required this.allowMultipleDocuments,
    required this.useAutomaticCapture,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'allowMultipleDocuments': allowMultipleDocuments,
      'useAutomaticCapture': useAutomaticCapture,
    };
  }
  
  @override
  String toString() {
    return 'ScanOptions(allowMultipleDocuments: $allowMultipleDocuments, useAutomaticCapture: $useAutomaticCapture)';
  }
}
```

**lib/src/models/scan_result.dart**
```dart
/// Résultat d'une opération de scan
class ScanResult {
  /// Liste des chemins vers les images scannées
  final List<String> imagePaths;
  
  /// Indique si l'opération a réussi
  final bool success;
  
  /// Message d'erreur en cas d'échec
  final String? errorMessage;
  
  const ScanResult({
    required this.imagePaths,
    required this.success,
    this.errorMessage,
  });
  
  /// Crée un résultat d'erreur
  factory ScanResult.error(String message) {
    return ScanResult(
      imagePaths: [],
      success: false,
      errorMessage: message,
    );
  }
  
  /// Crée un résultat de succès
  factory ScanResult.success(List<String> imagePaths) {
    return ScanResult(
      imagePaths: imagePaths,
      success: true,
      errorMessage: null,
    );
  }
  
  @override
  String toString() {
    return 'ScanResult(success: $success, imagePaths: ${imagePaths.length} images, error: $errorMessage)';
  }
}
```

#### 3.3 Implémentation MethodChannel - lib/src/document_scanner_method_channel.dart
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../document_scanner_plugin.dart';
import 'generated/document_scanner_api.g.dart';
import 'models/scan_result.dart';
import 'models/scan_options.dart';

class MethodChannelDocumentScanner extends DocumentScannerPluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('document_scanner_plugin');
  
  late final DocumentScannerApi _api = DocumentScannerApi();

  @override
  Future<ScanResult> scanDocuments(ScanOptions options) async {
    try {
      final pigeonOptions = PigeonScanOptions(
        allowMultipleDocuments: options.allowMultipleDocuments,
        useAutomaticCapture: options.useAutomaticCapture,
      );
      
      final result = await _api.scanDocuments(pigeonOptions);
      
      return ScanResult(
        imagePaths: result.imagePaths,
        success: result.success,
        errorMessage: result.errorMessage,
      );
    } on PlatformException catch (e) {
      return ScanResult.error('Platform error: ${e.message}');
    } catch (e) {
      return ScanResult.error('Unexpected error: $e');
    }
  }
}
```

### 4. Implémentation iOS (Swift + VisionKit)

#### 4.1 Configuration podspec - ios/document_scanner_plugin.podspec
```ruby
Pod::Spec.new do |s|
  s.name             = 'document_scanner_plugin'
  s.version          = '1.0.0'
  s.summary          = 'Plugin Flutter pour scanner des documents'
  s.description      = 'Plugin utilisant VisionKit sur iOS et ML Kit sur Android'
  s.homepage         = 'https://github.com/yourcompany/document_scanner_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'contact@yourcompany.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  
  # VisionKit framework requis
  s.frameworks = 'VisionKit'
  
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' 
  }
  s.swift_version = '5.0'
end
```

#### 4.2 Pont Objective-C - ios/Classes/DocumentScannerPlugin.h
```objc
#import <Flutter/Flutter.h>

@interface DocumentScannerPlugin : NSObject<FlutterPlugin>
@end
```

#### 4.3 Pont Objective-C - ios/Classes/DocumentScannerPlugin.m
```objc
#import "DocumentScannerPlugin.h"
#if __has_include(<document_scanner_plugin/document_scanner_plugin-Swift.h>)
#import <document_scanner_plugin/document_scanner_plugin-Swift.h>
#else
#import "document_scanner_plugin-Swift.h"
#endif

@implementation DocumentScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [DocumentScannerPluginSwift registerWithRegistrar:registrar];
}
@end
```

#### 4.4 Implémentation Swift - ios/Classes/DocumentScannerPlugin.swift
```swift
import Flutter
import UIKit
import VisionKit

@objc(DocumentScannerPluginSwift)
public class DocumentScannerPluginSwift: NSObject, FlutterPlugin, DocumentScannerApi {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let api = DocumentScannerPluginSwift()
        DocumentScannerApiSetup.setUp(binaryMessenger: messenger, api: api)
    }
    
    func scanDocuments(options: ScanOptions, completion: @escaping (Result<ScanResult, Error>) -> Void) {
        // Vérification de la disponibilité de VisionKit
        guard VNDocumentCameraViewController.isSupported else {
            let error = ScanResult(
                imagePaths: [],
                success: false,
                errorMessage: "Document scanning not supported on this device (iOS 13.0+ required)"
            )
            completion(.success(error))
            return
        }
        
        DispatchQueue.main.async {
            self.presentDocumentScanner(options: options, completion: completion)
        }
    }
    
    private func presentDocumentScanner(
        options: ScanOptions, 
        completion: @escaping (Result<ScanResult, Error>) -> Void
    ) {
        guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController else {
            let error = ScanResult(
                imagePaths: [],
                success: false,
                errorMessage: "Unable to present scanner: no root view controller"
            )
            completion(.success(error))
            return
        }
        
        let scannerViewController = VNDocumentCameraViewController()
        let delegate = DocumentScannerDelegate(options: options, completion: completion)
        scannerViewController.delegate = delegate
        
        // Conserver une référence forte au delegate
        objc_setAssociatedObject(
            scannerViewController, 
            "delegate", 
            delegate, 
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        rootViewController.present(scannerViewController, animated: true)
    }
}

// MARK: - Document Scanner Delegate
private class DocumentScannerDelegate: NSObject, VNDocumentCameraViewControllerDelegate {
    private let options: ScanOptions
    private let completion: (Result<ScanResult, Error>) -> Void
    
    init(options: ScanOptions, completion: @escaping (Result<ScanResult, Error>) -> Void) {
        self.options = options
        self.completion = completion
    }
    
    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController, 
        didFinishWith scan: VNDocumentCameraScan
    ) {
        controller.dismiss(animated: true) {
            self.processScanResult(scan)
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) {
            let result = ScanResult(
                imagePaths: [],
                success: false,
                errorMessage: "User cancelled document scanning"
            )
            self.completion(.success(result))
        }
    }
    
    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController, 
        didFailWithError error: Error
    ) {
        controller.dismiss(animated: true) {
            let result = ScanResult(
                imagePaths: [],
                success: false,
                errorMessage: "Scanner failed: \(error.localizedDescription)"
            )
            self.completion(.success(result))
        }
    }
    
    private func processScanResult(_ scan: VNDocumentCameraScan) {
        var imagePaths: [String] = []
        
        // Créer le dossier de destination
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let scanFolderPath = "\(documentsPath)/DocumentScanner"
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: scanFolderPath) {
            do {
                try fileManager.createDirectory(atPath: scanFolderPath, withIntermediateDirectories: true)
            } catch {
                completion(.success(ScanResult(
                    imagePaths: [],
                    success: false,
                    errorMessage: "Failed to create scan directory: \(error.localizedDescription)"
                )))
                return
            }
        }
        
        // Déterminer le nombre de pages à traiter
        let maxPages = options.allowMultipleDocuments ? scan.pageCount : min(1, scan.pageCount)
        
        // Traiter chaque page
        for pageIndex in 0..<maxPages {
            let image = scan.imageOfPage(at: pageIndex)
            let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            let filename = "scanned_document_\(timestamp)_\(pageIndex).jpg"
            let filePath = "\(scanFolderPath)/\(filename)"
            
            if let imageData = image.jpegData(compressionQuality: 0.85) {
                do {
                    try imageData.write(to: URL(fileURLWithPath: filePath))
                    imagePaths.append(filePath)
                } catch {
                    print("⚠️ Error saving image \(pageIndex): \(error)")
                }
            }
        }
        
        let result = ScanResult(
            imagePaths: imagePaths,
            success: !imagePaths.isEmpty,
            errorMessage: imagePaths.isEmpty ? "No images were successfully saved" : nil
        )
        
        completion(.success(result))
    }
}

// MARK: - Extensions
extension VNDocumentCameraViewController {
    static var isSupported: Bool {
        if #available(iOS 13.0, *) {
            return VNDocumentCameraViewController.isSupported
        }
        return false
    }
}
```

### 5. Implémentation Android (Kotlin + ML Kit)

#### 5.1 Configuration Gradle - android/build.gradle
```gradle
group 'com.yourcompany.document_scanner_plugin'
version '1.0-SNAPSHOT'

buildscript {
    ext.kotlin_version = '1.8.22'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    compileSdkVersion 34
    namespace 'com.yourcompany.document_scanner_plugin'

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        minSdkVersion 21  // ML Kit Document Scanner requirement
        targetSdkVersion 34
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    
    // ML Kit Document Scanner
    implementation 'com.google.android.gms:play-services-mlkit-document-scanner:16.0.0-beta1'
    
    // Pour la gestion des fichiers
    implementation 'androidx.core:core-ktx:1.12.0'
}
```

#### 5.2 Permissions Android - android/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.yourcompany.document_scanner_plugin">
    
    <!-- Permissions requises -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="28" />
    
    <!-- Fonctionnalités hardware (optionnelles) -->
    <uses-feature android:name="android.hardware.camera" 
                  android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" 
                  android:required="false" />
</manifest>
```

#### 5.3 Plugin principal - android/src/main/kotlin/.../DocumentScannerPlugin.kt
```kotlin
package com.yourcompany.document_scanner_plugin

import android.app.Activity
import android.content.Intent
import android.content.IntentSender
import android.os.Environment
import androidx.annotation.NonNull
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream

class DocumentScannerPlugin: FlutterPlugin, ActivityAware, DocumentScannerApi, 
    PluginRegistry.ActivityResultListener {
    
    private var activity: Activity? = null
    private var pendingResult: ((Result<ScanResult>) -> Unit)? = null
    private var currentOptions: ScanOptions? = null
    
    companion object {
        private const val REQUEST_CODE_SCAN_DOCUMENT = 12345
        private const val TAG = "DocumentScannerPlugin"
    }

    // FlutterPlugin lifecycle
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        DocumentScannerApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        DocumentScannerApi.setUp(binding.binaryMessenger, null)
    }

    // ActivityAware lifecycle
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // DocumentScannerApi implementation
    override fun scanDocuments(options: ScanOptions, callback: (Result<ScanResult>) -> Unit) {
        val currentActivity = activity
        if (currentActivity == null) {
            callback(Result.success(ScanResult(
                imagePaths = emptyList(),
                success = false,
                errorMessage = "Activity not available. Ensure plugin is properly initialized."
            )))
            return
        }

        // Configuration du scanner ML Kit
        val scannerOptionsBuilder = GmsDocumentScannerOptions.Builder()
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)

        // Configuration du nombre de pages
        if (options.allowMultipleDocuments) {
            scannerOptionsBuilder.setPageLimit(20) // Limite raisonnable
        } else {
            scannerOptionsBuilder.setPageLimit(1)
        }

        val scannerOptions = scannerOptionsBuilder.build()
        val scanner = GmsDocumentScanning.getClient(scannerOptions)

        // Stocker les informations pour le callback
        pendingResult = callback
        currentOptions = options

        // Démarrer le scanner
        scanner.getStartScanIntent(currentActivity)
            .addOnSuccessListener { intentSender ->
                try {
                    currentActivity.startIntentSenderForResult(
                        intentSender,
                        REQUEST_CODE_SCAN_DOCUMENT,
                        null,
                        0,
                        0,
                        0
                    )
                } catch (e: IntentSender.SendIntentException) {
                    callback(Result.success(ScanResult(
                        imagePaths = emptyList(),
                        success = false,
                        errorMessage = "Failed to start document scanner: ${e.message}"
                    )))
                    clearPendingOperation()
                }
            }
            .addOnFailureListener { e ->
                callback(Result.success(ScanResult(
                    imagePaths = emptyList(),
                    success = false,
                    errorMessage = "Failed to initialize scanner: ${e.message}"
                )))
                clearPendingOperation()
            }
    }

    // ActivityResultListener implementation
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_SCAN_DOCUMENT) {
            val callback = pendingResult
            val options = currentOptions
            
            if (callback != null && options != null) {
                when (resultCode) {
                    Activity.RESULT_OK -> {
                        data?.let { intent ->
                            val result = GmsDocumentScanningResult.fromActivityResultIntent(intent)
                            result?.let { scanResult ->
                                processScanResult(scanResult, callback)
                            } ?: run {
                                callback(Result.success(ScanResult(
                                    imagePaths = emptyList(),
                                    success = false,
                                    errorMessage = "Failed to retrieve scan result"
                                )))
                            }
                        } ?: run {
                            callback(Result.success(ScanResult(
                                imagePaths = emptyList(),
                                success = false,
                                errorMessage = "No scan data received"
                            )))
                        }
                    }
                    Activity.RESULT_CANCELED -> {
                        callback(Result.success(ScanResult(
                            imagePaths = emptyList(),
                            success = false,
                            errorMessage = "User cancelled document scanning"
                        )))
                    }
                    else -> {
                        callback(Result.success(ScanResult(
                            imagePaths = emptyList(),
                            success = false,
                            errorMessage = "Scanning failed with result code: $resultCode"
                        )))
                    }
                }
                clearPendingOperation()
            }
            return true
        }
        return false
    }

    private fun processScanResult(
        scanResult: GmsDocumentScanningResult, 
        callback: (Result<ScanResult>) -> Unit
    ) {
        val pages = scanResult.pages
        if (pages.isNullOrEmpty()) {
            callback(Result.success(ScanResult(
                imagePaths = emptyList(),
                success = false,
                errorMessage = "No pages found in scan result"
            )))
            return
        }

        val imagePaths = mutableListOf<String>()
        
        // Créer le dossier de destination
        val documentsDir = File(
            activity?.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), 
            "DocumentScanner"
        )
        
        if (!documentsDir.exists()) {
            if (!documentsDir.mkdirs()) {
                callback(Result.success(ScanResult(
                    imagePaths = emptyList(),
                    success = false,
                    errorMessage = "Failed to create storage directory"
                )))
                return
            }
        }

        try {
            // Traiter chaque page scannée
            for ((index, page) in pages.withIndex()) {
                page.imageUri?.let { imageUri ->
                    val inputStream = activity?.contentResolver?.openInputStream(imageUri)
                    inputStream?.use { input ->
                        val timestamp = System.currentTimeMillis()
                        val filename = "scanned_document_${timestamp}_$index.jpg"
                        val outputFile = File(documentsDir, filename)
                        
                        FileOutputStream(outputFile).use { output ->
                            input.copyTo(output)
                        }
                        
                        imagePaths.add(outputFile.absolutePath)
                    }
                }
            }

            callback(Result.success(ScanResult(
                imagePaths = imagePaths,
                success = imagePaths.isNotEmpty(),
                errorMessage = if (imagePaths.isEmpty()) "Failed to save any scanned images" else null
            )))
            
        } catch (e: Exception) {
            callback(Result.success(ScanResult(
                imagePaths = emptyList(),
                success = false,
                errorMessage = "Error processing scan result: ${e.message}"
            )))
        }
    }
    
    private fun clearPendingOperation() {
        pendingResult = null
        currentOptions = null
    }
}
```

### 6. Configuration de l'application exemple

#### 6.1 Application Flutter d'exemple - example/lib/main.dart
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:document_scanner_plugin/document_scanner_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Scanner Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DocumentScannerDemo(),
    );
  }
}

class DocumentScannerDemo extends StatefulWidget {
  const DocumentScannerDemo({super.key});

  @override
  State<DocumentScannerDemo> createState() => _DocumentScannerDemoState();
}

class _DocumentScannerDemoState extends State<DocumentScannerDemo> {
  List<String> _scannedImagePaths = [];
  bool _isScanning = false;
  String _lastError = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Boutons de scan
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Options de scan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : () => _scanDocument(false),
                      icon: const Icon(Icons.document_scanner),
                      label: const Text('Scanner un document'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : () => _scanDocument(true),
                      icon: const Icon(Icons.library_books),
                      label: const Text('Scanner plusieurs documents'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statut du scan
            if (_isScanning)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Scan en cours...'),
                    ],
                  ),
                ),
              ),
            
            // Affichage des erreurs
            if (_lastError.isNotEmpty)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Erreur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_lastError),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _lastError = ''),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Liste des documents scannés
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Documents scannés (${_scannedImagePaths.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_scannedImagePaths.isNotEmpty)
                            TextButton.icon(
                              onPressed: _clearScannedDocuments,
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Tout effacer'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _scannedImagePaths.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucun document scanné',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _scannedImagePaths.length,
                              itemBuilder: (context, index) {
                                final imagePath = _scannedImagePaths[index];
                                return ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(imagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.error);
                                        },
                                      ),
                                    ),
                                  ),
                                  title: Text('Document ${index + 1}'),
                                  subtitle: Text(
                                    imagePath.split('/').last,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () => _shareDocument(imagePath),
                                        tooltip: 'Partager',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteDocument(index),
                                        tooltip: 'Supprimer',
                                      ),
                                    ],
                                  ),
                                  onTap: () => _viewDocument(imagePath),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanDocument(bool allowMultiple) async {
    setState(() {
      _isScanning = true;
      _lastError = '';
    });

    try {
      final result = await DocumentScannerPlugin.scanDocuments(
        allowMultipleDocuments: allowMultiple,
        useAutomaticCapture: true,
      );

      if (result.success && result.imagePaths.isNotEmpty) {
        setState(() {
          _scannedImagePaths.addAll(result.imagePaths);
        });
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.imagePaths.length} document(s) scanné(s) avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _lastError = result.errorMessage ?? 'Erreur inconnue lors du scan';
        });
      }
    } catch (e) {
      setState(() {
        _lastError = 'Erreur inattendue: $e';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _clearScannedDocuments() {
    setState(() {
      _scannedImagePaths.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tous les documents ont été effacés de la liste'),
      ),
    );
  }

  void _deleteDocument(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le document'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce document ?'),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Supprimer'),
              onPressed: () {
                setState(() {
                  _scannedImagePaths.removeAt(index);
                });
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document supprimé'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _viewDocument(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentViewer(imagePath: imagePath),
      ),
    );
  }

  void _shareDocument(String imagePath) {
    // Implémentation du partage (nécessiterait un plugin comme share_plus)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage du document: ${imagePath.split('/').last}'),
      ),
    );
  }
}

class DocumentViewer extends StatelessWidget {
  final String imagePath;

  const DocumentViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document - ${imagePath.split('/').last}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implémentation du partage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(80),
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            File(imagePath),
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Erreur lors du chargement de l\'image'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```

#### 6.2 Permissions pour l'exemple Android - example/android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions requises pour le scanner -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="28" />
    
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <application
        android:label="document_scanner_example"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Reste de la configuration -->
    </application>
</manifest>
```

#### 6.3 Configuration iOS pour l'exemple - example/ios/Runner/Info.plist
```xml
<!-- Ajouter dans le dict principal -->
<key>NSCameraUsageDescription</key>
<string>Cette application a besoin d'accéder à la caméra pour scanner des documents</string>

<!-- Optionnel: pour iOS 14+ -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Cette application peut sauvegarder les documents scannés dans la photothèque</string>
```

## 📋 Instructions de déploiement et tests

### 1. Génération des fichiers Pigeon
```bash
# Rendre le script exécutable
chmod +x scripts/generate_pigeon.sh

# Exécuter la génération
./scripts/generate_pigeon.sh

# Ou manuellement
dart run pigeon --input pigeons/document_scanner_api.dart
```

### 2. Tests sur iOS
```bash
# Naviguer vers l'exemple
cd example

# Installer les dépendances
flutter pub get

# Installer les pods iOS
cd ios && pod install && cd ..

# Lancer sur iOS (simulateur ou device)
flutter run -d ios

# Note: Le simulateur iOS ne supporte pas la caméra
# Tests requis sur un device physique
```

### 3. Tests sur Android
```bash
cd example
flutter pub get

# Lancer sur Android
flutter run -d android

# Vérifier les permissions dans l'app
# Tester sur différentes versions d'Android (21+)
```

### 4. Configuration des versions minimales

#### example/android/app/build.gradle
```gradle
android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    defaultConfig {
        applicationId "com.example.document_scanner_example"
        minSdkVersion 21  // Requis pour ML Kit
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
}
```

#### example/ios/Podfile
```ruby
platform :ios, '13.0'  # Requis pour VisionKit

# Reste de la configuration Podfile
```

## 🔧 Dépannage et bonnes pratiques

### Problèmes courants et solutions

#### iOS
- **Erreur VisionKit non disponible**: Vérifier iOS 13.0+ et device physique
- **Permissions caméra**: S'assurer que `NSCameraUsageDescription` est dans Info.plist
- **Build errors**: Vérifier que VisionKit framework est correctement lié

#### Android
- **ML Kit non initialisé**: Vérifier la version des Google Play Services
- **Permissions refusées**: Implémenter une gestion appropriée des permissions
- **Crash au démarrage**: Vérifier minSdkVersion 21+

### Tests recommandés

1. **Tests unitaires pour les modèles de données**
2. **Tests d'intégration sur devices physiques**
3. **Tests de performance avec multiple documents**
4. **Tests de gestion d'erreurs**
5. **Tests sur différentes versions d'OS**

### Optimisations recommandées

1. **Compression d'images**: Ajuster la qualité JPEG selon les besoins
2. **Gestion mémoire**: Libérer les ressources après scan
3. **Stockage**: Implémenter une stratégie de nettoyage des fichiers
4. **UI/UX**: Ajouter des indicateurs de progression
5. **Internationalisation**: Support multilingue des messages d'erreur

## 📚 Documentation API

### DocumentScannerPlugin.scanDocuments()
```dart
static Future<ScanResult> scanDocuments({
  bool allowMultipleDocuments = false,
  bool useAutomaticCapture = true,
})
```

**Paramètres:**
- `allowMultipleDocuments`: Permet de scanner plusieurs documents en une session
- `useAutomaticCapture`: Active la détection automatique des bords (recommandé)

**Retour:**
- `ScanResult`: Contient les chemins des images, le statut et les erreurs éventuelles

### ScanResult
```dart
class ScanResult {
  final List<String> imagePaths;  // Chemins vers les images scannées
  final bool success;             // Statut de l'opération
  final String? errorMessage;     // Message d'erreur si échec
}
```

### Messages d'erreur courants
- `"Document scanning not supported on this device"` - iOS < 13.0 ou simulateur
- `"User cancelled document scanning"` - Utilisateur a annulé
- `"Activity not available"` - Plugin non initialisé correctement (Android)
- `"Failed to initialize scanner"` - Problème avec ML Kit/VisionKit

## 🔒 Considérations de sécurité

1. **Permissions minimales**: Ne demander que les permissions nécessaires
2. **Stockage sécurisé**: Sauvegarder dans des répertoires privés à l'app
3. **Nettoyage des données**: Implémenter une stratégie de suppression
4. **Validation des fichiers**: Vérifier l'intégrité des images
5. **Chiffrement**: Considérer le chiffrement pour les documents sensibles

## 📝 Notes de développement

### Prochaines améliorations possibles
1. **Support PDF**: Génération de PDF à partir des scans
2. **OCR intégré**: Extraction de texte avec ML Kit Text Recognition
3. **Filtres d'image**: Amélioration de la qualité des scans
4. **Cloud storage**: Intégration avec services cloud
5. **Batch processing**: Traitement par lots optimisé

### Limitations connues
1. **iOS Simulator**: Pas de support caméra, tests sur device requis
2. **Taille des fichiers**: Pas de limite configurée actuellement
3. **Formats**: Support JPEG uniquement
4. **Concurrent scans**: Un seul scan à la fois

Ce guide fournit tout le nécessaire pour développer et déployer un plugin Flutter de scan de documents robuste et sécurisé.