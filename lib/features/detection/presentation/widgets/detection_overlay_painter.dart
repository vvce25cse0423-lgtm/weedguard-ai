import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/models/detection_result_model.dart';
import '../../../../core/l10n/app_localizations.dart';

class DetectionOverlayPainter extends CustomPainter {
  final List<WeedDetection> detections;
  final AppLocalizations? l10n;
  DetectionOverlayPainter({required this.detections, this.l10n});

  static const _cropKeywords = [
    'maize', 'rice', 'wheat', 'soybean', 'cotton', 'corn',
    'sugarcane', 'barley', 'sorghum', 'sunflower', 'tomato', 'potato', 'crop', 'onion',
    'chilli', 'chili', 'garlic', 'ginger', 'turmeric', 'brinjal', 'eggplant', 'okra', 'ragi'
  ];

  bool _isCrop(WeedDetection d) {
    if (d.isCrop) return true;
    final lower = d.label.toLowerCase();
    return _cropKeywords.any((k) => lower.contains(k));
  }

  // Pre-configured proportional boxes across quadrants for visual clarity
  static const _syntheticBoxes = [
    Rect.fromLTWH(0.08, 0.18, 0.38, 0.44), // Upper-left
    Rect.fromLTWH(0.54, 0.14, 0.38, 0.42), // Upper-right
    Rect.fromLTWH(0.12, 0.52, 0.36, 0.40), // Lower-left
    Rect.fromLTWH(0.52, 0.50, 0.40, 0.42), // Lower-right
    Rect.fromLTWH(0.28, 0.28, 0.44, 0.46), // Center
    Rect.fromLTWH(0.32, 0.10, 0.36, 0.38), // Upper-center
    Rect.fromLTWH(0.30, 0.54, 0.38, 0.38), // Lower-center
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    // Filter to valid detections to display
    final displayDetections = detections.where((d) => d.label.trim().isNotEmpty).toList();
    if (displayDetections.isEmpty) return;

    for (int i = 0; i < displayDetections.length; i++) {
      final d = displayDetections[i];
      final isCrop = _isCrop(d);

      // Red boundaries for both identified crop and weeds
      const primaryColor = Color(0xFFE53935);
      final glowColor = primaryColor.withOpacity(0.35);

      final Rect rect;
      if (d.boundingBox != null) {
        rect = Rect.fromLTWH(
          d.boundingBox!.x * size.width,
          d.boundingBox!.y * size.height,
          d.boundingBox!.width * size.width,
          d.boundingBox!.height * size.height,
        );
      } else {
        // Fallback boundary box scaled to image canvas
        final normRect = _syntheticBoxes[i % _syntheticBoxes.length];
        rect = Rect.fromLTWH(
          normRect.left * size.width,
          normRect.top * size.height,
          normRect.width * size.width,
          normRect.height * size.height,
        );
      }

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      // 1. Subtle glow
      final glowPaint = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(rrect, glowPaint);

      // 2. Main sleek red border
      final boxPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      canvas.drawRRect(rrect, boxPaint);

      // 3. Pill badge at top-left
      final translatedName = l10n != null
          ? (isCrop ? l10n!.translateCrop(d.label) : l10n!.translateWeed(d.label))
          : d.label;
      final shortName = translatedName.split('(').first.trim();
      final tag = isCrop ? 'Crop: ' : 'Weed: ';
      final confPercent = (d.confidence * 100).toStringAsFixed(0);
      final label = "$tag$shortName $confPercent%";
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      const badgeH = 20.0;
      final badgeW = tp.width + 12;
      final badgeTop = math.max(4.0, rect.top - badgeH - 2);
      final badgeLeft = math.min(size.width - badgeW - 4, math.max(4.0, rect.left));
      final badgeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeLeft, badgeTop, badgeW, badgeH),
        const Radius.circular(6),
      );

      final badgePaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(badgeRRect, badgePaint);

      tp.paint(canvas, Offset(badgeLeft + 6, badgeTop + 2.5));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) =>
      oldDelegate.detections != detections || oldDelegate.l10n != l10n;
}
