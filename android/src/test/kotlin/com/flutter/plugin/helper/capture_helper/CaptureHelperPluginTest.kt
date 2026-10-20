package com.flutter.plugin.helper.capture_helper

import com.flutter.plugin.helper.capture_helper.generated.CompressionResult
import com.flutter.plugin.helper.capture_helper.generated.FlutterError
import com.flutter.plugin.helper.capture_helper.generated.ScanOptions
import com.flutter.plugin.helper.capture_helper.generated.ScanResult
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/*
 * Tests unitaires de la partie Kotlin du plugin.
 *
 * Après avoir buildé l'application exemple, lancer depuis `example/android/` :
 * `./gradlew :capture_helper:testDebugUnitTest`
 */

internal class CaptureHelperPluginTest {
    @Test
    fun isScanningAvailable_returnsTrue() {
        assertTrue(CaptureHelperPlugin().isScanningAvailable())
    }

    @Test
    fun scanDocument_withoutActivity_failsWithNoActivity() {
        var result: Result<ScanResult>? = null
        CaptureHelperPlugin().scanDocument(
            ScanOptions(
                autoCompress = false,
                compressionQuality = 80,
                outputFormat = "jpeg",
                useAutomaticCapture = true,
                pageLimit = 0
            )
        ) { result = it }

        val error = result!!.exceptionOrNull() as FlutterError
        assertEquals("NO_ACTIVITY", error.code)
    }

    @Test
    fun compressImage_withMissingFile_returnsFailure() {
        var result: Result<CompressionResult>? = null
        CaptureHelperPlugin().compressImage("/does/not/exist.jpg", 80) { result = it }

        val compression = result!!.getOrThrow()
        assertFalse(compression.success)
        assertEquals("Source file does not exist", compression.errorMessage)
    }

    @Test
    fun clearTemporaryFiles_withoutContext_returnsFalse() {
        var result: Result<Boolean>? = null
        CaptureHelperPlugin().clearTemporaryFiles { result = it }

        assertFalse(result!!.getOrThrow())
    }

    @Test
    fun compressPdf_isNotSupported() {
        var result: Result<CompressionResult>? = null
        CaptureHelperPlugin().compressPdf("/tmp/doc.pdf", 80) { result = it }

        val compression = result!!.getOrThrow()
        assertFalse(compression.success)
        assertEquals("PDF compression is not supported on Android", compression.errorMessage)
    }
}
