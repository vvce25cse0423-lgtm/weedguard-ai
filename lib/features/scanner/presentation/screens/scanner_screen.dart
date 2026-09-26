import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/weed_detection_service.dart';
import '../../../../shared/models/detection_result_model.dart';
import '../../../../shared/models/scan_model.dart';
import '../../../scanner/data/scan_repository.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final String? fieldId;
  const ScannerScreen({super.key, this.fieldId});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

enum _ScannerStep { select, preview, analyzing, done }

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
      final picked = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 88);
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
      if (widget.fieldId != null) {
        final scanRepo = ScanRepository(Supabase.instance.client);
        uploadedUrl = await scanRepo.uploadScanImage(_imageFile!, widget.fieldId!);
        final savedScan = await scanRepo.saveScan(
          fieldId: widget.fieldId!,
          result: result,
          imageUrl: uploadedUrl,
        );
        savedScanId = savedScan.id;
      }
      final finalResult = WeedDetectionResult(
        imagePath: result.imagePath,
        imageUrl: uploadedUrl,
        detections: result.detections,
        weedCount: result.weedCount,
        averageConfidence: result.averageConfidence,
        severity: result.severity,
        infestationScore: result.infestationScore,
        zones: result.zones,
        priorityZone: result.priorityZone,
        analyzedAt: result.analyzedAt,
        isMockDetection: result.isMockDetection,
      );
      if (mounted) {
        context.push('/detection-result', extra: {
          'result': finalResult,
          'fieldId': widget.fieldId ?? '',
          'scanId': savedScanId,
        });
        setState(() => _step = _ScannerStep.select);
        _imageFile = null;
      }
    } catch (e) {
      if (mounted) setState(() { _step = _ScannerStep.preview; _error = 'Analysis failed. Please check your connection and try again.'; });
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
      appBar: AppBar(
        title: const Text('Scan field'),
        leading: _step == _ScannerStep.preview
            ? BackButton(onPressed: () => setState(() { _step = _ScannerStep.select; _imageFile = null; }))
            : const BackButton(),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (_step) {
          _ScannerStep.select => _SelectImageStep(onPick: _pickImage, error: _error),
          _ScannerStep.preview => _PreviewStep(imageFile: _imageFile!, onRetake: () => setState(() { _step = _ScannerStep.select; _imageFile = null; }), onAnalyze: _analyze, error: _error),
          _ScannerStep.analyzing => _AnalyzingStep(message: _analysisMessage),
          _ScannerStep.done => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _SelectImageStep extends StatelessWidget {
  final Future<void> Function(ImageSource) onPick;
  final String? error;
  const _SelectImageStep({required this.onPick, this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Capture field image', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text('Take a clear, well-lit photograph of the crop area. Ensure the image covers the target zone adequately.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(6)),
              child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
            const SizedBox(height: 16),
          ],
          _ImageSourceTile(
            icon: Icons.photo_camera_outlined,
            title: 'Camera',
            subtitle: 'Capture a new photograph',
            onTap: () => onPick(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _ImageSourceTile(
            icon: Icons.photo_library_outlined,
            title: 'Gallery',
            subtitle: 'Choose from existing photos',
            onTap: () => onPick(ImageSource.gallery),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Detection accuracy depends on image quality. Avoid shadows across the frame. Capture from a consistent angle for reliable comparison between scans.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ImageSourceTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  final File imageFile;
  final VoidCallback onRetake;
  final VoidCallback onAnalyze;
  final String? error;
  const _PreviewStep({required this.imageFile, required this.onRetake, required this.onAnalyze, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Image.file(imageFile, fit: BoxFit.contain, width: double.infinity),
          ),
        ),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(6)),
                  child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRetake,
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAnalyze,
                      icon: const Icon(Icons.search_outlined),
                      label: const Text('Analyse'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyzingStep extends StatelessWidget {
  final String message;
  const _AnalyzingStep({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
              child: const Icon(Icons.search_outlined, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                message,
                key: ValueKey(message),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This may take a moment.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Demo mode — mock detection', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
