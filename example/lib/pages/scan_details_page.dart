import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capture_helper/capture_helper.dart';

class ScanDetailsPage extends StatefulWidget {
  final List<String> imagePaths;

  const ScanDetailsPage({
    super.key,
    required this.imagePaths,
  });

  @override
  State<ScanDetailsPage> createState() => _ScanDetailsPageState();
}

class _ScanDetailsPageState extends State<ScanDetailsPage> {
  final _captureHelper = CaptureHelper();
  int _currentImageIndex = 0;
  double _compressionQuality = 80.0;
  bool _isCompressing = false;
  CaptureHelperCompressionResult? _compressionResult;

  String get currentImagePath => widget.imagePaths[_currentImageIndex];

  Future<int> _getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    return 0;
  }

  Future<void> _compressImage() async {
    setState(() {
      _isCompressing = true;
      _compressionResult = null;
    });

    try {
      final result = await _captureHelper.compressImage(
        imagePath: currentImagePath,
        quality: _compressionQuality.toInt(),
      );

      if (!mounted) return;

      setState(() {
        _compressionResult = result;
      });

      if (result.success) {
        _showMessage(
          'Compressed successfully! Saved ${result.formattedSavedBytes}',
        );
      } else {
        _showMessage('Compression failed: ${result.errorMessage}');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan Details (${_currentImageIndex + 1}/${widget.imagePaths.length})',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.imagePaths.length > 1) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentImageIndex > 0
                  ? () {
                      setState(() {
                        _currentImageIndex--;
                        _compressionResult = null;
                      });
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentImageIndex < widget.imagePaths.length - 1
                  ? () {
                      setState(() {
                        _currentImageIndex++;
                        _compressionResult = null;
                      });
                    }
                  : null,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Preview
            Container(
              height: 400,
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.file(
                File(currentImagePath),
                fit: BoxFit.contain,
              ),
            ),

            // Image Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Image',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<int>(
                    future: _getFileSize(currentImagePath),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final size = snapshot.data!;
                        final sizeKB = (size / 1024).toStringAsFixed(1);
                        final sizeMB = (size / (1024 * 1024)).toStringAsFixed(2);
                        final formattedSize = size > 1024 * 1024 ? '$sizeMB MB' : '$sizeKB KB';

                        return Text(
                          'Size: $formattedSize',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        );
                      }
                      return const Text('Loading...');
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Path: ${currentImagePath.split('/').last}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 32),

                  // Compression Section
                  Text(
                    'Image Compression',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Quality Slider
                  Row(
                    children: [
                      Text(
                        'Quality:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _compressionQuality,
                          min: 10,
                          max: 100,
                          divisions: 18,
                          label: _compressionQuality.toInt().toString(),
                          onChanged: (value) {
                            setState(() {
                              _compressionQuality = value;
                              _compressionResult = null;
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_compressionQuality.toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    _getQualityDescription(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Compress Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCompressing ? null : _compressImage,
                      icon: _isCompressing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.compress),
                      label: Text(
                        _isCompressing ? 'Compressing...' : 'Compress Image',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Compression Result
                  if (_compressionResult != null && _compressionResult!.success) ...[
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Compression Successful',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildResultRow(
                              'Original Size',
                              _compressionResult!.formattedOriginalSize,
                            ),
                            _buildResultRow(
                              'Compressed Size',
                              _compressionResult!.formattedCompressedSize,
                            ),
                            _buildResultRow(
                              'Space Saved',
                              _compressionResult!.formattedSavedBytes,
                            ),
                            _buildResultRow(
                              'Reduction',
                              '${_compressionResult!.reductionPercentage.toStringAsFixed(1)}%',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Output: ${_compressionResult!.outputPath?.split('/').last ?? ''}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityDescription() {
    if (_compressionQuality >= 85) {
      return 'High quality - Minimal compression, larger file size';
    } else if (_compressionQuality >= 70) {
      return 'Good quality - Balanced compression and quality';
    } else if (_compressionQuality >= 50) {
      return 'Medium quality - More compression, smaller file size';
    } else {
      return 'Low quality - Maximum compression, smallest file size';
    }
  }
}
