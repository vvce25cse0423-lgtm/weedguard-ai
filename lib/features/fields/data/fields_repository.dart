import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/field_model.dart';
import '../../../shared/models/scan_model.dart';
import '../../../core/errors/app_error.dart';

class FieldsRepository {
  final SupabaseClient _client;
  FieldsRepository(this._client);

  static const _localFieldsKey = 'weedguard_local_fields_v1';

  String get _uid {
    try {
      final user = _client.auth.currentUser;
      if (user != null && user.id.isNotEmpty) return user.id;
    } catch (_) {}
    return 'local_user';
  }

  Future<List<FieldModel>> getFields() async {
    final Map<String, FieldModel> fieldMap = {};

    // 1. Read local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_localFieldsKey);
      if (localJson != null && localJson.isNotEmpty) {
        final list = jsonDecode(localJson) as List<dynamic>;
        for (final item in list) {
          final f = FieldModel.fromJson(item as Map<String, dynamic>);
          fieldMap[f.id] = f;
        }
      }
    } catch (_) {}

    // 2. Fetch from Supabase
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final data = await _client
            .from('fields')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        if (data is List) {
          for (final j in data) {
            final f = FieldModel.fromJson(j as Map<String, dynamic>);
            fieldMap[f.id] = f;
          }
          final prefs = await SharedPreferences.getInstance();
          final allJson = fieldMap.values.map((f) => f.toJson()).toList();
          await prefs.setString(_localFieldsKey, jsonEncode(allJson));
        }
      }
    } catch (_) {}

    final sorted = fieldMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<FieldModel> getField(String fieldId) async {
    final all = await getFields();
    try {
      return all.firstWhere((f) => f.id == fieldId);
    } catch (_) {
      throw const NotFoundError('Field not found.');
    }
  }

  Future<FieldModel> createField({
    required String name,
    required String cropType,
    double? areaHectares,
    double? latitude,
    double? longitude,
    String? locationLabel,
    DateTime? plantingDate,
    String? notes,
  }) async {
    final fieldId = const Uuid().v4();
    final now = DateTime.now();

    final newField = FieldModel(
      id: fieldId,
      userId: _uid,
      name: name,
      cropType: cropType,
      areHectares: areaHectares,
      latitude: latitude,
      longitude: longitude,
      locationLabel: locationLabel,
      plantingDate: plantingDate,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_localFieldsKey);
      List<dynamic> list = [];
      if (localJson != null && localJson.isNotEmpty) {
        list = jsonDecode(localJson) as List<dynamic>;
      }
      list.insert(0, newField.toJson());
      await prefs.setString(_localFieldsKey, jsonEncode(list));
    } catch (_) {}

    // Best-effort Supabase insert
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('fields').insert({
          'id': fieldId,
          'user_id': user.id,
          'name': name,
          'crop_type': cropType,
          'area_hectares': areaHectares,
          'latitude': latitude,
          'longitude': longitude,
          'location_label': locationLabel,
          'planting_date': plantingDate?.toIso8601String().split('T').first,
          'notes': notes,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      }
    } catch (_) {}

    return newField;
  }

  Future<FieldModel> updateField(FieldModel field) async {
    final updated = field.copyWith();
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_localFieldsKey);
      if (localJson != null && localJson.isNotEmpty) {
        final list = jsonDecode(localJson) as List<dynamic>;
        final idx = list.indexWhere((item) => (item as Map)['id'] == field.id);
        if (idx >= 0) {
          list[idx] = field.toJson();
          await prefs.setString(_localFieldsKey, jsonEncode(list));
        }
      }
    } catch (_) {}

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client
            .from('fields')
            .update({
              'name': field.name,
              'crop_type': field.cropType,
              'area_hectares': field.areHectares,
              'latitude': field.latitude,
              'longitude': field.longitude,
              'location_label': field.locationLabel,
              'planting_date': field.plantingDate?.toIso8601String().split('T').first,
              'notes': field.notes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', field.id)
            .eq('user_id', user.id);
      }
    } catch (_) {}

    return field;
  }

  Future<void> deleteField(String fieldId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_localFieldsKey);
      if (localJson != null && localJson.isNotEmpty) {
        final list = jsonDecode(localJson) as List<dynamic>;
        list.removeWhere((item) => (item as Map)['id'] == fieldId);
        await prefs.setString(_localFieldsKey, jsonEncode(list));
      }
    } catch (_) {}

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('fields').delete().eq('id', fieldId).eq('user_id', user.id);
      }
    } catch (_) {}
  }

  Future<FieldModel> getOrCreateFieldForCrop(String cropName) async {
    final cleanCrop = cropName.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    final effectiveCrop = cleanCrop.isNotEmpty ? cleanCrop : 'Crop';
    final cropLower = effectiveCrop.toLowerCase();

    final existingFields = await getFields();
    // Check if a field already exists for this crop
    for (final f in existingFields) {
      final fCrop = f.cropType.toLowerCase().trim();
      final fName = f.name.toLowerCase().trim();
      if (fCrop == cropLower ||
          fCrop.contains(cropLower) ||
          cropLower.contains(fCrop) ||
          fName.contains(cropLower)) {
        return f; // Reuse existing field!
      }
    }

    // No field exists yet for this crop, create one
    final fieldName = effectiveCrop.toLowerCase().contains('field')
        ? effectiveCrop
        : '$effectiveCrop Field';

    return await createField(
      name: fieldName,
      cropType: effectiveCrop,
      areaHectares: 1.5,
      locationLabel: 'Scanned Farmland',
    );
  }

  Future<List<ScanModel>> getScansForField(String fieldId) async {
    final List<ScanModel> result = [];
    final Set<String> seenIds = {};

    FieldModel? currentField;
    try {
      final fields = await getFields();
      for (final f in fields) {
        if (f.id == fieldId) {
          currentField = f;
          break;
        }
      }
    } catch (_) {}

    // 1. Read from local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('weedguard_local_scans_v1');
      if (localJson != null && localJson.isNotEmpty) {
        final list = jsonDecode(localJson) as List<dynamic>;
        for (final item in list) {
          final s = ScanModel.fromJson(item as Map<String, dynamic>);
          final matchesFieldId = s.fieldId != null && s.fieldId == fieldId;
          final matchesCrop = currentField != null &&
              s.cropName != null &&
              s.cropName!.isNotEmpty &&
              (s.cropName!.toLowerCase().contains(currentField.cropType.toLowerCase()) ||
               currentField.cropType.toLowerCase().contains(s.cropName!.toLowerCase()) ||
               currentField.name.toLowerCase().contains(s.cropName!.toLowerCase()));

          if ((matchesFieldId || ((s.fieldId == null || s.fieldId!.isEmpty) && matchesCrop)) &&
              seenIds.add(s.id)) {
            result.add(s);
          }
        }
      }
    } catch (_) {}

    // 2. Fetch from Supabase
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final data = await _client
            .from('scans')
            .select()
            .eq('user_id', user.id)
            .eq('field_id', fieldId)
            .order('created_at', ascending: false);
        if (data is List) {
          for (final j in data) {
            final s = ScanModel.fromJson(j as Map<String, dynamic>);
            if (seenIds.add(s.id)) {
              result.add(s);
            }
          }
        }
      }
    } catch (_) {}

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}
