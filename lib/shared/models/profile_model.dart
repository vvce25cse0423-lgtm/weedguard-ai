import 'package:flutter/foundation.dart';

@immutable
class ProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? locationLabel;
  final String preferredLanguage;
  final String? avatarUrl;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.locationLabel,
    this.preferredLanguage = 'en',
    this.avatarUrl,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        phone: json['phone'] as String?,
        locationLabel: json['location_label'] as String?,
        preferredLanguage: json['preferred_language'] as String? ?? 'en',
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'location_label': locationLabel,
        'preferred_language': preferredLanguage,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  String get displayName => fullName?.trim().isNotEmpty == true ? fullName! : email.split('@').first;
}
