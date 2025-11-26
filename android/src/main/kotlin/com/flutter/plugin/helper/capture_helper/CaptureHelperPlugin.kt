package com.flutter.plugin.helper.capture_helper

import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream

/** CaptureHelperPlugin */
class CaptureHelperPlugin: FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {

    private var activity: Activity? = null
    private var pendingResult: BasicMessageChannel.Reply<Any?>? = null
    private var outputFormat: String = "jpeg"
    private lateinit var scanChannel: BasicMessageChannel<Any?>
    private lateinit var availabilityChannel: BasicMessageChannel<Any?>

    companion object {
        private const val REQUEST_CODE_SCAN = 100
    }

    private lateinit var compressImageChannel: BasicMessageChannel<Any?>

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        android.util.Log.d("CaptureHelper", "Plugin attached to engine")
        val codec = PigeonCodec()

        // Setup scan document channel
        scanChannel = BasicMessageChannel(
            flutterPluginBinding.binaryMessenger,
            "dev.flutter.pigeon.capture_helper.DocumentScannerApi.scanDocument",
            codec
        )
        scanChannel.setMessageHandler { message, reply ->
            android.util.Log.d("CaptureHelper", "Received scanDocument message: $message")
            handleScanDocument(message, reply)
        }

        // Setup availability check channel
        availabilityChannel = BasicMessageChannel(
            flutterPluginBinding.binaryMessenger,
            "dev.flutter.pigeon.capture_helper.DocumentScannerApi.isScanningAvailable",
            codec
        )
        availabilityChannel.setMessageHandler { message, reply ->
            android.util.Log.d("CaptureHelper", "Received isScanningAvailable message: $message")
            handleIsScanningAvailable(reply)
        }

        // Setup compress image channel
        compressImageChannel = BasicMessageChannel(
            flutterPluginBinding.binaryMessenger,
            "dev.flutter.pigeon.capture_helper.DocumentScannerApi.compressImage",
            codec
        )
        compressImageChannel.setMessageHandler { message, reply ->
            android.util.Log.d("CaptureHelper", "Received compressImage message: $message")
            handleCompressImage(message, reply)
        }
    }

    private fun handleIsScanningAvailable(reply: BasicMessageChannel.Reply<Any?>) {
        // ML Kit Document Scanner is available on Android API 21+
        reply.reply(listOf(true))
    }

    private fun handleScanDocument(message: Any?, reply: BasicMessageChannel.Reply<Any?>) {
        if (activity == null) {
            reply.reply(listOf(
                "NO_ACTIVITY",
                "Activity not available",
                null
            ))
            return
        }

        try {
            // Extraire le format de sortie des options
            @Suppress("UNCHECKED_CAST")
            val options = message as? Map<String, Any?>
            outputFormat = options?.get("outputFormat") as? String ?: "jpeg"

            startScanning(reply)
        } catch (e: Exception) {
            reply.reply(listOf(
                "ERROR",
                "Failed to start scanning: ${e.message}",
                null
            ))
        }
    }

    private fun startScanning(reply: BasicMessageChannel.Reply<Any?>) {
        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(false)
            .setPageLimit(10)
            .setResultFormats(
                GmsDocumentScannerOptions.RESULT_FORMAT_JPEG,
                GmsDocumentScannerOptions.RESULT_FORMAT_PDF
            )
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .build()

        val scanner = GmsDocumentScanning.getClient(options)

        pendingResult = reply

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
                    pendingResult?.reply(listOf(
                        "SCAN_ERROR",
                        "Failed to start scanner: ${e.message}",
                        null
                    ))
                    pendingResult = null
                }
            }
            .addOnFailureListener { e ->
                pendingResult?.reply(listOf(
                    "SCAN_ERROR",
                    "Failed to get scan intent: ${e.message}",
                    null
                ))
                pendingResult = null
            }
    }

    private fun handleCompressImage(message: Any?, reply: BasicMessageChannel.Reply<Any?>) {
        try {
            @Suppress("UNCHECKED_CAST")
            val args = message as? List<Any?>

            if (args == null || args.size < 2) {
                reply.reply(listOf(
                    "INVALID_ARGS",
                    "Invalid arguments for compressImage",
                    null
                ))
                return
            }

            val imagePath = args[0] as? String
            val quality = (args[1] as? Number)?.toInt() ?: 80

            if (imagePath == null) {
                reply.reply(listOf(
                    "INVALID_PATH",
                    "Image path is null",
                    null
                ))
                return
            }

            compressImage(imagePath, quality, reply)
        } catch (e: Exception) {
            reply.reply(listOf(
                "ERROR",
                "Failed to compress image: ${e.message}",
                null
            ))
        }
    }

    private fun compressImage(imagePath: String, quality: Int, reply: BasicMessageChannel.Reply<Any?>) {
        try {
            val sourceFile = File(imagePath)
            if (!sourceFile.exists()) {
                val result = mapOf(
                    "outputPath" to null,
                    "originalSize" to 0L,
                    "compressedSize" to 0L,
                    "success" to false,
                    "errorMessage" to "Source file does not exist"
                )
                reply.reply(listOf(result))
                return
            }

            val originalSize = sourceFile.length()

            // Read and decode the image
            val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath)
            if (bitmap == null) {
                val result = mapOf(
                    "outputPath" to null,
                    "originalSize" to originalSize,
                    "compressedSize" to 0L,
                    "success" to false,
                    "errorMessage" to "Failed to decode image"
                )
                reply.reply(listOf(result))
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
                bitmap.compress(compressFormat, if (isPNG) 100 else quality, out)
            }

            // Recycle bitmap to free memory
            bitmap.recycle()

            val compressedSize = outputFile.length()

            val result = mapOf(
                "outputPath" to outputFile.absolutePath,
                "originalSize" to originalSize,
                "compressedSize" to compressedSize,
                "success" to true,
                "errorMessage" to null
            )
            reply.reply(listOf(result))

        } catch (e: Exception) {
            val result = mapOf(
                "outputPath" to null,
                "originalSize" to 0L,
                "compressedSize" to 0L,
                "success" to false,
                "errorMessage" to "Compression failed: ${e.message}"
            )
            reply.reply(listOf(result))
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_SCAN) {
            if (pendingResult == null) return false

            when (resultCode) {
                Activity.RESULT_OK -> {
                    if (data != null) {
                        val scanResult = GmsDocumentScanningResult.fromActivityResultIntent(data)
                        val pages = scanResult?.pages ?: emptyList()

                        if (pages.isEmpty()) {
                            // Return ScanResult: [imagePaths, success, errorMessage]
                            val result = mapOf(
                                "imagePaths" to emptyList<String>(),
                                "success" to false,
                                "errorMessage" to "No pages scanned"
                            )
                            pendingResult?.reply(listOf(result))
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

                                val result = mapOf(
                                    "imagePaths" to imagePaths,
                                    "success" to true,
                                    "errorMessage" to null
                                )
                                pendingResult?.reply(listOf(result))
                            } catch (e: Exception) {
                                val result = mapOf(
                                    "imagePaths" to emptyList<String>(),
                                    "success" to false,
                                    "errorMessage" to "Failed to save images: ${e.message}"
                                )
                                pendingResult?.reply(listOf(result))
                            }
                        }
                    } else {
                        val result = mapOf(
                            "imagePaths" to emptyList<String>(),
                            "success" to false,
                            "errorMessage" to "No data returned"
                        )
                        pendingResult?.reply(listOf(result))
                    }
                }
                Activity.RESULT_CANCELED -> {
                    val result = mapOf(
                        "imagePaths" to emptyList<String>(),
                        "success" to false,
                        "errorMessage" to "User cancelled"
                    )
                    pendingResult?.reply(listOf(result))
                }
                else -> {
                    val result = mapOf(
                        "imagePaths" to emptyList<String>(),
                        "success" to false,
                        "errorMessage" to "Unknown error"
                    )
                    pendingResult?.reply(listOf(result))
                }
            }

            pendingResult = null
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        scanChannel.setMessageHandler(null)
        availabilityChannel.setMessageHandler(null)
        compressImageChannel.setMessageHandler(null)
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
