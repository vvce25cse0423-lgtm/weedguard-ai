import 'package:flutter/material.dart';

enum SpraySuitability { optimal, caution, dangerous }

class SprayWindowAnalysis {
  final int sprayScore; // 0 to 100
  final SpraySuitability suitability;
  final String statusTitle;
  final String description;
  final double windSpeedKmh;
  final double temperatureC;
  final int humidityPercent;
  final int rainProbability;
  final String recommendedTimeWindow;
  final List<String> advisories;

  const SprayWindowAnalysis({
    required this.sprayScore,
    required this.suitability,
    required this.statusTitle,
    required this.description,
    required this.windSpeedKmh,
    required this.temperatureC,
    required this.humidityPercent,
    required this.rainProbability,
    required this.recommendedTimeWindow,
    required this.advisories,
  });
}

class SprayWindowService {
  static SprayWindowAnalysis calculateSuitability({
    double windSpeed = 6.5, // km/h
    double temperature = 27.0, // °C
    int humidity = 58, // %
    int rainChance = 10, // %
  }) {
    // Scoring logic:
    // Ideal wind: 3 to 10 km/h (too low = inversion drift, too high = wind drift)
    // Ideal temp: 18 to 28 °C (high temp = rapid droplet evaporation)
    // Ideal humidity: 50% to 75%
    // Rain chance: < 20%
    int score = 100;
    final List<String> advisories = [];

    if (windSpeed > 14) {
      score -= 40;
      advisories.add('High wind speed (${windSpeed.toStringAsFixed(1)} km/h): Extreme chemical drift risk onto adjacent fields.');
    } else if (windSpeed < 2.5) {
      score -= 15;
      advisories.add('Stagnant air: Potential temperature inversion trap.');
    } else {
      advisories.add('Gentle breeze (${windSpeed.toStringAsFixed(1)} km/h): Optimal droplet target settling.');
    }

    if (temperature > 32) {
      score -= 30;
      advisories.add('High temperature (${temperature.toStringAsFixed(1)}°C): Risk of rapid volatilization & leaf scorching.');
    } else {
      advisories.add('Favorable temperature (${temperature.toStringAsFixed(1)}°C): Standard droplet retention.');
    }

    if (rainChance > 40) {
      score -= 45;
      advisories.add('High rain forecast ($rainChance%): Chemical wash-off risk within 3 hours.');
    } else {
      advisories.add('Low rain risk ($rainChance%): Chemical rainfastness ensured.');
    }

    score = score.clamp(0, 100);

    SpraySuitability suitability;
    String statusTitle;
    String description;

    if (score >= 75) {
      suitability = SpraySuitability.optimal;
      statusTitle = 'OPTIMAL SPRAY WINDOW';
      description = 'Weather conditions are ideal. Minimal chemical drift risk and high leaf absorption.';
    } else if (score >= 45) {
      suitability = SpraySuitability.caution;
      statusTitle = 'MODERATE SPRAY CONDITIONS';
      description = 'Spray with coarse flat-fan nozzles and maintain lower boom height.';
    } else {
      suitability = SpraySuitability.dangerous;
      statusTitle = 'DO NOT SPRAY';
      description = 'Adverse meteorological conditions. Delay application to prevent crop damage or runoff.';
    }

    return SprayWindowAnalysis(
      sprayScore: score,
      suitability: suitability,
      statusTitle: statusTitle,
      description: description,
      windSpeedKmh: windSpeed,
      temperatureC: temperature,
      humidityPercent: humidity,
      rainProbability: rainChance,
      recommendedTimeWindow: 'Today 4:00 PM – 6:30 PM (Golden Spray Hour)',
      advisories: advisories,
    );
  }
}
