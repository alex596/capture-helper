#!/bin/bash

echo "🔨 Generating Pigeon code..."

# Générer le code Pigeon
dart run pigeon --input pigeons/document_scanner_api.dart

echo "✅ Pigeon code generated successfully!"
echo ""
echo "Generated files:"
echo "  - lib/src/generated/document_scanner_api.g.dart"
echo "  - ios/capture_helper/Sources/capture_helper/Generated/DocumentScannerApi.g.swift"
echo "  - android/src/main/kotlin/com/flutter/plugin/helper/capture_helper/generated/DocumentScannerApi.g.kt"
