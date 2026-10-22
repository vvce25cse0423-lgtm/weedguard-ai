import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/detection_result_model.dart';
import '../../../shared/models/scan_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../fields/data/fields_repository.dart';
import '../../../shared/widgets/scan_thumbnail_image.dart';

class ScanRepository {
  final SupabaseClient _client;
  ScanRepository(this._client);

  static const _localScansKey = 'weedguard_local_scans_v1';

  String get _uid {
    try {
      final user = _client.auth.currentUser;
      if (user != null && user.id.isNotEmpty) return user.id;
    } catch (_) {}
    return 'local_user';
  }

  Future<String?> uploadScanImage(File imageFile, String fieldId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final ext = imageFile.path.split('.').last;
      final path = '${user.id}/$fieldId/${const Uuid().v4()}.$ext';
      await _client.storage.from(AppConstants.scanImagesBucket).upload(path, imageFile);
      return _client.storage.from(AppConstants.scanImagesBucket).getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<ScanModel> saveScan({
    required String? fieldId,
    required WeedDetectionResult result,
    String? imageUrl,
    String? scanId,
  }) async {
    final effectiveScanId = (scanId != null && scanId.isNotEmpty) ? scanId : const Uuid().v4();
    final now = DateTime.now();
    final uid = _uid;

    final detectedCrop = result.detections.where((d) => d.isCrop).isNotEmpty
        ? result.detections.firstWhere((d) => d.isCrop).label
        : (result.detections.isNotEmpty ? result.detections.first.label : 'Crop Field');
    final detectedWeeds = result.detections.where((d) => !d.isCrop).map((d) => d.label).toSet().toList();

    String effectiveFieldId = fieldId ?? '';
    try {
      final fieldsRepo = FieldsRepository(_client);
      if (effectiveFieldId.isNotEmpty) {
        final existingFields = await fieldsRepo.getFields();
        if (!existingFields.any((f) => f.id == effectiveFieldId)) {
          effectiveFieldId = '';
        }
      }
      if (effectiveFieldId.isEmpty) {
        final field = await fieldsRepo.getOrCreateFieldForCrop(detectedCrop);
        effectiveFieldId = field.id;
      }
    } catch (_) {}

    var effectiveImageUrl = imageUrl ?? result.imageUrl ?? result.imagePath;
    if (effectiveImageUrl == null || effectiveImageUrl.isEmpty) {
      try {
        final diskFile = await resolveScanFile(null, now);
        if (diskFile != null) effectiveImageUrl = diskFile.path;
      } catch (_) {}
    }

    // Ensure image is permanently preserved in local scans directory
    if (effectiveImageUrl != null &&
        effectiveImageUrl.isNotEmpty &&
        !effectiveImageUrl.startsWith('http')) {
      try {
        final clean = normalizeLocalPath(effectiveImageUrl) ?? effectiveImageUrl;
        final src = File(clean);
        if (src.existsSync()) {
          final appDir = await getApplicationDocumentsDirectory();
          final scansDir = Directory('${appDir.path}/scans');
          if (!scansDir.existsSync()) scansDir.createSync(recursive: true);
          final ext = clean.contains('.') ? clean.split('.').last : 'jpg';
          final dest = File('${scansDir.path}/scan_${now.millisecondsSinceEpoch}.$ext');
          if (src.path != dest.path) {
            await dest.writeAsBytes(await src.readAsBytes());
            effectiveImageUrl = dest.path;
          } else {
            effectiveImageUrl = src.path;
          }
        }
      } catch (_) {}
    }

    // Compute sequential Zone A, Zone B, Zone C... for this field
    String effectiveZone = result.priorityZone ?? 'Zone A';
    List<FieldZoneAnalysis> effectiveZones = result.zones;

    try {
      final fieldsRepo = FieldsRepository(_client);
      final fieldScans = await fieldsRepo.getScansForField(effectiveFieldId);
      final existingIdx = fieldScans.indexWhere((s) => s.id == effectiveScanId);
      final int zoneIndex = (existingIdx >= 0) ? existingIdx : fieldScans.length;
      final zoneLetter = String.fromCharCode(65 + (zoneIndex % 26));
      effectiveZone = 'Zone $zoneLetter';
      effectiveZones = [
        FieldZoneAnalysis(
          zoneId: zoneLetter.toLowerCase(),
          zoneLabel: effectiveZone,
          severity: result.severity,
          weedCount: result.weedCount,
          coveragePercent: (result.infestationScore * 100).clamp(5, 100).toDouble(),
        ),
      ];
    } catch (_) {}

    final newScan = ScanModel(
      id: effectiveScanId,
      fieldId: effectiveFieldId,
      userId: uid,
      imageUrl: effectiveImageUrl,
      weedCount: result.weedCount,
      averageConfidence: result.averageConfidence,
      severity: result.severity,
      cropName: detectedCrop,
      weedNames: detectedWeeds,
      priorityZone: effectiveZone,
      infestationScore: result.infestationScore,
      isMockDetection: result.isMockDetection,
      zones: effectiveZones,
      createdAt: now,
    );

    // 1. ALWAYS persist locally first with deduplication
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_localScansKey);
      List<dynamic> list = [];
      if (localJson != null && localJson.isNotEmpty) {
        list = jsonDecode(localJson) as List<dynamic>;
      }
      // If scan already exists by id, remove old version
      list.removeWhere((item) => (item as Map)['id'] == effectiveScanId);
      list.insert(0, newScan.toJson());
      await prefs.setString(_localScansKey, jsonEncode(list));
    } catch (_) {}

    // 2. Best-effort Supabase sync
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('scans').upsert({
          'id': effectiveScanId,
          if (effectiveFieldId.isNotEmpty) 'field_id': effectiveFieldId,
          'user_id': user.id,
          'image_url': effectiveImageUrl,
          'weed_count': result.weedCount,
          'average_confidence': result.averageConfidence,
          'severity': result.severity.dbValue,
          'priority_zone': result.priorityZone,
          'infestation_score': result.infestationScore,
          'is_mock_detection': result.isMockDetection,
          'created_at': now.toIso8601String(),
        });

        if (result.zones.isNotEmpty) {
          final zonesData = result.zones.map((z) => {
            'scan_id': effectiveScanId,
            'zone_id': z.zoneId,
            'zone_label': z.zoneLabel,
            'severity': z.severity.dbValue,
            'weed_count': z.weedCount,
            'coverage_percent': z.coveragePercent,
          }).toList();
          await _client.from('field_zones').insert(zonesData);
        }
      }
    } catch (_) {}

    return newScan;
  }

  Future<List<ScanModel>> getAllScans() async {
    final Map<String, ScanModel> scanMap = {};

    // 1. Load all local scans from SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_localScansKey);
      if (localJson != null && localJson.isNotEmpty) {
        final list = jsonDecode(localJson) as List<dynamic>;
        for (final item in list) {
          var s = ScanModel.fromJson(item as Map<String, dynamic>);
          // If image path is missing or points to stale path, attempt to heal from disk
          final cleanLocal = normalizeLocalPath(s.imageUrl);
          final bool hasValidFile = cleanLocal != null && File(cleanLocal).existsSync();
          if (!hasValidFile) {
            try {
              final healed = await resolveScanFile(s.imageUrl, s.createdAt);
              if (healed != null && healed.existsSync()) {
                s = s.copyWith(imageUrl: healed.path);
              }
            } catch (_) {}
          }
          scanMap[s.id] = s;
        }
      }
    } catch (_) {}

    // 2. Try fetching from Supabase if online and authenticated
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final data = await _client
            .from('scans')
            .select('*, field_zones(*)')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        for (final j in data) {
          var s = ScanModel.fromJson(j);
          final existing = scanMap[s.id];
          if (existing != null) {
            // Never destroy a valid on-device image path with a null or broken remote URL
            final cleanEx = normalizeLocalPath(existing.imageUrl);
            final bool existingValid = cleanEx != null && File(cleanEx).existsSync();

            final String? mergedImage = existingValid
                ? existing.imageUrl
                : ((s.imageUrl != null && s.imageUrl!.isNotEmpty) ? s.imageUrl : existing.imageUrl);

            scanMap[s.id] = s.copyWith(
              imageUrl: mergedImage,
              cropName: s.cropName ?? existing.cropName,
            );
          } else {
            final cleanRemote = normalizeLocalPath(s.imageUrl);
            final bool remoteValid = cleanRemote != null && File(cleanRemote).existsSync();
            if (!remoteValid) {
              try {
                final healed = await resolveScanFile(s.imageUrl, s.createdAt);
                if (healed != null && healed.existsSync()) {
                  s = s.copyWith(imageUrl: healed.path);
                }
              } catch (_) {}
            }
            scanMap[s.id] = s;
          }
        }
        final prefs = await SharedPreferences.getInstance();
        final allJson = scanMap.values.map((s) => s.toJson()).toList();
        await prefs.setString(_localScansKey, jsonEncode(allJson));
      }
    } catch (_) {}

    final sortedScans = scanMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sortedScans;
  }

  Future<ScanModel?> getScan(String scanId) async {
    final all = await getAllScans();
    try {
      return all.firstWhere((s) => s.id == scanId);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteScan(String scanId) async {
    String? targetFieldId;
    String? targetCropName;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_localScansKey);
      if (localJson != null && localJson.isNotEmpty) {
        final list = jsonDecode(localJson) as List<dynamic>;
        final matchIdx = list.indexWhere((item) => (item as Map)['id'] == scanId);
        if (matchIdx >= 0) {
          final scanItem = list[matchIdx] as Map<String, dynamic>;
          targetFieldId = scanItem['field_id'] as String?;
          targetCropName = scanItem['crop_name'] as String?;
          list.removeAt(matchIdx);
          await prefs.setString(_localScansKey, jsonEncode(list));
        }
      }
    } catch (_) {}

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        if (targetFieldId == null || targetFieldId.isEmpty) {
          try {
            final scanRow = await _client.from('scans').select('field_id, crop_name').eq('id', scanId).maybeSingle();
            if (scanRow != null) {
              targetFieldId = scanRow['field_id'] as String?;
              targetCropName = scanRow['crop_name'] as String?;
            }
          } catch (_) {}
        }
        await _client.from('scans').delete().eq('id', scanId).eq('user_id', user.id);
      }
    } catch (_) {}

    // If this scan was linked to a field (or crop), check if any remaining scans exist for it.
    // If no scans remain for this field/crop, automatically remove the field from My Fields!
    try {
      final remainingScans = await getAllScans();
      final fieldsRepo = FieldsRepository(_client);
      final fields = await fieldsRepo.getFields();

      for (final f in fields) {
        final bool isSameField = (targetFieldId != null && targetFieldId.isNotEmpty && f.id == targetFieldId);
        final bool isSameCrop = (targetCropName != null &&
            targetCropName.isNotEmpty &&
            (f.cropType.toLowerCase() == targetCropName.toLowerCase() ||
             f.name.toLowerCase().contains(targetCropName.toLowerCase()) ||
             targetCropName.toLowerCase().contains(f.cropType.toLowerCase())));

        if (isSameField || isSameCrop) {
          // Check if any remaining scans reference this field or crop
          final hasOtherScans = remainingScans.any((s) =>
              s.id != scanId &&
              (s.fieldId == f.id ||
               (s.cropName != null &&
                (s.cropName!.toLowerCase() == f.cropType.toLowerCase() ||
                 f.name.toLowerCase().contains(s.cropName!.toLowerCase()) ||
                 s.cropName!.toLowerCase().contains(f.cropType.toLowerCase())))));

          if (!hasOtherScans) {
            await fieldsRepo.deleteField(f.id);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> clearAllScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localScansKey);
    } catch (_) {}

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('scans').delete().eq('user_id', user.id);
      }
    } catch (_) {}
  }
}
