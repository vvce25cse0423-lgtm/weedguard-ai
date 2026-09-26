import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/detection_result_model.dart';
import '../../../shared/models/scan_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error.dart';

class ScanRepository {
  final SupabaseClient _client;
  ScanRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  Future<String?> uploadScanImage(File imageFile, String fieldId) async {
    try {
      final ext = imageFile.path.split('.').last;
      final path = '$_uid/$fieldId/${const Uuid().v4()}.$ext';
      await _client.storage.from(AppConstants.scanImagesBucket).upload(path, imageFile);
      return _client.storage.from(AppConstants.scanImagesBucket).getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<ScanModel> saveScan({
    required String fieldId,
    required WeedDetectionResult result,
    String? imageUrl,
  }) async {
    try {
      final scanId = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      final scanData = await _client.from('scans').insert({
        'id': scanId,
        'field_id': fieldId,
        'user_id': _uid,
        'image_url': imageUrl,
        'weed_count': result.weedCount,
        'average_confidence': result.averageConfidence,
        'severity': result.severity.dbValue,
        'priority_zone': result.priorityZone,
        'infestation_score': result.infestationScore,
        'is_mock_detection': result.isMockDetection,
        'created_at': now,
      }).select().single();

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

      return ScanModel.fromJson({...scanData, 'field_zones': []});
    } catch (_) {
      throw const StorageError('Could not save scan data. Please try again.');
    }
  }

  Future<List<ScanModel>> getAllScans() async {
    try {
      final data = await _client
          .from('scans')
          .select('*, field_zones(*), fields(name)')
          .eq('user_id', _uid)
          .order('created_at', ascending: false);
      return (data as List).map((j) => ScanModel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      throw const NetworkError();
    }
  }

  Future<ScanModel?> getScan(String scanId) async {
    try {
      final data = await _client
          .from('scans')
          .select('*, field_zones(*)')
          .eq('id', scanId)
          .eq('user_id', _uid)
          .single();
      return ScanModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
