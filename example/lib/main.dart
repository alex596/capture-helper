import 'package:flutter/material.dart';
import 'package:capture_helper/capture_helper.dart';
import 'package:capture_helper_example/pages/scan_details_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capture Helper Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _captureHelper = CaptureHelper();
  bool _isScanning = false;
  bool _isScanningAvailable = false;
  String? _statusMessage;
  OutputFormat _selectedFormat = OutputFormat.jpeg;
  bool _useAutomaticCapture = true;
  int _pageLimit = 0;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _captureHelper.isScanningAvailable();
    setState(() {
      _isScanningAvailable = available;
      if (!available) {
        _statusMessage = 'Document scanning not available on this device';
      }
    });
  }

  Future<void> _scanDocument() async {
    if (!_isScanningAvailable) {
      _showMessage('Scanning not available');
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Opening scanner...';
    });

    try {
      final result = await _captureHelper.scanDocument(
        options: CaptureHelperScanOptions(
          autoCompress: false,
          compressionQuality: 80,
          outputFormat: _selectedFormat,
          useAutomaticCapture: _useAutomaticCapture,
          pageLimit: _pageLimit,
        ),
      );

      if (!mounted) return;

      if (result.success && result.imagePaths.isNotEmpty) {
        setState(() {
          _statusMessage = 'Successfully scanned ${result.imageCount} image(s)';
        });

        // Navigate to details page
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ScanDetailsPage(
              imagePaths: result.imagePaths,
            ),
          ),
        );
      } else if (result.wasCancelled) {
        setState(() {
          _statusMessage = 'Scan cancelled';
        });
      } else {
        setState(() {
          _statusMessage = 'Error: ${result.errorMessage}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
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
        title: const Text('Capture Helper Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.document_scanner,
                  size: 100,
                  color: _isScanningAvailable ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                const SizedBox(height: 32),
                Text(
                  'Document Scanner',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan documents using your device camera',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Options de scan
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Options de scan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sélecteur de format
                        const Text('Format de sortie:'),
                        const SizedBox(height: 8),
                        SegmentedButton<OutputFormat>(
                          segments: const [
                            ButtonSegment<OutputFormat>(
                              value: OutputFormat.jpeg,
                              label: Text('JPEG'),
                            ),
                            ButtonSegment<OutputFormat>(
                              value: OutputFormat.png,
                              label: Text('PNG'),
                            ),
                          ],
                          selected: {_selectedFormat},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedFormat = newSelection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Capture automatique
                        SwitchListTile(
                          title: const Text('Capture automatique'),
                          subtitle: Text(
                            _useAutomaticCapture
                                ? 'La photo est prise automatiquement quand le document est détecté'
                                : 'Vous devez appuyer sur le bouton pour capturer',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          value: _useAutomaticCapture,
                          onChanged: (value) {
                            setState(() {
                              _useAutomaticCapture = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),

                        // Limite de pages
                        const SizedBox(height: 8),
                        Text('Limite de pages: ${_pageLimit == 0 ? 'Illimité' : _pageLimit}'),
                        Slider(
                          value: _pageLimit.toDouble(),
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _pageLimit == 0 ? 'Illimité' : '$_pageLimit',
                          onChanged: (value) {
                            setState(() {
                              _pageLimit = value.toInt();
                            });
                          },
                        ),
                        Text(
                          _pageLimit == 0
                              ? 'Aucune limite de pages'
                              : 'Le scanner se fermera après $_pageLimit page${_pageLimit > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isScanning)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _isScanningAvailable ? _scanDocument : null,
                    icon: const Icon(Icons.camera_alt),
                    label: Text('Scan as ${_selectedFormat.name.toUpperCase()}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (_statusMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isScanningAvailable ? Icons.info_outline : Icons.warning_amber,
                          color: _isScanningAvailable ? Colors.blue : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
