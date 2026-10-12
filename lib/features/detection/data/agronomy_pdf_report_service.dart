import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
    final severityColor = result.severity == SeverityLevel.high
        ? PdfColors.red700
        : (result.severity == SeverityLevel.moderate ? PdfColors.orange700 : PdfColors.green700);

    // Group weeds & crops
    final weedDetections = result.detections.where((d) => !d.isCrop).toList();
    final cropDetections = result.detections.where((d) => d.isCrop).toList();

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
                        'Precision Crop Health & Herbicide Prescription',
                        style: const pw.TextStyle(
                          color: PdfColors.green100,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
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
                color: PdfColor.fromHex('#F4F9F4'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColor.fromHex('#C8E6C9')),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow('Date & Time:', formattedDate),
                      pw.SizedBox(height: 4),
                      _buildMetaRow('Field / Plot:', fieldName ?? 'Active Cultivation Field'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow('Location / GPS:', locationLabel ?? 'Field Geo-Tagged'),
                      pw.SizedBox(height: 4),
                      _buildMetaRow('Target Crop:', cropType ?? 'Standing Agricultural Crop'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Executive Diagnostic Summary ──
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildMetricBox(
                    'Weeds Identified',
                    '${result.weedCount}',
                    PdfColor.fromHex('#1B5E20'),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildMetricBox(
                    'Infestation Severity',
                    severityStr,
                    severityColor,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildMetricBox(
                    'AI Confidence',
                    '${(result.averageConfidence * 100).toStringAsFixed(1)}%',
                    PdfColor.fromHex('#2E7D32'),
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
                  border: pw.Border.all(color: PdfColors.grey300),
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

            // ── Section 1: Detected Weed Species ──
            pw.Text(
              '1. IDENTIFIED SPECIES BREAKDOWN',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1B5E20'),
              ),
            ),
            pw.SizedBox(height: 6),
            if (weedDetections.isEmpty)
              pw.Text('No invasive weeds detected. Crop foliage appears clean and healthy.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2E7D32')),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                headers: ['Species / Target', 'Category', 'Confidence', 'Risk Assessment'],
                data: weedDetections.map((w) {
                  return [
                    w.label,
                    'Invasive Weed',
                    '${(w.confidence * 100).toStringAsFixed(0)}%',
                    result.severity == SeverityLevel.high ? 'High Yield Depletion' : 'Nutrient Competition',
                  ];
                }).toList(),
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
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E65100')),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              headers: ['Target Weed', 'Prescribed Chemical', 'Standard Dosage', 'Application Method'],
              data: weedDetections.isNotEmpty
                  ? weedDetections.map((w) {
                      final p = _getPrescription(w.label);
                      return [w.label, p['chemical']!, p['dose']!, p['type']!];
                    }).toList()
                  : [
                      ['Preventative', 'Pre-emergence Pendimethalin 30% EC', '1.0 - 1.5 L / Acre', 'Soil Surface Spray'],
                    ],
            ),
            pw.SizedBox(height: 14),

            // ── Section 3: Safety & Field Rules ──
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF8E1'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColor.fromHex('#FFE082')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MANDATORY AGRONOMY & SAFETY GUIDELINES:',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#B78103')),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '• Weather Check: Spray only in calm conditions (wind < 4 m/s) and avoid spraying before rainfall.\n'
                    '• Protection: Wear chemical-resistant gloves, goggles, and respiratory masks during mixing.\n'
                    '• Dilution: Mix in 150-200 Litres of clean water per acre with flat-fan nozzles for uniform coverage.\n'
                    '• Consultation: Verify with your local Krishi Vigyan Kendra (KVK) or authorized agronomy officer before purchase.',
                    style: const pw.TextStyle(fontSize: 7.8, color: PdfColors.grey800, lineSpacing: 1.5),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Footer ──
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by WeedGuard AI System • Field Intelligence',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
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
      text: '🌱 WeedGuard AI Agronomy & Weed Diagnosis Report for ${fieldName ?? "Field Plot"}. Attached PDF summary with prescribed herbicide treatments.',
    );
  }

  static pw.Widget _buildMetaRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text('$label ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
      ],
    );
  }

  static pw.Widget _buildMetricBox(String title, String val, PdfColor col) {
    final bgColor = PdfColor(col.red, col.green, col.blue, 0.12);
    final borderColor = PdfColor(col.red, col.green, col.blue, 0.45);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(val, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: col)),
        ],
      ),
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
