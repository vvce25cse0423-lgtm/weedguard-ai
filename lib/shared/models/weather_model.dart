import 'package:flutter/foundation.dart';

@immutable
class WeatherModel {
  final double temperatureCelsius;
  final double humidity;
  final double rainProbability;
  final double windSpeedKmh;
  final String description;
  final String icon;
  final List<WeatherForecastDay> forecast;
  final DateTime fetchedAt;

  const WeatherModel({
    required this.temperatureCelsius,
    required this.humidity,
    required this.rainProbability,
    required this.windSpeedKmh,
    required this.description,
    required this.icon,
    required this.forecast,
    required this.fetchedAt,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final forecastList = (json['forecast'] as List<dynamic>? ?? [])
        .map((f) => WeatherForecastDay.fromJson(f as Map<String, dynamic>))
        .toList();
    return WeatherModel(
      temperatureCelsius: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      rainProbability: (json['rain_probability'] as num).toDouble(),
      windSpeedKmh: (json['wind_speed'] as num).toDouble(),
      description: json['description'] as String,
      icon: json['icon'] as String? ?? 'cloud',
      forecast: forecastList,
      fetchedAt: DateTime.now(),
    );
  }
}

@immutable
class WeatherForecastDay {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double rainProbability;
  final String description;

  const WeatherForecastDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.rainProbability,
    required this.description,
  });

  factory WeatherForecastDay.fromJson(Map<String, dynamic> json) => WeatherForecastDay(
        date: DateTime.parse(json['date'] as String),
        maxTemp: (json['max_temp'] as num).toDouble(),
        minTemp: (json['min_temp'] as num).toDouble(),
        rainProbability: (json['rain_probability'] as num).toDouble(),
        description: json['description'] as String,
      );
}
