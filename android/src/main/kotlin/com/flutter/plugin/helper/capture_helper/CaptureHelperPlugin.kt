package com.flutter.plugin.helper.capture_helper

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.flutter.plugin.helper.capture_helper.generated.CompressionResult
import com.flutter.plugin.helper.capture_helper.generated.DocumentScannerApi
import com.flutter.plugin.helper.capture_helper.generated.FlutterError
import com.flutter.plugin.helper.capture_helper.generated.ScanOptions
import com.flutter.plugin.helper.capture_helper.generated.ScanResult
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream

/** CaptureHelperPlugin */
class CaptureHelperPlugin: FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener, DocumentScannerApi {

    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingCallback: ((Result<ScanResult>) -> Unit)? = null
    private var outputFormat: String = "jpeg"
    private var autoCompress: Boolean = false
    private var compressionQuality: Int = 80

    companion object {
        private const val REQUEST_CODE_SCAN = 100
        private const val OUTPUT_DIRECTORY_NAME = "capture_helper"
    }

    /**
     * Répertoire de sortie des fichiers produits par le plugin (scans et compressions) : `cacheDir/capture_helper/`.
     * Les fichiers sont privés à l'app et peuvent être supprimés par le système en cas de manque d'espace ;
     * l'application hôte doit copier ceux qu'elle souhaite conserver.
     */
    private fun outputDirectory(context: Context): File {
        return File(context.cacheDir, OUTPUT_DIRECTORY_NAME).apply { mkdirs() }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        DocumentScannerApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        DocumentScannerApi.setUp(binding.binaryMessenger, null)
        context = null
    }

    override fun isScanningAvailable(): Boolean {
        // ML Kit Document Scanner est disponible à partir de l'API 21
        return true
    }

    override fun scanDocument(options: ScanOptions, callback: (Result<ScanResult>) -> Unit) {
        val currentActivity = activity
        if (currentActivity == null) {
            callback(Result.failure(FlutterError("NO_ACTIVITY", "Activity not available")))
            return
        }
        if (pendingCallback != null) {
            callback(Result.failure(FlutterError("ALREADY_ACTIVE", "A scan is already in progress")))
            return
        }

        outputFormat = options.outputFormat
        autoCompress = options.autoCompress
        compressionQuality = options.compressionQuality.toInt()

        val optionsBuilder = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(false)
            .setResultFormats(
                GmsDocumentScannerOptions.RESULT_FORMAT_JPEG,
                GmsDocumentScannerOptions.RESULT_FORMAT_PDF
            )

        // Configurer la limite de pages (0 = illimité : sans appel à setPageLimit,
        // ML Kit n'est limité que par les ressources de l'appareil)
        if (options.pageLimit > 0) {
            optionsBuilder.setPageLimit(options.pageLimit.toInt())
        }

        // Configurer le mode de capture
        val scannerMode = if (options.useAutomaticCapture) {
            GmsDocumentScannerOptions.SCANNER_MODE_FULL
        } else {
            GmsDocumentScannerOptions.SCANNER_MODE_BASE
        }
        optionsBuilder.setScannerMode(scannerMode)

        val scanner = GmsDocumentScanning.getClient(optionsBuilder.build())

        pendingCallback = callback

        scanner.getStartScanIntent(currentActivity)
            .addOnSuccessListener { intentSender ->
                try {
                    currentActivity.startIntentSenderForResult(
                        intentSender,
                        REQUEST_CODE_SCAN,
                        null,
                        0,
                        0,
                        0
                    )
                } catch (e: Exception) {
                    completeScan(Result.failure(FlutterError("SCAN_ERROR", "Failed to start scanner: ${e.message}")))
                }
            }
            .addOnFailureListener { e ->
                completeScan(Result.failure(FlutterError("SCAN_ERROR", "Failed to get scan intent: ${e.message}")))
            }
    }

    override fun compressImage(imagePath: String, quality: Long, callback: (Result<CompressionResult>) -> Unit) {
        callback(Result.success(compressImageFile(imagePath, quality.toInt())))
    }

    override fun compressPdf(pdfPath: String, quality: Long, callback: (Result<CompressionResult>) -> Unit) {
        callback(Result.success(compressionFailure(0L, "PDF compression is not supported on Android")))
    }

    override fun clearTemporaryFiles(callback: (Result<Boolean>) -> Unit) {
        val currentContext = context
        if (currentContext == null) {
            callback(Result.success(false))
            return
        }

        // Supprime le sous-dossier capture_helper/ du cache (true s'il n'existait pas)
        val directory = File(currentContext.cacheDir, OUTPUT_DIRECTORY_NAME)
        callback(Result.success(!directory.exists() || directory.deleteRecursively()))
    }

    private fun compressImageFile(imagePath: String, quality: Int): CompressionResult {
        try {
            val sourceFile = File(imagePath)
            if (!sourceFile.exists()) {
                return compressionFailure(0L, "Source file does not exist")
            }

            val originalSize = sourceFile.length()

            // Read and decode the image
            val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath)
                ?: return compressionFailure(originalSize, "Failed to decode image")

            // Déterminer le format basé sur l'extension du fichier source
            val isPNG = imagePath.endsWith(".png", ignoreCase = true)
            val fileExtension = if (isPNG) "png" else "jpg"
            val compressFormat = if (isPNG) {
                android.graphics.Bitmap.CompressFormat.PNG
            } else {
                android.graphics.Bitmap.CompressFormat.JPEG
            }

            // Create output file (même nommage qu'iOS : <nom>_compressed.<ext>)
            val outputFileName = "${sourceFile.nameWithoutExtension}_compressed.$fileExtension"
            val outputFile = File(outputDirectory(context!!), outputFileName)

            // Compress and save
            // PNG: qualité ignorée (compression sans perte)
            // JPEG: qualité utilisée
            FileOutputStream(outputFile).use { out ->
                bitmap.compress(compressFormat, if (isPNG) 100 else quality, out)
            }

            // Recycle bitmap to free memory
            bitmap.recycle()

            return CompressionResult(
                outputPath = outputFile.absolutePath,
                originalSize = originalSize,
                compressedSize = outputFile.length(),
                success = true,
                errorMessage = null
            )
        } catch (e: Exception) {
            return compressionFailure(0L, "Compression failed: ${e.message}")
        }
    }

    private fun compressionFailure(originalSize: Long, errorMessage: String) = CompressionResult(
        outputPath = null,
        originalSize = originalSize,
        compressedSize = 0L,
        success = false,
        errorMessage = errorMessage
    )

    private fun scanFailure(errorMessage: String) = ScanResult(
        imagePaths = emptyList(),
        success = false,
        errorMessage = errorMessage,
        ignoredPageCount = 0
    )

    private fun completeScan(result: Result<ScanResult>) {
        val callback = pendingCallback ?: return
        pendingCallback = null
        callback(result)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_SCAN) return false
        if (pendingCallback == null) return false

        val result = when (resultCode) {
            Activity.RESULT_OK -> {
                if (data != null) {
                    val scanResult = GmsDocumentScanningResult.fromActivityResultIntent(data)
                    val pages = scanResult?.pages ?: emptyList()

                    if (pages.isEmpty()) {
                        scanFailure("No pages scanned")
                    } else {
                        try {
                            var imagePaths = pages.mapIndexedNotNull { index, page ->
                                page.imageUri?.let { uri -> savePage(uri, index) }
                            }

                            // Compression automatique si demandée
                            if (autoCompress) {
                                imagePaths = compressScannedImages(imagePaths, compressionQuality)
                            }
                            // ML Kit arrête lui-même la capture à pageLimit : aucune page n'est ignorée
                            ScanResult(imagePaths = imagePaths, success = true, errorMessage = null, ignoredPageCount = 0)
                        } catch (e: Exception) {
                            scanFailure("Failed to save images: ${e.message}")
                        }
                    }
                } else {
                    scanFailure("No data returned")
                }
            }
            Activity.RESULT_CANCELED -> scanFailure("User cancelled")
            else -> scanFailure("Unknown error")
        }

        completeScan(Result.success(result))
        return true
    }

    private fun compressScannedImages(imagePaths: List<String>, quality: Int): List<String> {
        return imagePaths.map { imagePath ->
            val result = compressImageFile(imagePath, quality)
            // En cas d'échec, garder l'image originale
            if (result.success) result.outputPath ?: imagePath else imagePath
        }
    }

    private fun savePage(uri: android.net.Uri, index: Int): String {
        val currentContext = context!!

        // Déterminer l'extension selon le format
        val isPNG = outputFormat == "png"
        val fileExtension = if (isPNG) "png" else "jpg"

        // Lire et convertir si nécessaire
        val bitmap = android.provider.MediaStore.Images.Media.getBitmap(
            currentContext.contentResolver,
            uri
        )

        val fileName = "scan_${System.currentTimeMillis()}_$index.$fileExtension"
        val destFile = File(outputDirectory(currentContext), fileName)

        // Sauvegarder dans le bon format
        FileOutputStream(destFile).use { output ->
            val format = if (isPNG) {
                android.graphics.Bitmap.CompressFormat.PNG
            } else {
                android.graphics.Bitmap.CompressFormat.JPEG
            }
            bitmap.compress(format, 100, output)
        }

        // Libérer la mémoire
        bitmap.recycle()

        return destFile.absolutePath
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachFromActivity()
    }

    private fun attachToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    private fun detachFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }
}
