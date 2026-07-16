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

  // Options de scan
  OutputFormat _selectedFormat = OutputFormat.jpeg;
  CaptureMode _captureMode = CaptureMode.manual;
  int _pageLimit = 1;
  bool _enableQualityCheck = false;

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
          captureMode: _captureMode,
          pageLimit: _pageLimit,
          outputFormat: _selectedFormat,
          autoCompress: false,
          compressionQuality: 80,
          // Contrôle de qualité optionnel
          minSharpnessScore: _enableQualityCheck ? 40 : 0,
          minBrightnessScore: _enableQualityCheck ? 30 : 0,
          minDocumentCoverage: 40,
          autoCaptureDelay: 1.0,
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

  String _getModeDescription() {
    final mode = _captureMode == CaptureMode.auto ? 'Auto' : 'Manuel';
    final pages = _pageLimit == 0 ? 'Multi' : (_pageLimit == 1 ? 'Single' : '$_pageLimit pages');
    return '$mode - $pages';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Helper Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Icon(
                Icons.document_scanner,
                size: 80,
                color: _isScanningAvailable ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Document Scanner',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Scan documents using your device camera',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Section: Mode de capture
              _buildSectionTitle('Mode de capture'),
              const SizedBox(height: 8),
              SegmentedButton<CaptureMode>(
                segments: const [
                  ButtonSegment<CaptureMode>(
                    value: CaptureMode.manual,
                    label: Text('Manuel'),
                    icon: Icon(Icons.touch_app),
                  ),
                  ButtonSegment<CaptureMode>(
                    value: CaptureMode.auto,
                    label: Text('Auto'),
                    icon: Icon(Icons.auto_awesome),
                  ),
                ],
                selected: {_captureMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _captureMode = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                _captureMode == CaptureMode.auto
                    ? 'Capture automatique après 1s de stabilité + bouton manuel'
                    : 'Capture uniquement via le bouton',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Nombre de pages
              _buildSectionTitle('Nombre de pages'),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 1, label: Text('1')),
                  ButtonSegment<int>(value: 2, label: Text('2')),
                  ButtonSegment<int>(value: 5, label: Text('5')),
                  ButtonSegment<int>(value: 0, label: Text('∞')),
                ],
                selected: {_pageLimit},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _pageLimit = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Section: Format de sortie
              _buildSectionTitle('Format de sortie'),
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
              const SizedBox(height: 24),

              // Section: Options avancées
              _buildSectionTitle('Options avancées'),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Contrôle de qualité'),
                subtitle: const Text('Vérifie la netteté et la luminosité'),
                value: _enableQualityCheck,
                onChanged: (value) {
                  setState(() {
                    _enableQualityCheck = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Bouton de scan
              if (_isScanning)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _isScanningAvailable ? _scanDocument : null,
                  icon: const Icon(Icons.camera_alt, size: 28),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        const Text('Scanner', style: TextStyle(fontSize: 18)),
                        Text(
                          _getModeDescription(),
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  ),
                ),
              const SizedBox(height: 24),

              // Presets rapides
              _buildSectionTitle('Presets rapides'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildPresetChip('Single Auto', CaptureMode.auto, 1),
                  _buildPresetChip('Single Manuel', CaptureMode.manual, 1),
                  _buildPresetChip('Multi Auto', CaptureMode.auto, 0),
                  _buildPresetChip('Multi Manuel', CaptureMode.manual, 0),
                ],
              ),
              const SizedBox(height: 24),

              // Status message
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPresetChip(String label, CaptureMode mode, int pages) {
    final isSelected = _captureMode == mode && _pageLimit == pages;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      onPressed: () {
        setState(() {
          _captureMode = mode;
          _pageLimit = pages;
        });
      },
    );
  }
}
