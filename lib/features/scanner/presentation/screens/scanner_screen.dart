import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/weed_detection_service.dart';
import '../../../../shared/models/detection_result_model.dart';
import '../../../../shared/models/scan_model.dart';
import '../../../scanner/data/scan_repository.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final String? fieldId;
  const ScannerScreen({super.key, this.fieldId});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

enum _ScannerStep { select, preview, analyzing }

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _picker = ImagePicker();
  final _detectionService = MockWeedDetectionService();
  File? _imageFile;
  _ScannerStep _step = _ScannerStep.select;
  String _analysisMessage = 'Analyzing field image...';
  String? _error;

  static const _analysisMessages = [
    'Analyzing field image...',
    'Detecting vegetation...',
    'Identifying possible weeds...',
    'Generating field assessment...',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 88);
      if (picked == null) return;
      final file = File(picked.path);
      final size = await file.length();
      if (size > AppConstants.maxImageSizeBytes) {
        setState(() => _error = 'Image is too large. Maximum size is 10 MB.');
        return;
      }
      setState(() { _imageFile = file; _step = _ScannerStep.preview; _error = null; });
    } catch (_) {
      setState(() => _error = 'Unable to access the image. Please try again.');
    }
  }

  Future<void> _analyze() async {
    if (_imageFile == null) return;
    setState(() { _step = _ScannerStep.analyzing; _error = null; });
    _runAnalysisMessages();
    try {
      final result = await _detectionService.analyzeImage(_imageFile!);
      String? savedScanId;
      String? uploadedUrl;
      final scanRepo = ScanRepository(Supabase.instance.client);
      if (widget.fieldId != null) {
        uploadedUrl = await scanRepo.uploadScanImage(_imageFile!, widget.fieldId!);
      }
      final savedScan = await scanRepo.saveScan(
          fieldId: widget.fieldId, result: result, imageUrl: uploadedUrl);
      savedScanId = savedScan.id;
      ref.invalidate(dashboardFieldsProvider);
      ref.invalidate(dashboardScansProvider);
      final finalResult = WeedDetectionResult(
        imagePath: result.imagePath, imageUrl: uploadedUrl,
        detections: result.detections, weedCount: result.weedCount,
        averageConfidence: result.averageConfidence, severity: result.severity,
        infestationScore: result.infestationScore, zones: result.zones,
        priorityZone: result.priorityZone, analyzedAt: result.analyzedAt,
        isMockDetection: result.isMockDetection,
      );
      if (mounted) {
        context.push('/detection-result', extra: {
          'result': finalResult,
          'fieldId': widget.fieldId ?? '',
          'scanId': savedScanId,
        });
        setState(() { _step = _ScannerStep.select; _imageFile = null; });
      }
    } catch (e) {
      if (mounted) setState(() {
        _step = _ScannerStep.preview;
        _error = 'Analysis failed. Please check your connection and try again.';
      });
    }
  }

  void _runAnalysisMessages() async {
    for (int i = 0; i < _analysisMessages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted && _step == _ScannerStep.analyzing) {
        setState(() => _analysisMessage = _analysisMessages[i]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      // No AppBar at all
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_step) {
            _ScannerStep.select => _SelectStep(
                onCamera: () => _pickImage(ImageSource.camera),
                onGallery: () => _pickImage(ImageSource.gallery),
                onBack: () => context.pop(),
                error: _error),
            _ScannerStep.preview => _PreviewStep(
                imageFile: _imageFile!,
                onRetake: () => setState(() { _step = _ScannerStep.select; _imageFile = null; }),
                onAnalyze: _analyze,
                error: _error),
            _ScannerStep.analyzing => _AnalyzingStep(message: _analysisMessage),
          },
        ),
      ),
    );
  }
}

// ─── SELECT STEP ─────────────────────────────────────────────────────────────
class _SelectStep extends StatelessWidget {
  final VoidCallback onCamera, onGallery, onBack;
  final String? error;
  const _SelectStep({required this.onCamera, required this.onGallery, required this.onBack, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          ),

        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final imgW = constraints.maxWidth;
            final imgH = imgW / (1033 / 1336);

            // Tap zone fractions (relative to image height)
            // Camera card: y 0.269 → 0.516
            // Gallery card: y 0.524 → 0.748
            final cameraTop    = imgH * 0.269;
            final cameraBottom = imgH * 0.516;
            final galleryTop    = imgH * 0.524;
            final galleryBottom = imgH * 0.748;

            // Back arrow: sits at top-left of image, over the baked-in arrow area
            // The image has "Scan field" text + arrow at top ~8% of height
            final backBtnTop = imgH * 0.01;

            return SingleChildScrollView(
              child: SizedBox(
                width: imgW,
                height: imgH,
                child: Stack(
                  children: [
                    // Full template image
                    Image.asset('assets/images/scanner_bg.png',
                        width: imgW, height: imgH, fit: BoxFit.fill),

                    // Floating back arrow (only widget, positioned over image arrow)
                    Positioned(
                      left: 8,
                      top: backBtnTop,
                      child: GestureDetector(
                        onTap: onBack,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 44, height: 44,
                          color: Colors.transparent,
                        ),
                      ),
                    ),

                    // Transparent Camera tap zone
                    Positioned(
                      left: 0, right: 0,
                      top: cameraTop,
                      height: cameraBottom - cameraTop,
                      child: GestureDetector(
                        onTap: onCamera,
                        behavior: HitTestBehavior.translucent,
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // Transparent Gallery tap zone
                    Positioned(
                      left: 0, right: 0,
                      top: galleryTop,
                      height: galleryBottom - galleryTop,
                      child: GestureDetector(
                        onTap: onGallery,
                        behavior: HitTestBehavior.translucent,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── PREVIEW STEP ────────────────────────────────────────────────────────────
class _PreviewStep extends StatelessWidget {
  final File imageFile;
  final VoidCallback onRetake, onAnalyze;
  final String? error;
  const _PreviewStep({required this.imageFile, required this.onRetake, required this.onAnalyze, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Container(
          color: Colors.black,
          child: Image.file(imageFile, fit: BoxFit.contain, width: double.infinity),
        )),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(children: [
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
              const SizedBox(height: 12),
            ],
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                  onPressed: onRetake, icon: const Icon(Icons.refresh_outlined), label: const Text('Retake'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                  onPressed: onAnalyze, icon: const Icon(Icons.search_outlined), label: const Text('Analyse'))),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ─── ANALYZING STEP ──────────────────────────────────────────────────────────
class _AnalyzingStep extends StatelessWidget {
  final String message;
  const _AnalyzingStep({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.search_outlined, size: 36, color: Color(0xFF2D6A4F))),
          const SizedBox(height: 28),
          const CircularProgressIndicator(color: Color(0xFF2D6A4F)),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(message, key: ValueKey(message),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1B4332)),
              textAlign: TextAlign.center),
          ),
          const SizedBox(height: 10),
          const Text('This may take a moment.',
              style: TextStyle(fontSize: 13, color: Color(0xFF757575)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
