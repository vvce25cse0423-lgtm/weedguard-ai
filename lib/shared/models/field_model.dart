import 'package:flutter/foundation.dart';

@immutable
class FieldModel {
  final String id;
  final String userId;
  final String name;
  final String cropType;
  final double? areHectares;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final DateTime? plantingDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FieldModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.cropType,
    this.areHectares,
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.plantingDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      cropType: json['crop_type'] as String,
      areHectares: (json['area_hectares'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationLabel: json['location_label'] as String?,
      plantingDate: json['planting_date'] != null
          ? DateTime.parse(json['planting_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'crop_type': cropType,
      'area_hectares': areHectares,
      'latitude': latitude,
      'longitude': longitude,
      'location_label': locationLabel,
      'planting_date': plantingDate?.toIso8601String().split('T').first,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FieldModel copyWith({
    String? name,
    String? cropType,
    double? areHectares,
    double? latitude,
    double? longitude,
    String? locationLabel,
    DateTime? plantingDate,
    String? notes,
  }) {
    return FieldModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      cropType: cropType ?? this.cropType,
      areHectares: areHectares ?? this.areHectares,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      plantingDate: plantingDate ?? this.plantingDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
