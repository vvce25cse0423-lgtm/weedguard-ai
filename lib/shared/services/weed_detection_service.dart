import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/detection_result_model.dart';
import '../models/scan_model.dart';
import '../../core/constants/app_constants.dart';

abstract class WeedDetectionService {
  Future<WeedDetectionResult> analyzeImage(File imageFile);
  bool get isMock;
}

// ─────────────────────────────────────────────────────────────────────────────
//  OpenRouter — production service (google/gemma-4-26b-a4b-it:free)
// ─────────────────────────────────────────────────────────────────────────────
class GeminiWeedDetectionService implements WeedDetectionService {
  static const _apiKey = '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';
  static const _url = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'google/gemma-4-26b-a4b-it:free';

  @override
  bool get isMock => false;

  static const _cropNames = [
    'Finger Millet (Ragi)', 'Sorghum (Jowar)', 'Rice (Paddy)', 'Maize (Corn)',
    'Pearl Millet (Bajra)', 'Wheat', 'Foxtail Millet (Navane)', 'Little Millet (Same)',
    'Kodo Millet (Arka)', 'Proso Millet (Baragu)', 'Pigeon Pea (Red Gram)',
    'Chickpea (Bengal Gram)', 'Black Gram (Udid)', 'Green Gram (Moong)',
    'Horse Gram (Huruli)', 'Cowpea (Alsandi)', 'Lablab Bean (Avare)',
    'Groundnut (Peanut)', 'Sunflower', 'Sesame (Ellu)', 'Sugarcane',
    'Cotton', 'Soybean', 'Tomato', 'Banana', 'Chilli', 'Castor',
    'Mustard', 'Niger (Huttellu)', 'Tobacco', 'Arecanut (Betel Nut)',
    'Coconut', 'Coffee Arabica', 'Coffee Robusta', 'Tea', 'Rubber',
    'Cardamom', 'Black Pepper', 'Mango', 'Pomegranate', 'Grapes',
    'Guava', 'Sapota (Chikoo)', 'Onion', 'Brinjal (Eggplant)',
    'Okra (Bhendi)', 'Jute', 'Turmeric', 'Ginger',
  ];

  static const _weedNames = [
    'Purple Nutsedge (Cyperus rotundus)', 'Yellow Nutsedge (Cyperus esculentus)',
    'Bermuda Grass (Cynodon dactylon)', 'Barnyard Grass (Echinochloa crus-galli)',
    'Jungle Rice (Echinochloa colona)', 'Crowfoot Grass (Dactyloctenium aegyptium)',
    'Goosegrass (Eleusine indica)', 'Crabgrass (Digitaria sanguinalis)',
    'Feather Fingergrass (Chloris barbata)', 'Brachiaria Grass (Brachiaria ramosa)',
    'Kans Grass (Saccharum spontaneum)', 'Cogongrass (Imperata cylindrica)',
    'Lovegrass (Eragrostis unioloides)', 'Globe Fimbristylis (Fimbristylis miliacea)',
    'Short-leaf Spike Rush (Cyperus brevifolius)', 'Johnsongrass (Sorghum halepense)',
    'Little Canary Grass (Phalaris minor)', 'Congress Grass (Parthenium hysterophorus)',
    'Benghal Dayflower (Commelina benghalensis)', 'Coat Buttons Tridax (Tridax procumbens)',
    'Horse Purslane (Trianthema portulacastrum)', 'Wild Amaranth (Amaranthus spinosus)',
    'Slender Amaranth (Amaranthus viridis)', 'Spurge Milkweed (Euphorbia hirta)',
    'Thyme-leaved Spurge (Euphorbia thymifolia)', 'False Daisy (Eclipta alba)',
    'Wild Mustard Cleome (Cleome viscosa)', 'Mexican Prickly Poppy (Argemone mexicana)',
    'Touch-Me-Not (Mimosa pudica)', 'Billygoat Weed (Ageratum conyzoides)',
    'Siam Weed (Chromolaena odorata)', "Devil's Horsewhip (Achyranthes aspera)",
    'Indian Acalypha (Acalypha indica)', 'Balloon Vine (Cardiospermum halicacabum)',
    'Black Nightshade (Solanum nigrum)', 'Turkey Berry (Solanum torvum)',
    'Field Bindweed (Convolvulus arvensis)', 'Wild Goat Weed (Stachytarpheta jamaicensis)',
    'Spreading Hogweed (Boerhavia diffusa)', 'Dwarf Copperleaf (Alternanthera sessilis)',
    'Khaki Weed (Alternanthera pungens)', 'Country Mallow (Abutilon indicum)',
    'Arrowleaf Sida (Sida rhombifolia)', 'Common Cocklebur (Xanthium strumarium)',
    'Wild Coffee (Cassia occidentalis)', 'Sickle Senna (Cassia tora)',
    "Lamb's Quarters (Chenopodium album)", 'Ban Tulsi (Croton bonplandianum)',
    'Witchweed (Striga asiatica)', 'Dodder (Cuscuta reflexa)',
    'Broomrape (Orobanche cernua)', 'Water Hyacinth (Eichhornia crassipes)',
    'Water Lettuce (Pistia stratiotes)',
  ];

  @override
  Future<WeedDetectionResult> analyzeImage(File imageFile) async {
    // ── 1. Resize + compress image to stay well within Groq payload limits ──
    final rawBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) throw const AnalysisException('Could not decode image file.');
    img.Image resized = decoded;
    const maxDim = 1024;
    if (decoded.width > maxDim || decoded.height > maxDim) {
      resized = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: maxDim)
          : img.copyResize(decoded, height: maxDim);
    }
    final compressedBytes = img.encodeJpg(resized, quality: 85);
    final base64Image = base64Encode(compressedBytes);

    // ── 2. Build prompt ──────────────────────────────────────────────────────
    final prompt =
        'You are an expert agricultural AI. Analyze this field image and identify the crop and any weeds present.\n\n'
        'Known crops (pick the best match): ${_cropNames.join(', ')}.\n'
        'Known weeds (identify any visible): ${_weedNames.join(', ')}.\n\n'
        'Confidence calibration:\n'
        '- 0.90-1.0: 3+ definitive features match\n'
        '- 0.75-0.89: 2 features match\n'
        '- 0.60-0.74: partial view\n'
        '- Below 0.60: very uncertain\n\n'
        'Respond ONLY with valid JSON (no markdown, no backticks):\n'
        '{\n'
        '  "crop_identified": "Full name or null",\n'
        '  "crop_confidence": 0.95,\n'
        '  "crop_growth_stage": "seedling|vegetative|reproductive|maturity",\n'
        '  "crop_key_features": "observed features",\n'
        '  "weeds": [\n'
        '    {\n'
        '      "name": "Weed name",\n'
        '      "count": 2,\n'
        '      "confidence": 0.85,\n'
        '      "severity": "low|moderate|high",\n'
        '      "distribution": "scattered|clustered|uniform",\n'
        '      "key_feature": "observed feature"\n'
        '    }\n'
        '  ],\n'
        '  "total_weed_count": 2,\n'
        '  "overall_severity": "low|moderate|high",\n'
        '  "infestation_score": 0.15,\n'
        '  "affected_area_percent": 15,\n'
        '  "recommended_action": "specific recommendation",\n'
        '  "summary": "One-line agronomic assessment"\n'
        '}\n\n'
        'Rules:\n'
        '1. confidence must be 0.0-1.0\n'
        '2. infestation_score: 0.0=no weeds, 1.0=fully infested\n'
        '3. severity: low <10%, moderate 10-30%, high >30%\n'
        '4. If not a crop image: crop_identified=null, weeds=[]\n'
        '5. NEVER list the main crop as a weed\n'
        '6. Count only clearly visible plants';

    // ── 3. Build request body (text first, then image — required by Qwen) ───
    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              }
            },
          ]
        }
      ],
      'max_tokens': 2048,
      'temperature': 0.1,
    });

    // ── 4. POST with 45-second timeout ───────────────────────────────────────
    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              'HTTP-Referer': 'https://weedguard.app',
              'X-Title': 'WeedGuard',
            },
            body: utf8.encode(body),
          )
          .timeout(const Duration(seconds: 45));

      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode != 200) {
        String groqError = '';
        try {
          final errJson = jsonDecode(responseBody) as Map<String, dynamic>;
          groqError = (errJson['error']?['message'] as String?) ?? '';
        } catch (_) {}
        throw AnalysisException(
            'AI error ${response.statusCode}${groqError.isNotEmpty ? ": $groqError" : ""}. Please try again.');
      }

      // ── 5. Parse response ────────────────────────────────────────────────
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

      String rawText;
      try {
        final choices = jsonResponse['choices'] as List<dynamic>;
        rawText = (choices[0]['message']['content'] as String).trim();
      } catch (_) {
        throw const AnalysisException('Unexpected response from AI. Please try again.');
      }

      // Strip markdown fences if model added them despite instructions
      rawText = rawText.replaceAll(RegExp(r'```json|```'), '').trim();
      final jsonStart = rawText.indexOf('{');
      final jsonEnd = rawText.lastIndexOf('}');
      if (jsonStart < 0 || jsonEnd <= jsonStart) {
        throw const AnalysisException('Could not parse AI response. Please try again.');
      }
      rawText = rawText.substring(jsonStart, jsonEnd + 1);

      late Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(rawText) as Map<String, dynamic>;
      } catch (_) {
        throw const AnalysisException('AI response was not valid JSON. Please try again.');
      }

      return _buildResult(imageFile.path, parsed);

    } on AnalysisException {
      rethrow;
    } on TimeoutException {
      throw const AnalysisException('Request timed out. Please check your connection and try again.');
    } on SocketException {
      throw const AnalysisException('No internet connection. Please check your network and try again.');
    } catch (e) {
      throw AnalysisException('Analysis failed: ${e.toString()}. Please try again.');
    }
  }

  WeedDetectionResult _buildResult(String imagePath, Map<String, dynamic> parsed) {
    final rawCropName = parsed['crop_identified'] as String?;
    final cropConf = (parsed['crop_confidence'] as num?)?.toDouble() ?? 0.0;

    final cropName = (rawCropName != null &&
            rawCropName.isNotEmpty &&
            rawCropName != 'null' &&
            rawCropName != 'Unknown' &&
            cropConf >= 0.40)
        ? rawCropName
        : null;

    final weedsJson = parsed['weeds'] as List<dynamic>? ?? [];
    final totalWeedCount = (parsed['total_weed_count'] as num?)?.toInt() ??
        weedsJson.fold<int>(0, (s, w) => s + ((w['count'] as num?)?.toInt() ?? 1));
    final severityStr = parsed['overall_severity'] as String? ?? 'low';
    final infestationScore = (parsed['infestation_score'] as num?)?.toDouble() ?? 0.0;

    final detections = <WeedDetection>[];

    if (cropName != null) {
      detections.add(WeedDetection(label: cropName, confidence: cropConf));
    }

    for (final w in weedsJson) {
      final wMap = w as Map<String, dynamic>;
      final count = (wMap['count'] as num?)?.toInt() ?? 1;
      final weedName = wMap['name'] as String? ?? 'Unknown weed';
      final conf = (wMap['confidence'] as num?)?.toDouble() ?? 0.75;

      if (conf < 0.40) continue;
      if (cropName != null &&
          weedName.toLowerCase().contains(
              cropName.split('(').first.trim().toLowerCase())) continue;

      for (int i = 0; i < count; i++) {
        detections.add(WeedDetection(label: weedName, confidence: conf));
      }
    }

    final severity = _parseSeverity(severityStr);
    final avgConf = detections.isEmpty
        ? 0.0
        : detections.map((d) => d.confidence).reduce((a, b) => a + b) /
            detections.length;

    final zones = _buildZones(weedsJson, totalWeedCount, infestationScore);
    final priorityZone = zones.isEmpty
        ? null
        : zones.reduce((a, b) => a.weedCount > b.weedCount ? a : b).zoneLabel;

    return WeedDetectionResult(
      imagePath: imagePath,
      detections: detections,
      weedCount: totalWeedCount,
      averageConfidence: avgConf,
      severity: severity,
      infestationScore: infestationScore,
      zones: zones,
      priorityZone: priorityZone,
      analyzedAt: DateTime.now(),
      isMockDetection: false,
    );
  }

  List<FieldZoneAnalysis> _buildZones(
      List<dynamic> weedsJson, int totalWeedCount, double infestationScore) {
    const zoneLabels = ['Zone A', 'Zone B', 'Zone C', 'Zone D'];
    final basePerZone = totalWeedCount ~/ 4;
    final remainder = totalWeedCount % 4;
    final perZone =
        List.generate(4, (i) => basePerZone + (i < remainder ? 1 : 0));
    final baseCoverage = infestationScore * 100;

    return List.generate(4, (i) {
      final count = perZone[i];
      final coverage = (baseCoverage *
              (count / (totalWeedCount == 0 ? 1 : totalWeedCount)))
          .clamp(0.0, 100.0);
      SeverityLevel sev;
      if (infestationScore <= AppConstants.severityLowMax)
        sev = SeverityLevel.low;
      else if (infestationScore <= AppConstants.severityModerateMax)
        sev = SeverityLevel.moderate;
      else
        sev = SeverityLevel.high;

      return FieldZoneAnalysis(
        zoneId: 'zone_${String.fromCharCode(97 + i)}',
        zoneLabel: zoneLabels[i],
        severity: sev,
        weedCount: count,
        coveragePercent: coverage,
      );
    });
  }

  SeverityLevel _parseSeverity(String s) {
    switch (s.toLowerCase()) {
      case 'high':
        return SeverityLevel.high;
      case 'moderate':
        return SeverityLevel.moderate;
      default:
        return SeverityLevel.low;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Demo-mode service
// ─────────────────────────────────────────────────────────────────────────────
class MockWeedDetectionService implements WeedDetectionService {
  @override
  bool get isMock => true;

  static const _demoScenarios = [
    _DemoScenario(
      crop: 'Sugarcane (Saccharum officinarum)',
      cropConf: 0.96,
      weeds: [
        _DemoWeed('Purple Nutsedge (Cyperus rotundus)', 3, 0.88),
        _DemoWeed('Barnyard Grass (Echinochloa crus-galli)', 2, 0.82),
      ],
      totalWeedCount: 5,
      severity: SeverityLevel.low,
      infestationScore: 0.08,
      summary: 'Sugarcane field with minor nutsedge and barnyard grass pressure',
    ),
    _DemoScenario(
      crop: 'Maize (Corn)',
      cropConf: 0.94,
      weeds: [
        _DemoWeed('Wild Amaranth (Amaranthus viridis)', 6, 0.85),
        _DemoWeed('Crabgrass (Digitaria sanguinalis)', 4, 0.79),
        _DemoWeed('Field Bindweed (Convolvulus arvensis)', 2, 0.76),
      ],
      totalWeedCount: 12,
      severity: SeverityLevel.moderate,
      infestationScore: 0.22,
      summary: 'Maize field with moderate broadleaf and grass weed infestation',
    ),
    _DemoScenario(
      crop: 'Rice (Paddy)',
      cropConf: 0.91,
      weeds: [
        _DemoWeed('Barnyard Grass (Echinochloa crus-galli)', 8, 0.90),
        _DemoWeed('Purple Nutsedge (Cyperus rotundus)', 5, 0.78),
      ],
      totalWeedCount: 13,
      severity: SeverityLevel.moderate,
      infestationScore: 0.28,
      summary: 'Rice paddy with significant barnyard grass and sedge competition',
    ),
  ];

  static int _scenarioIndex = 0;

  @override
  Future<WeedDetectionResult> analyzeImage(File imageFile) async {
    await Future.delayed(const Duration(milliseconds: 1800));

    final scenario = _demoScenarios[_scenarioIndex % _demoScenarios.length];
    _scenarioIndex++;

    final detections = <WeedDetection>[
      WeedDetection(label: scenario.crop, confidence: scenario.cropConf),
      ...scenario.weeds
          .map((w) => WeedDetection(label: w.name, confidence: w.confidence)),
    ];

    final avgConf = detections
            .map((d) => d.confidence)
            .reduce((a, b) => a + b) /
        detections.length;

    final basePerZone = scenario.totalWeedCount ~/ 4;
    final remainder = scenario.totalWeedCount % 4;
    final perZone =
        List.generate(4, (i) => basePerZone + (i < remainder ? 1 : 0));
    const zoneLabels = ['Zone A', 'Zone B', 'Zone C', 'Zone D'];

    final zones = List.generate(4, (i) {
      final count = perZone[i];
      final coverage =
          (scenario.infestationScore * 100 * count / scenario.totalWeedCount)
              .clamp(0.0, 100.0);
      return FieldZoneAnalysis(
        zoneId: 'zone_${String.fromCharCode(97 + i)}',
        zoneLabel: zoneLabels[i],
        severity: scenario.severity,
        weedCount: count,
        coveragePercent: coverage,
      );
    });

    final priorityZone =
        zones.reduce((a, b) => a.weedCount >= b.weedCount ? a : b).zoneLabel;

    return WeedDetectionResult(
      imagePath: imageFile.path,
      detections: detections,
      weedCount: scenario.totalWeedCount,
      averageConfidence: avgConf,
      severity: scenario.severity,
      infestationScore: scenario.infestationScore,
      zones: zones,
      priorityZone: priorityZone,
      analyzedAt: DateTime.now(),
      isMockDetection: true,
    );
  }
}

class _DemoScenario {
  final String crop;
  final double cropConf;
  final List<_DemoWeed> weeds;
  final int totalWeedCount;
  final SeverityLevel severity;
  final double infestationScore;
  final String summary;
  const _DemoScenario({
    required this.crop,
    required this.cropConf,
    required this.weeds,
    required this.totalWeedCount,
    required this.severity,
    required this.infestationScore,
    required this.summary,
  });
}

class _DemoWeed {
  final String name;
  final int count;
  final double confidence;
  const _DemoWeed(this.name, this.count, this.confidence);
}
