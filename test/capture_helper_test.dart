import 'package:flutter_test/flutter_test.dart';
import 'package:capture_helper/capture_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CaptureHelperScanOptions', () {
    test('creates options with default values', () {
      const options = CaptureHelperScanOptions();

      expect(options.autoCompress, false);
      expect(options.compressionQuality, 80);
    });

    test('creates options with custom values', () {
      const options = CaptureHelperScanOptions(
        autoCompress: true,
        compressionQuality: 90,
      );

      expect(options.autoCompress, true);
      expect(options.compressionQuality, 90);
    });

    test('validates compression quality range', () {
      expect(
        () => CaptureHelperScanOptions(compressionQuality: -1),
        throwsAssertionError,
      );

      expect(
        () => CaptureHelperScanOptions(compressionQuality: 101),
        throwsAssertionError,
      );
    });

    test('copyWith works correctly', () {
      const original = CaptureHelperScanOptions(
        autoCompress: false,
        compressionQuality: 70,
      );

      final modified = original.copyWith(autoCompress: true);

      expect(modified.autoCompress, true);
      expect(modified.compressionQuality, 70);
    });

    test('equality works correctly', () {
      const options1 = CaptureHelperScanOptions(
        autoCompress: true,
        compressionQuality: 80,
      );

      const options2 = CaptureHelperScanOptions(
        autoCompress: true,
        compressionQuality: 80,
      );

      const options3 = CaptureHelperScanOptions(
        autoCompress: false,
        compressionQuality: 80,
      );

      expect(options1, equals(options2));
      expect(options1, isNot(equals(options3)));
    });
  });

  group('CaptureHelperScanResult', () {
    test('creates success result', () {
      final result = CaptureHelperScanResult.success(['path1', 'path2']);

      expect(result.success, true);
      expect(result.imagePaths, ['path1', 'path2']);
      expect(result.imageCount, 2);
      expect(result.errorMessage, null);
      expect(result.wasCancelled, false);
    });

    test('creates failure result', () {
      final result = CaptureHelperScanResult.failure('Error occurred');

      expect(result.success, false);
      expect(result.imagePaths, isEmpty);
      expect(result.imageCount, 0);
      expect(result.errorMessage, 'Error occurred');
      expect(result.wasCancelled, false);
    });

    test('creates cancelled result', () {
      final result = CaptureHelperScanResult.cancelled();

      expect(result.success, false);
      expect(result.imagePaths, isEmpty);
      expect(result.wasCancelled, true);
    });
  });

  group('CaptureHelperCompressionResult', () {
    test('creates success result', () {
      final result = CaptureHelperCompressionResult.success(
        outputPath: '/path/to/compressed.jpg',
        originalSize: 1000000,
        compressedSize: 500000,
      );

      expect(result.success, true);
      expect(result.outputPath, '/path/to/compressed.jpg');
      expect(result.originalSize, 1000000);
      expect(result.compressedSize, 500000);
      expect(result.compressionRatio, 0.5);
      expect(result.reductionPercentage, 50.0);
      expect(result.savedBytes, 500000);
    });

    test('creates failure result', () {
      final result = CaptureHelperCompressionResult.failure(
        errorMessage: 'Compression failed',
        originalSize: 1000000,
      );

      expect(result.success, false);
      expect(result.outputPath, null);
      expect(result.errorMessage, 'Compression failed');
    });

    test('formats sizes correctly', () {
      final result = CaptureHelperCompressionResult.success(
        outputPath: '/path/to/compressed.jpg',
        originalSize: 2048576, // 2 MB
        compressedSize: 512000, // 500 KB
      );

      expect(result.formattedOriginalSize, '2.0 MB');
      expect(result.formattedCompressedSize, '500.0 KB');
    });

    test('calculates compression ratio correctly', () {
      final result1 = CaptureHelperCompressionResult.success(
        outputPath: '/path/to/compressed.jpg',
        originalSize: 1000,
        compressedSize: 500,
      );
      expect(result1.compressionRatio, 0.5);
      expect(result1.reductionPercentage, 50.0);

      final result2 = CaptureHelperCompressionResult.success(
        outputPath: '/path/to/compressed.jpg',
        originalSize: 1000,
        compressedSize: 250,
      );
      expect(result2.compressionRatio, 0.75);
      expect(result2.reductionPercentage, 75.0);
    });
  });

  group('CaptureHelper', () {
    test('is a singleton', () {
      final instance1 = CaptureHelper();
      final instance2 = CaptureHelper();

      expect(identical(instance1, instance2), true);
    });
  });
}
