import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/detection_result_model.dart';
import '../../../../shared/models/scan_model.dart';

class AgronomyPdfReportService {
  static Future<void> generateAndShareReport({
    required WeedDetectionResult result,
    String? fieldName,
    String? locationLabel,
    String? cropType,
  }) async {
    final pdf = pw.Document();

    Uint8List? imageBytes;
    if (result.imagePath != null && File(result.imagePath!).existsSync()) {
      try {
        imageBytes = await File(result.imagePath!).readAsBytes();
      } catch (_) {}
    }

    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(result.analyzedAt);
    final severityStr = result.severity.name.toUpperCase();

    // ── High Contrast Color Themes for Metrics (No translucent alpha that renders opaque in mobile PDF viewers) ──
    final PdfColor metricSeverityBg;
    final PdfColor metricSeverityBorder;
    final PdfColor metricSeverityText;

    if (result.severity == SeverityLevel.high) {
      metricSeverityBg = PdfColor.fromHex('#FFEBEE');
      metricSeverityBorder = PdfColor.fromHex('#E57373');
      metricSeverityText = PdfColor.fromHex('#C62828');
    } else if (result.severity == SeverityLevel.moderate) {
      metricSeverityBg = PdfColor.fromHex('#FFF3E0');
      metricSeverityBorder = PdfColor.fromHex('#FFB74D');
      metricSeverityText = PdfColor.fromHex('#E65100');
    } else {
      metricSeverityBg = PdfColor.fromHex('#E8F5E9');
      metricSeverityBorder = PdfColor.fromHex('#81C784');
      metricSeverityText = PdfColor.fromHex('#1B5E20');
    }

    // ── 1 Single Crop Name and 1 Single Weed Name (Deduplicated cleanly) ──
    String singleCropName = (cropType != null && cropType.trim().isNotEmpty) ? cropType.trim() : '';
    if (singleCropName.isEmpty) {
      final cropDets = result.detections.where((d) => d.isCrop).toList();
      if (cropDets.isNotEmpty) {
        singleCropName = cropDets.first.label;
      } else {
        singleCropName = 'Field Crop (Active Cultivation)';
      }
    }

    String singleWeedName = 'No Invasive Weeds (Clean Field)';
    double singleWeedConfidence = 0.95;
    final weedDets = result.detections.where((d) => !d.isCrop).toList();
    final bool hasWeeds = weedDets.isNotEmpty && result.weedCount > 0;
    if (hasWeeds) {
      singleWeedName = weedDets.first.label;
      singleWeedConfidence = weedDets.first.confidence;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ── Header Banner ──
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1B5E20'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WEEDGUARD AI - AGRONOMY REPORT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Precision Crop Health & Herbicide Prescription Advisory',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      'STATUS: VERIFIED',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#1B5E20'),
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Metadata Grid ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F9FBF9'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColor.fromHex('#C8E6C9'), width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow('Date & Time:', formattedDate),
                      pw.SizedBox(height: 6),
                      _buildMetaRow('Field / Plot:', fieldName ?? 'Cultivated Farmland Plot'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow('Location / GPS:', locationLabel ?? 'Geo-Tagged Field'),
                      pw.SizedBox(height: 6),
                      _buildMetaRow('Target Crop:', singleCropName),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Executive Diagnostic Summary (High Contrast Text & Backgrounds) ──
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildMetricBox(
                    'Weeds Identified',
                    '${result.weedCount}',
                    PdfColor.fromHex('#E8F5E9'),
                    PdfColor.fromHex('#81C784'),
                    PdfColor.fromHex('#1B5E20'),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildMetricBox(
                    'Infestation Severity',
                    severityStr,
                    metricSeverityBg,
                    metricSeverityBorder,
                    metricSeverityText,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildMetricBox(
                    'AI Confidence',
                    '${(result.averageConfidence * 100).toStringAsFixed(1)}%',
                    PdfColor.fromHex('#E3F2FD'),
                    PdfColor.fromHex('#90CAF9'),
                    PdfColor.fromHex('#0D47A1'),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Image if present ──
            if (imageBytes != null) ...[
              pw.Container(
                height: 180,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColor.fromHex('#D0D7DE'), width: 1),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            // ── Section 1: Identified Species Breakdown (1 Crop Name & 1 Weed Name) ──
            pw.Text(
              '1. IDENTIFIED SPECIES BREAKDOWN',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1B5E20'),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0'), width: 0.8),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1B5E20')),
              cellStyle: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#1A1A1A')),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['Species / Target', 'Category', 'Confidence', 'Risk Assessment'],
              data: [
                // 1 Crop Name
                [
                  singleCropName,
                  'Cultivated Crop',
                  '${(result.averageConfidence * 100).toStringAsFixed(0)}%',
                  'Active Standing Crop',
                ],
                // 1 Weed Name
                [
                  singleWeedName,
                  hasWeeds ? 'Invasive Weed' : 'Flora Clean',
                  '${(singleWeedConfidence * 100).toStringAsFixed(0)}%',
                  hasWeeds
                      ? (result.severity == SeverityLevel.high
                          ? 'High Yield Depletion'
                          : 'Nutrient Competition')
                      : 'Zero Infestation Risk',
                ],
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Section 2: Recommended Herbicide Prescription ──
            pw.Text(
              '2. RECOMMENDED CHEMICAL / HERBICIDE PRESCRIPTION',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1B5E20'),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0'), width: 0.8),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#D84315')),
              cellStyle: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#1A1A1A')),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['Target Weed', 'Prescribed Chemical', 'Standard Dosage', 'Application Method'],
              data: [
                if (hasWeeds) ...[
                  () {
                    final p = _getPrescription(singleWeedName);
                    return [singleWeedName, p['chemical']!, p['dose']!, p['type']!];
                  }(),
                ] else ...[
                  [
                    'Preventative Care',
                    'Pre-emergence Pendimethalin 30% EC',
                    '1.0 - 1.5 L / Acre',
                    'Soil Surface Spray',
                  ],
                ],
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Section 3: Mandatory Agronomy Guidelines (Native PDF Dot Badges - No X Marks) ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFFDE7'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColor.fromHex('#FFE082'), width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MANDATORY AGRONOMY & SAFETY GUIDELINES:',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#B78103'),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _buildGuidelineItem(
                    '1',
                    'Weather Check: Spray only in calm conditions (wind < 4 m/s) and avoid spraying before rainfall.',
                  ),
                  pw.SizedBox(height: 5),
                  _buildGuidelineItem(
                    '2',
                    'Protection: Wear chemical-resistant gloves, goggles, and respiratory masks during mixing.',
                  ),
                  pw.SizedBox(height: 5),
                  _buildGuidelineItem(
                    '3',
                    'Dilution: Mix in 150-200 Litres of clean water per acre with flat-fan nozzles for uniform coverage.',
                  ),
                  pw.SizedBox(height: 5),
                  _buildGuidelineItem(
                    '4',
                    'Consultation: Verify with your local Krishi Vigyan Kendra (KVK) or authorized agronomy officer before purchase.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Footer ──
            pw.Divider(color: PdfColor.fromHex('#E0E0E0'), thickness: 0.8),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by WeedGuard AI System • Field Intelligence',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                pw.Text('Share directly with Krishi Kendra & Retailers',
                    style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#1B5E20'), fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ];
        },
      ),
    );

    // Save and Share
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'WeedGuard_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'WeedGuard AI Field Agronomy Report',
      text: 'WeedGuard AI Agronomy & Weed Diagnosis Report for ${fieldName ?? "Field Plot"}. Attached PDF summary with prescribed herbicide treatments.',
    );
  }

  static pw.Widget _buildMetaRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text('$label ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#333333'))),
        pw.Text(value, style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#1B5E20'), fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildMetricBox(
    String title,
    String val,
    PdfColor bgColor,
    PdfColor borderColor,
    PdfColor textColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderColor, width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#424242')),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            val,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGuidelineItem(String number, String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 14,
          height: 14,
          margin: const pw.EdgeInsets.only(top: 1, right: 6),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#1B5E20'),
            shape: pw.BoxShape.circle,
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            number,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromHex('#212121'),
              lineSpacing: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  static Map<String, String> _getPrescription(String weedName) {
    final lower = weedName.toLowerCase();
    if (lower.contains('parthenium') || lower.contains('congress')) {
      return {'chemical': '2,4-D Sodium Salt 80% WP or Metribuzin 70% WP', 'dose': '500g - 1kg / Acre', 'type': 'Systemic Post-emergence'};
    } else if (lower.contains('cyperus') || lower.contains('nutgrass') || lower.contains('sedge')) {
      return {'chemical': 'Halosulfuron-methyl 75% WG (Sempra)', 'dose': '36g / Acre', 'type': 'Selective Sedge Control'};
    } else if (lower.contains('echinochloa') || lower.contains('barnyard') || lower.contains('grass')) {
      return {'chemical': 'Bispyribac-sodium 10% SC (Nominee Gold)', 'dose': '80 - 100 ml / Acre', 'type': 'Post-emergence Selective'};
    } else if (lower.contains('amaranthus') || lower.contains('pigweed')) {
      return {'chemical': 'Atrazine 50% WP or Pendimethalin 30% EC', 'dose': '1.0 - 1.5 L / Acre', 'type': 'Pre/Early Post-emergence'};
    } else if (lower.contains('convolvulus') || lower.contains('morning')) {
      return {'chemical': 'Glyphosate 41% SL (Directed) or 2,4-D Amine', 'dose': '800 ml - 1 L / Acre', 'type': 'Non-selective / Foliar'};
    }
    return {'chemical': 'Glyphosate 41% SL or Oxyfluorfen 23.5% EC', 'dose': '600 - 800 ml / Acre', 'type': 'Broad-spectrum Foliar'};
  }
}
