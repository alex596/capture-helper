package com.flutter.plugin.helper.capture_helper

import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull
import com.flutter.plugin.helper.capture_helper.generated.CompressionResult
import com.flutter.plugin.helper.capture_helper.generated.DocumentScannerApi
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

    private var activity: Activity? = null
    private var pendingCallback: ((Result<ScanResult>) -> Unit)? = null
    private var outputFormat: String = "jpeg"
    private var pageLimit: Int = 10

    companion object {
        private const val REQUEST_CODE_SCAN = 100
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        android.util.Log.d("CaptureHelper", "Plugin attached to engine")
        DocumentScannerApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun isScanningAvailable(): Boolean {
        // ML Kit Document Scanner is available on Android API 21+
        return true
    }

    override fun scanDocument(options: ScanOptions, callback: (Result<ScanResult>) -> Unit) {
        android.util.Log.d("CaptureHelper", "scanDocument called with options: $options")

        if (activity == null) {
            callback(Result.success(ScanResult(
                imagePaths = emptyList(),
                success = false,
                errorMessage = "Activity not available"
            )))
            return
        }

        try {
            outputFormat = options.outputFormat
            pageLimit = options.pageLimit.toInt()
            startScanning(callback)
        } catch (e: Exception) {
            callback(Result.success(ScanResult(
                imagePaths = emptyList(),
                success = false,
                errorMessage = "Failed to start scanning: ${e.message}"
            )))
        }
    }

    private fun startScanning(callback: (Result<ScanResult>) -> Unit) {
        val effectivePageLimit = pageLimit.coerceIn(1, 10)
        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(false)
            .setPageLimit(effectivePageLimit)
            .setResultFormats(
                GmsDocumentScannerOptions.RESULT_FORMAT_JPEG,
                GmsDocumentScannerOptions.RESULT_FORMAT_PDF
            )
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .build()

        val scanner = GmsDocumentScanning.getClient(options)

        pendingCallback = callback

        scanner.getStartScanIntent(activity!!)
            .addOnSuccessListener { intentSender ->
                try {
                    activity?.startIntentSenderForResult(
                        intentSender,
                        REQUEST_CODE_SCAN,
                        null,
                        0,
                        0,
                        0
                    )
                } catch (e: Exception) {
                    pendingCallback?.invoke(Result.success(ScanResult(
                        imagePaths = emptyList(),
                        success = false,
                        errorMessage = "Failed to start scanner: ${e.message}"
                    )))
                    pendingCallback = null
                }
            }
            .addOnFailureListener { e ->
                pendingCallback?.invoke(Result.success(ScanResult(
                    imagePaths = emptyList(),
                    success = false,
                    errorMessage = "Failed to get scan intent: ${e.message}"
                )))
                pendingCallback = null
            }
    }

    override fun compressImage(imagePath: String, quality: Long, callback: (Result<CompressionResult>) -> Unit) {
        try {
            val sourceFile = File(imagePath)
            if (!sourceFile.exists()) {
                callback(Result.success(CompressionResult(
                    outputPath = null,
                    originalSize = 0L,
                    compressedSize = 0L,
                    success = false,
                    errorMessage = "Source file does not exist"
                )))
                return
            }

            val originalSize = sourceFile.length()

            // Read and decode the image
            val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath)
            if (bitmap == null) {
                callback(Result.success(CompressionResult(
                    outputPath = null,
                    originalSize = originalSize,
                    compressedSize = 0L,
                    success = false,
                    errorMessage = "Failed to decode image"
                )))
                return
            }

            // Déterminer le format basé sur l'extension du fichier source
            val isPNG = imagePath.endsWith(".png", ignoreCase = true)
            val fileExtension = if (isPNG) "png" else "jpg"
            val compressFormat = if (isPNG) {
                android.graphics.Bitmap.CompressFormat.PNG
            } else {
                android.graphics.Bitmap.CompressFormat.JPEG
            }

            // Create output file
            val outputFileName = "compressed_${System.currentTimeMillis()}.$fileExtension"
            val outputFile = File(activity!!.filesDir, outputFileName)

            // Compress and save
            // PNG: qualité ignorée (compression sans perte)
            // JPEG: qualité utilisée
            FileOutputStream(outputFile).use { out ->
                bitmap.compress(compressFormat, if (isPNG) 100 else quality.toInt(), out)
            }

            // Recycle bitmap to free memory
            bitmap.recycle()

            val compressedSize = outputFile.length()

            callback(Result.success(CompressionResult(
                outputPath = outputFile.absolutePath,
                originalSize = originalSize,
                compressedSize = compressedSize,
                success = true,
                errorMessage = null
            )))

        } catch (e: Exception) {
            callback(Result.success(CompressionResult(
                outputPath = null,
                originalSize = 0L,
                compressedSize = 0L,
                success = false,
                errorMessage = "Compression failed: ${e.message}"
            )))
        }
    }

    override fun compressPdf(pdfPath: String, quality: Long, callback: (Result<CompressionResult>) -> Unit) {
        // PDF compression not implemented yet
        callback(Result.success(CompressionResult(
            outputPath = null,
            originalSize = 0L,
            compressedSize = 0L,
            success = false,
            errorMessage = "PDF compression not implemented"
        )))
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_SCAN) {
            if (pendingCallback == null) return false

            when (resultCode) {
                Activity.RESULT_OK -> {
                    if (data != null) {
                        val scanResult = GmsDocumentScanningResult.fromActivityResultIntent(data)
                        val pages = scanResult?.pages ?: emptyList()

                        if (pages.isEmpty()) {
                            pendingCallback?.invoke(Result.success(ScanResult(
                                imagePaths = emptyList(),
                                success = false,
                                errorMessage = "No pages scanned"
                            )))
                        } else {
                            try {
                                val imagePaths = pages.mapNotNull { page ->
                                    page.imageUri?.let { uri ->
                                        // Déterminer l'extension selon le format
                                        val fileExtension = if (outputFormat == "png") "png" else "jpg"

                                        // Lire et convertir si nécessaire
                                        val bitmap = android.provider.MediaStore.Images.Media.getBitmap(
                                            activity!!.contentResolver,
                                            uri
                                        )

                                        val fileName = "scan_${System.currentTimeMillis()}_${pages.indexOf(page)}.$fileExtension"
                                        val destFile = File(activity!!.filesDir, fileName)

                                        // Sauvegarder dans le bon format
                                        FileOutputStream(destFile).use { output ->
                                            val format = if (outputFormat == "png") {
                                                android.graphics.Bitmap.CompressFormat.PNG
                                            } else {
                                                android.graphics.Bitmap.CompressFormat.JPEG
                                            }
                                            bitmap.compress(format, 100, output)
                                        }

                                        // Libérer la mémoire
                                        bitmap.recycle()

                                        destFile.absolutePath
                                    }
                                }

                                pendingCallback?.invoke(Result.success(ScanResult(
                                    imagePaths = imagePaths,
                                    success = true,
                                    errorMessage = null
                                )))
                            } catch (e: Exception) {
                                pendingCallback?.invoke(Result.success(ScanResult(
                                    imagePaths = emptyList(),
                                    success = false,
                                    errorMessage = "Failed to save images: ${e.message}"
                                )))
                            }
                        }
                    } else {
                        pendingCallback?.invoke(Result.success(ScanResult(
                            imagePaths = emptyList(),
                            success = false,
                            errorMessage = "No data returned"
                        )))
                    }
                }
                Activity.RESULT_CANCELED -> {
                    pendingCallback?.invoke(Result.success(ScanResult(
                        imagePaths = emptyList(),
                        success = false,
                        errorMessage = "User cancelled"
                    )))
                }
                else -> {
                    pendingCallback?.invoke(Result.success(ScanResult(
                        imagePaths = emptyList(),
                        success = false,
                        errorMessage = "Unknown error"
                    )))
                }
            }

            pendingCallback = null
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        DocumentScannerApi.setUp(binding.binaryMessenger, null)
    }

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
}
