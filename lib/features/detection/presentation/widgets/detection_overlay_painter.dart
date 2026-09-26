import 'package:flutter/material.dart';
import '../../../../shared/models/detection_result_model.dart';

class DetectionOverlayPainter extends CustomPainter {
  final List<WeedDetection> detections;
  DetectionOverlayPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final labelBgPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;

    const textStyle = TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600);

    for (final d in detections) {
      final rect = Rect.fromLTWH(
        d.boundingBox.x * size.width,
        d.boundingBox.y * size.height,
        d.boundingBox.width * size.width,
        d.boundingBox.height * size.height,
      );
      canvas.drawRect(rect, boxPaint);

      final label = '${(d.confidence * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(rect.left, rect.top - 18, tp.width + 8, 18);
      canvas.drawRect(labelRect, labelBgPaint);
      tp.paint(canvas, Offset(rect.left + 4, rect.top - 16));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) =>
      oldDelegate.detections != detections;
}
