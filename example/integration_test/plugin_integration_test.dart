// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:capture_helper/capture_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isScanningAvailable test', (_) async {
    final CaptureHelper plugin = CaptureHelper();
    final bool isAvailable = await plugin.isScanningAvailable();

    // The availability depends on the platform and device
    // On iOS: requires iOS 13.0+ and physical device
    // On Android: requires ML Kit and Google Play Services
    expect(isAvailable, isA<bool>());
  });

  testWidgets('scanDocument returns result', (_) async {
    final CaptureHelper plugin = CaptureHelper();

    // Note: This test cannot actually scan without user interaction
    // It just verifies the API is callable
    expect(plugin.scanDocument, isA<Function>());
  });

  testWidgets('compressImage API exists', (_) async {
    final CaptureHelper plugin = CaptureHelper();

    // Verify the compress methods are available
    expect(plugin.compressImage, isA<Function>());
    expect(plugin.compressPdf, isA<Function>());
  });
}
