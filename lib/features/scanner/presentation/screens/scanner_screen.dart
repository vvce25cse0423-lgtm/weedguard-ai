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
import '../../../history/presentation/screens/scan_history_screen.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/widgets/offline_banner.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final String? fieldId;
  const ScannerScreen({super.key, this.fieldId});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

enum _ScannerStep { select, preview, analyzing }

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _picker = ImagePicker();
  final _detectionService = GeminiWeedDetectionService();
  File? _imageFile;
  _ScannerStep _step = _ScannerStep.select;
  String _analysisMessage = '';
  String? _error;

  List<String> _analysisMessages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.analyzing,
      l10n.get('loading'),
      l10n.get('analyzing'),
      l10n.get('analyzing'),
    ];
  }

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
    _analysisMessage = AppLocalizations.of(context).analyzing;
    _runAnalysisMessages(context);
    try {
      final result = await _detectionService.analyzeImage(_imageFile!);
      String? savedScanId;
      String? uploadedUrl;
      try {
        final scanRepo = ScanRepository(Supabase.instance.client);
        final fid = widget.fieldId ?? '';
        if (fid.isNotEmpty) {
          uploadedUrl = await scanRepo.uploadScanImage(_imageFile!, fid);
        }
        final savedScan = await scanRepo.saveScan(
            fieldId: fid.isEmpty ? null : fid, result: result, imageUrl: uploadedUrl);
        savedScanId = savedScan.id;
      } catch (saveErr) {
        // Save/upload failed — continue to show result anyway
      } finally {
        ref.invalidate(dashboardFieldsProvider);
        ref.invalidate(dashboardScansProvider);
        ref.invalidate(scanHistoryProvider);
      }
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
          'scanId': savedScanId ?? '',
        });
        setState(() { _step = _ScannerStep.select; _imageFile = null; });
      }
    } on AnalysisException catch (e) {
      if (mounted) setState(() {
        _step = _ScannerStep.preview;
        _error = e.message;
      });
    } catch (e) {
      if (mounted) setState(() {
        _step = _ScannerStep.preview;
        _error = 'Analysis failed. Please check your connection and try again.';
      });
    }
  }

  void _runAnalysisMessages(BuildContext context) async {
    final msgs = [
      AppLocalizations.of(context).analyzing,
      AppLocalizations.of(context).get('loading'),
      AppLocalizations.of(context).get('analyzing'),
      AppLocalizations.of(context).get('analyzing'),
    ];
    for (int i = 0; i < msgs.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted && _step == _ScannerStep.analyzing) {
        setState(() => _analysisMessage = msgs[i]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // No AppBar at all
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
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
          ],
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
                  onPressed: onRetake, icon: const Icon(Icons.refresh_outlined), label: Text(AppLocalizations.of(context).get('retry')))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                  onPressed: onAnalyze, icon: const Icon(Icons.search_outlined), label: Text(AppLocalizations.of(context).analyzing.replaceAll('…','')))),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ─── ANALYZING STEP ──────────────────────────────────────────────────────────
class _AnalyzingStep extends StatefulWidget {
  final String message;
  const _AnalyzingStep({required this.message});
  @override
  State<_AnalyzingStep> createState() => _AnalyzingStepState();
}

class _AnalyzingStepState extends State<_AnalyzingStep> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF2D6A4F).withOpacity(0.25), blurRadius: 20, spreadRadius: 4)],
                ),
                child: const Icon(Icons.biotech_outlined, size: 48, color: Color(0xFF2D6A4F)),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: Color(0xFF2D6A4F),
                backgroundColor: Color(0xFFE8F5E9),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim), child: child)),
              child: Text(widget.message.isEmpty ? AppLocalizations.of(context).analyzing : widget.message,
                key: ValueKey(widget.message),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1B4332)),
                textAlign: TextAlign.center),
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context).get('loading'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF757575)), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
