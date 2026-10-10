import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/models/detection_result_model.dart';

class DetectionOverlayPainter extends CustomPainter {
  final List<WeedDetection> detections;
  DetectionOverlayPainter({required this.detections});

  static const _cropKeywords = ['maize', 'rice', 'wheat', 'soybean', 'cotton', 'corn',
    'sugarcane', 'barley', 'sorghum', 'sunflower', 'tomato', 'potato', 'crop'];

  bool _isCrop(String label) {
    final lower = label.toLowerCase();
    return _cropKeywords.any((k) => lower.contains(k));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    for (final d in detections) {
      if (d.boundingBox == null) continue;
      final isCrop = _isCrop(d.label);
      final primaryColor = isCrop ? const Color(0xFF2E7D32) : const Color(0xFFE53935);
      final glowColor = primaryColor.withOpacity(0.35);

      final rect = Rect.fromLTWH(
        d.boundingBox!.x * size.width,
        d.boundingBox!.y * size.height,
        d.boundingBox!.width * size.width,
        d.boundingBox!.height * size.height,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      // 1. Subtle glow
      final glowPaint = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(rrect, glowPaint);

      // 2. Main sleek border
      final boxPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(rrect, boxPaint);

      // 3. Pill badge at top-left
      final label = '${d.label} ${(d.confidence * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeH = 20.0;
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
      oldDelegate.detections != detections;
}
