package com.flutter.plugin.helper.capture_helper

import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class PigeonCodec : StandardMessageCodec() {
    companion object {
        const val TYPE_SCAN_OPTIONS = 129.toByte()
        const val TYPE_SCAN_RESULT = 130.toByte()
        const val TYPE_COMPRESSION_RESULT = 131.toByte()
    }

    override fun writeValue(stream: ByteArrayOutputStream, value: Any?) {
        when (value) {
            is Map<*, *> -> {
                // Check if this is a ScanResult, ScanOptions, or CompressionResult
                when {
                    value.containsKey("imagePaths") && value.containsKey("success") -> {
                        // This is a ScanResult
                        stream.write(TYPE_SCAN_RESULT.toInt())
                        val encoded = listOf(
                            value["imagePaths"],
                            value["success"],
                            value["errorMessage"]
                        )
                        writeValue(stream, encoded)
                    }
                    value.containsKey("autoCompress") && value.containsKey("compressionQuality") -> {
                        // This is ScanOptions
                        stream.write(TYPE_SCAN_OPTIONS.toInt())
                        val encoded = listOf(
                            value["autoCompress"],
                            value["compressionQuality"]
                        )
                        writeValue(stream, encoded)
                    }
                    value.containsKey("outputPath") && value.containsKey("originalSize") -> {
                        // This is CompressionResult
                        stream.write(TYPE_COMPRESSION_RESULT.toInt())
                        val encoded = listOf(
                            value["outputPath"],
                            value["originalSize"],
                            value["compressedSize"],
                            value["success"],
                            value["errorMessage"]
                        )
                        writeValue(stream, encoded)
                    }
                    else -> super.writeValue(stream, value)
                }
            }
            else -> super.writeValue(stream, value)
        }
    }

    override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? {
        return when (type) {
            TYPE_SCAN_OPTIONS -> {
                val list = readValue(buffer) as List<*>
                mapOf(
                    "autoCompress" to list[0],
                    "compressionQuality" to list[1]
                )
            }
            TYPE_SCAN_RESULT -> {
                val list = readValue(buffer) as List<*>
                mapOf(
                    "imagePaths" to list[0],
                    "success" to list[1],
                    "errorMessage" to list[2]
                )
            }
            TYPE_COMPRESSION_RESULT -> {
                val list = readValue(buffer) as List<*>
                mapOf(
                    "outputPath" to list[0],
                    "originalSize" to list[1],
                    "compressedSize" to list[2],
                    "success" to list[3],
                    "errorMessage" to list[4]
                )
            }
            else -> super.readValueOfType(type, buffer)
        }
    }
}
