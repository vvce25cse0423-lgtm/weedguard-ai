import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/field_model.dart';
import '../../../shared/models/scan_model.dart';
import '../../../core/errors/app_error.dart';

class FieldsRepository {
  final SupabaseClient _client;
  FieldsRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  Future<List<FieldModel>> getFields() async {
    try {
      final data = await _client
          .from('fields')
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: false);
      return (data as List).map((j) => FieldModel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      throw const NetworkError();
    }
  }

  Future<FieldModel> getField(String fieldId) async {
    try {
      final data = await _client.from('fields').select().eq('id', fieldId).eq('user_id', _uid).single();
      return FieldModel.fromJson(data);
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
    try {
      final now = DateTime.now().toIso8601String();
      final data = await _client.from('fields').insert({
        'user_id': _uid,
        'name': name,
        'crop_type': cropType,
        'area_hectares': areaHectares,
        'latitude': latitude,
        'longitude': longitude,
        'location_label': locationLabel,
        'planting_date': plantingDate?.toIso8601String().split('T').first,
        'notes': notes,
        'created_at': now,
        'updated_at': now,
      }).select().single();
      return FieldModel.fromJson(data);
    } catch (_) {
      throw const UnknownError('Could not create field. Please try again.');
    }
  }

  Future<FieldModel> updateField(FieldModel field) async {
    try {
      final data = await _client
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
          .eq('user_id', _uid)
          .select()
          .single();
      return FieldModel.fromJson(data);
    } catch (_) {
      throw const UnknownError('Could not update field. Please try again.');
    }
  }

  Future<void> deleteField(String fieldId) async {
    try {
      await _client.from('fields').delete().eq('id', fieldId).eq('user_id', _uid);
    } catch (_) {
      throw const UnknownError('Could not delete field. Please try again.');
    }
  }

  Future<List<ScanModel>> getScansForField(String fieldId) async {
    try {
      final data = await _client
          .from('scans')
          .select('*, field_zones(*)')
          .eq('field_id', fieldId)
          .eq('user_id', _uid)
          .order('created_at', ascending: false);
      return (data as List).map((j) => ScanModel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      throw const NetworkError();
    }
  }
}
