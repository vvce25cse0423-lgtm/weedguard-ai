import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:weedguard/shared/models/detection_result_model.dart';
import 'package:weedguard/shared/models/scan_model.dart';

enum TtsVoiceState { stopped, playing, paused }

class AgronomyVoiceAssistantService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _initialized = false;
  static ValueNotifier<TtsVoiceState> voiceStateNotifier =
      ValueNotifier<TtsVoiceState>(TtsVoiceState.stopped);

  static Future<void> _initTts() async {
    if (_initialized) return;
    try {
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        voiceStateNotifier.value = TtsVoiceState.playing;
      });

      _flutterTts.setCompletionHandler(() {
        voiceStateNotifier.value = TtsVoiceState.stopped;
      });

      _flutterTts.setCancelHandler(() {
        voiceStateNotifier.value = TtsVoiceState.stopped;
      });

      _flutterTts.setErrorHandler((_) {
        voiceStateNotifier.value = TtsVoiceState.stopped;
      });

      _initialized = true;
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
      voiceStateNotifier.value = TtsVoiceState.stopped;
    } catch (_) {}
  }

  static Future<void> speakAnalysisReport({
    required WeedDetectionResult result,
    required String languageCode, // 'kn', 'hi', or 'en'
    String? cropType,
    String? fieldName,
  }) async {
    await _initTts();

    // If currently speaking, stop
    if (voiceStateNotifier.value == TtsVoiceState.playing) {
      await stop();
      return;
    }

    try {
      String speechLanguage = 'en-IN';
      if (languageCode == 'kn') {
        speechLanguage = 'kn-IN';
      } else if (languageCode == 'hi') {
        speechLanguage = 'hi-IN';
      }

      await _flutterTts.setLanguage(speechLanguage);

      final speechText = _buildSpeechScript(
        result: result,
        languageCode: languageCode,
        cropType: cropType,
        fieldName: fieldName,
      );

      voiceStateNotifier.value = TtsVoiceState.playing;
      await _flutterTts.speak(speechText);
    } catch (_) {
      voiceStateNotifier.value = TtsVoiceState.stopped;
    }
  }

  static String _buildSpeechScript({
    required WeedDetectionResult result,
    required String languageCode,
    String? cropType,
    String? fieldName,
  }) {
    final count = result.weedCount;
    final severity = result.severity.name;
    final weeds = result.detectedWeeds.map((w) => w.commonName).toSet().toList();
    final weedListStr = weeds.isNotEmpty ? weeds.join(', ') : 'None';
    final herbicides = result.recommendations.map((r) => '${r.herbicideName} (${r.dosage})').toList();
    final herbicideStr = herbicides.isNotEmpty ? herbicides.join(', ') : '';

    if (languageCode == 'kn') {
      // Kannada Voice Script
      final buffer = StringBuffer();
      buffer.write('ವೀಡ್‌ಗಾರ್ಡ್ AI ಕೃಷಿ ವಿಶ್ಲೇಷಣೆ ವರದಿ. ');
      if (fieldName != null && fieldName.isNotEmpty) {
        buffer.write('ಹೊಲ: $fieldName. ');
      }
      if (cropType != null && cropType.isNotEmpty) {
        buffer.write('ಬೆಳೆ: $cropType. ');
      }

      if (count == 0) {
        buffer.write('ಅಭಿನಂದನೆಗಳು! ನಿಮ್ಮ ಹೊಲದಲ್ಲಿ ಯಾವುದೇ ಕಳೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ. ಬೆಳೆ ಆರೋಗ್ಯಕರವಾಗಿದೆ.');
      } else {
        String knSeverity = 'ಕಡಿಮೆ';
        if (severity == 'high') knSeverity = 'ಹೆಚ್ಚು';
        if (severity == 'medium' || severity == 'moderate') knSeverity = 'ಮಧ್ಯಮ';

        buffer.write('ಒಟ್ಟು $count ಕಳೆಗಳನ್ನು ಪತ್ತೆ ಮಾಡಲಾಗಿದೆ. ');
        buffer.write('ಕಳೆ ಹಾವಳಿಯ ತೀವ್ರತೆ $knSeverity ಆಗಿದೆ. ');
        buffer.write('ಗುರುತಿಸಲಾದ ಕಳೆಗಳು: $weedListStr. ');

        if (herbicideStr.isNotEmpty) {
          buffer.write('ಶಿಫಾರಸು ಮಾಡಿದ ಸಸ್ಯನಾಶಕ ಔಷಧ ಮತ್ತು ಪ್ರಮಾಣ: $herbicideStr. ');
        }
        buffer.write('ಮುನ್ನೆಚ್ಚರಿಕೆ: ಔಷಧ ಸಿಂಪಡಿಸುವಾಗ ರಕ್ಷಣಾ ಕವಚ ಧರಿಸಿ ಮತ್ತು ಶಾಂತ ಹವಾಮಾನದಲ್ಲಿ ಸಿಂಪಡಿಸಿ.');
      }
      return buffer.toString();
    } else if (languageCode == 'hi') {
      // Hindi Voice Script
      final buffer = StringBuffer();
      buffer.write('वीडगार्ड AI कृषि विश्लेषण रिपोर्ट। ');
      if (fieldName != null && fieldName.isNotEmpty) {
        buffer.write('खेत: $fieldName. ');
      }
      if (cropType != null && cropType.isNotEmpty) {
        buffer.write('फसल: $cropType. ');
      }

      if (count == 0) {
        buffer.write('बधाई हो! आपके खेत में कोई खरपतवार नहीं पाई गई। फसल पूरी तरह स्वस्थ है।');
      } else {
        String hiSeverity = 'कम';
        if (severity == 'high') hiSeverity = 'गंभीर';
        if (severity == 'medium' || severity == 'moderate') hiSeverity = 'मध्यम';

        buffer.write('कुल $count खरपतवार पाए गए हैं। ');
        buffer.write('संक्रमण की गंभीरता $hiSeverity है। ');
        buffer.write('पहचाने गए खरपतवार: $weedListStr. ');

        if (herbicideStr.isNotEmpty) {
          buffer.write('अनुशंसित खरपतवारनाशक दवा और खुराक: $herbicideStr. ');
        }
        buffer.write('सावधानी: छिड़काव करते समय सुरक्षात्मक उपकरण पहनें और शांत मौसम में छिड़काव करें।');
      }
      return buffer.toString();
    } else {
      // English Voice Script
      final buffer = StringBuffer();
      buffer.write('WeedGuard AI Field Analysis Report. ');
      if (fieldName != null && fieldName.isNotEmpty) {
        buffer.write('Field: $fieldName. ');
      }
      if (cropType != null && cropType.isNotEmpty) {
        buffer.write('Crop: $cropType. ');
      }

      if (count == 0) {
        buffer.write('Great news! No weed infestation detected. Your crop is healthy and clear.');
      } else {
        buffer.write('$count weeds detected. ');
        buffer.write('Overall infestation severity is $severity. ');
        buffer.write('Identified weed varieties: $weedListStr. ');

        if (herbicideStr.isNotEmpty) {
          buffer.write('Recommended targeted herbicide and dosage: $herbicideStr. ');
        }
        buffer.write('Safety advisory: Always wear protective gear and spray during calm weather conditions.');
      }
      return buffer.toString();
    }
  }
}
