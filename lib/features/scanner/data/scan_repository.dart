import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/detection_result_model.dart';
import '../../../shared/models/scan_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../fields/data/fields_repository.dart';

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
  }) async {
    final scanId = const Uuid().v4();
    final now = DateTime.now();
    final uid = _uid;

    String effectiveFieldId = fieldId ?? '';
    try {
      final fieldsRepo = FieldsRepository(_client);
      final existingFields = await fieldsRepo.getFields();
      if (effectiveFieldId.isEmpty) {
        if (existingFields.isNotEmpty) {
          effectiveFieldId = existingFields.first.id;
        } else {
          final detectedCrop = result.detections.isNotEmpty ? result.detections.first.label : 'Crop';
          final newField = await fieldsRepo.createField(
            name: '$detectedCrop Field',
            cropType: detectedCrop,
            areaHectares: 1.5,
          );
          effectiveFieldId = newField.id;
        }
      }
    } catch (_) {}

    final effectiveImageUrl = imageUrl ?? result.imageUrl ?? result.imagePath;

    final newScan = ScanModel(
      id: scanId,
      fieldId: effectiveFieldId,
      userId: uid,
      imageUrl: effectiveImageUrl,
      weedCount: result.weedCount,
      averageConfidence: result.averageConfidence,
      severity: result.severity,
      priorityZone: result.priorityZone,
      infestationScore: result.infestationScore,
      isMockDetection: result.isMockDetection,
      zones: result.zones,
      createdAt: now,
    );

    // 1. ALWAYS persist locally first
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_localScansKey);
      List<dynamic> list = [];
      if (localJson != null && localJson.isNotEmpty) {
        list = jsonDecode(localJson) as List<dynamic>;
      }
      list.insert(0, newScan.toJson());
      await prefs.setString(_localScansKey, jsonEncode(list));
    } catch (_) {}

    // 2. Best-effort Supabase sync
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('scans').insert({
          'id': scanId,
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
            'scan_id': scanId,
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
          final s = ScanModel.fromJson(item as Map<String, dynamic>);
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

        if (data is List) {
          for (final j in data) {
            final s = ScanModel.fromJson(j as Map<String, dynamic>);
            scanMap[s.id] = s;
          }
          final prefs = await SharedPreferences.getInstance();
          final allJson = scanMap.values.map((s) => s.toJson()).toList();
          await prefs.setString(_localScansKey, jsonEncode(allJson));
        }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_localScansKey);
      if (localJson != null && localJson.isNotEmpty) {
        final list = jsonDecode(localJson) as List<dynamic>;
        list.removeWhere((item) => (item as Map)['id'] == scanId);
        await prefs.setString(_localScansKey, jsonEncode(list));
      }
    } catch (_) {}

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('scans').delete().eq('id', scanId).eq('user_id', user.id);
      }
    } catch (_) {}
  }
}
