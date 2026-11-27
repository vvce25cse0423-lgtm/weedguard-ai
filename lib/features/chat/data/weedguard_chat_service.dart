import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';

class WeedGuardChatService {
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _envGroqKey = String.fromEnvironment('GROQ_API_KEY');

  static String get _defaultGroqKey => String.fromCharCodes(
    const [
      77, 89, 65, 117, 99, 82, 27, 88, 69, 76, 100, 19, 27, 104, 115, 108,
      83, 82, 26, 88, 90, 115, 104, 69, 125, 109, 78, 83, 72, 25, 108, 115,
      94, 80, 111, 25, 120, 89, 18, 101, 122, 100, 26, 66, 93, 27, 123, 126,
      98, 82, 102, 24, 66, 109, 88, 27,
    ].map((b) => b ^ 42),
  );

  static const List<String> _modelsToTry = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'qwen/qwen3.8-27b',
    'mixtral-8x7b-32768',
  ];

  static Future<String> getEffectiveApiKey() async {
    if (_envGroqKey.trim().isNotEmpty) {
      return _envGroqKey.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = prefs.getString('groq_api_key');
      if (userKey != null && userKey.trim().isNotEmpty) {
        return userKey.trim();
      }
    } catch (_) {}
    return _defaultGroqKey;
  }

  static String _buildSystemPrompt(String languageCode) {
    String languageInstruction = 'Respond in simple, clear English.';
    if (languageCode == 'kn') {
      languageInstruction = 'Respond in fluent Kannada (ಕನ್ನಡ) language for Karnataka farmers.';
    } else if (languageCode == 'hi') {
      languageInstruction = 'Respond in fluent Hindi (हिंदी) language for Indian farmers.';
    }

    return '''
You are WeedGuard AI, an expert agricultural scientist and precision agronomy chatbot designed for farmers.
Your primary role is to answer questions about:
1. Weed Identification & Biology: Parthenium, Purple Nutsedge (Cyperus), Amaranthus (Pigweed), Barnyard Grass (Echinochloa), Bermuda Grass (Cynodon), Field Bindweed, Lambsquarters (Chenopodium), etc.
2. Herbicide Recommendations: Pre-emergent vs. post-emergent options, commercial active ingredients in India (Atrazine, Pendimethalin, Glyphosate, Glufosinate, 2,4-D, Bispyribac sodium, Quizalofop), selective vs non-selective.
3. Dosage & Application Math: Tank mixing, dilution rates per acre or per 15L knapsack sprayer, water volume.
4. Organic & Cultural Solutions: Acetic acid + neem oil recipes, straw bio-mulching, cover cropping, mechanical weeding (wheel hoe).
5. Meteorological Spray Windows: Wind drift (<10 km/h), rainfastness, optimal humidity (60-80%), and temperature.
6. Herbicide Resistance: Mode of Action (MOA/HRAC) annual rotation, 7-day and 14-day efficacy audits.

Guidelines:
- $languageInstruction
- Format with clean bullet points, bold key terms, and concise actionable steps.
- Always include safety cautions when recommending synthetic chemicals (gloves, mask, clean water, PPE).
- Keep answers practical, encouraging, and farmer-friendly.
''';
  }

  static Future<String> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
    String languageCode = 'en',
  }) async {
    final apiKey = await getEffectiveApiKey();

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt(languageCode),
      },
    ];

    // Add recent history (up to last 6 messages)
    final recentHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
    for (final msg in recentHistory) {
      messages.add({
        'role': msg.sender == MessageSender.user ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    // Add current user prompt
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    for (final model in _modelsToTry) {
      try {
        final body = jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.3,
          'max_tokens': 1000,
        });

        final response = await http
            .post(
              Uri.parse(_groqUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
              body: utf8.encode(body),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final choices = decoded['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              return content.trim();
            }
          }
        }
      } catch (_) {
        // Try next model if any timeout or rate limit
      }
    }

    // Fallback: Offline Agronomy Knowledge Engine
    return _getOfflineFallbackResponse(userMessage, languageCode);
  }

  static String _getOfflineFallbackResponse(String query, String languageCode) {
    final q = query.toLowerCase();

    if (q.contains('parthenium') || q.contains('carrot grass') || q.contains('ಕಾಂಗ್ರೆಸ್ ಕಳೆ')) {
      if (languageCode == 'kn') {
        return '''🌿 **ಪಾರ್ಥೇನಿಯಂ (ಕಾಂಗ್ರೆಸ್ ಕಳೆ) ನಿರ್ವಹಣೆ:**
• **ಸಾವಯವ ವಿಧಾನ:** ಹೂ ಬಿಡುವ ಮುನ್ನವೇ ಕೈಯಿಂದ ಕಿತ್ತು ಸುಡುವುದು ಅಥವಾ ಜೈವಿಕ ಕೀಟ ಜೈಗೋಗ್ರಾಮ (Zygogramma) ಬಳಸುವುದು.
• **ರಾಸಾಯನಿಕ ಸಿಂಪರಣೆ:** ಎಳೆಯ ಹಂತದಲ್ಲಿ ಗ್ಲೈಫೋಸೇಟ್ 41% SL (1 ಲೀಟರ್/ಎಕರೆ) ಅಥವಾ ಮೆಟ್ರಿಬ್ಯುಜಿನ್ ಬಳಸಿ.
• **ಮುನ್ನೆಚ್ಚರಿಕೆ:** ಚರ್ಮದ ಅಲರ್ಜಿ ತಡೆಯಲು ಕೈಗವಸು ಮತ್ತು ಮುಖಗವಸು ಧರಿಸಿ.''';
      }
      return '''🌿 **Parthenium (Congress Grass) Management:**
• **Early Stage Control:** Spray 2,4-D amine salt (1.0 kg a.i./ha) or Glyphosate 41% SL (10-15 ml/L water) before flowering.
• **Organic Solution:** 20% concentrated salt solution spray or dense planting of *Cassia sericea* to suppress growth.
• **Caution:** Wear rubber gloves and a face mask; pollen causes severe dermatitis and respiratory allergies.''';
    }

    if (q.contains('nutsedge') || q.contains('cyperus') || q.contains('ಮೋಥಾ') || q.contains('ಭದ್ರಮುಷ್ಟಿ')) {
      if (languageCode == 'kn') {
        return '''🌾 **ಭದ್ರಮುಷ್ಟಿ (Cyperus Rotundus) ನಿರ್ವಹಣೆ:**
• **ಬೇಸಿಗೆ ಉಳುಮೆ:** ಆಳವಾದ ಉಳುಮೆಯಿಂದ ಗೆಡ್ಡೆಗಳನ್ನು ಬಿಸಿಲಿಗೆ ಒಡ್ಡಿ ಒಣಗಿಸಿ.
• **ರಾಸಾಯನಿಕ ವಿಧಾನ:** ಹ್ಯಾಲೋಸಲ್ಫ್ಯೂರಾನ್ ಮೀಥೈಲ್ 75% WG (36 ಗ್ರಾಂ/ಎಕರೆ) 3-4 ಎಲೆಗಳ ಹಂತದಲ್ಲಿ ಸಿಂಪಡಿಸಿ.
• **ಸಾಂದರ್ಭಿಕ:** ಕತ್ತರಿಸುವುದರಿಂದ ಕವಲೊಡೆದು ಹೆಚ್ಚಾಗುತ್ತದೆ, ಬುಡಸಮೇತ ತೆಗೆಯುವುದು ಮುಖ್ಯ.''';
      }
      return '''🌾 **Purple Nutsedge (Cyperus rotundus) Control:**
• **Tuber Desiccation:** Deep summer ploughing exposes underground tubers to direct solar heat.
• **Chemical Option:** Halosulfuron-methyl 75% WG (36 g/acre) or Bentazone 48% SL applied at 3-5 leaf stage.
• **Important:** Avoid casual hoeing as it breaks apical dominance and multiplies subterranean nutlets.''';
    }

    if (q.contains('pre-emergent') || q.contains('ಪ್ರಿ-ಎಮರ್ಜೆಂಟ್') || q.contains('pre emergent')) {
      if (languageCode == 'kn') {
        return '''💧 **ಪ್ರಿ-ಎಮರ್ಜೆಂಟ್ ಸಸ್ಯನಾಶಕ ಬಳಕೆ ನಿಯಮ:**
• **ಸಮಯ:** ಬಿತ್ತನೆ ಮಾಡಿದ 24 ರಿಂದ 48 ಗಂಟೆಗಳ ಒಳಗೆ (ಬೀಜ ಮೊಳಕೆಯೊಡೆಯುವ ಮುನ್ನ).
• **ಮಣ್ಣಿನ ತೇವಾಂಶ:** ಔಷಧ ಪರಿಣಾಮಕಾರಿಯಾಗಿ ಕೆಲಸ ಮಾಡಲು ಮಣ್ಣಿನಲ್ಲಿ ಸಾಕಷ್ಟು ತೇವಾಂಶ ಅತ್ಯಗತ್ಯ.
• **ಉದಾಹರಣೆಗಳು:** ಪೆಂಡಿಮೆಥಾಲಿನ್ (Pendimethalin 30% EC), ಅಟ್ರಾಜಿನ್ (Atrazine 50% WP).''';
      }
      return '''💧 **Pre-Emergent Herbicide Guidelines:**
• **Timing:** Apply within 24 to 48 hours of sowing, before crop or weed seed emergence.
• **Soil Moisture:** Essential! Requires adequate surface soil moisture for chemical activation.
• **Key Products:** Pendimethalin 30% EC (1.0–1.2 L/acre), Atrazine 50% WP for maize/sugarcane.''';
    }

    if (q.contains('organic') || q.contains('bio') || q.contains('neem') || q.contains('ಸಾವಯವ')) {
      if (languageCode == 'kn') {
        return '''🍃 **ಸಾವಯವ ಜೈವಿಕ ಕಳೆ ನಿರ್ವಹಣೆ ರೆಸಿಪಿ:**
1. **ವಿನೆಗರ್ + ಬೇವಿನ ಎಣ್ಣೆ:** 10% ಅಸಿಟಿಕ್ ಆಮ್ಲ (ವಿನೆಗರ್) + 50 ಮಿಲಿ ಬೇವಿನ ಎಣ್ಣೆ + 5 ಮಿಲಿ ಸಾಬೂನಿನ ದ್ರಾವಣ (ಸ್ಪ್ರೆಡರ್).
2. **ಹುಲ್ಲು ಮಲ್ಚಿಂಗ್:** 4-6 ಇಂಚು ಒಣ ಹುಲ್ಲಿನ ಹೊದಿಕೆಯಿಂದ ಕಳೆ ಬೀಜಗಳು ಬೆಳಕಿಲ್ಲದೆ ಸಾಯುತ್ತವೆ.
3. **ಅಂತರ್ ಬೆಳೆ:** ಅಲಸಂದೆ ಅಥವಾ ಹೆಸರು ಬೆಳೆ ಬೆಳೆದು ಭೂಮಿಯನ್ನು ಆವರಿಸುವುದು.''';
      }
      return '''🍃 **Zero-Chemical Organic Herbicide Recipe:**
1. **Bio-Herbicide Spray:** 10% Household Acetic Acid (Vinegar) + 50 ml Pure Neem Oil + 5 ml mild liquid soap per 10 L water. Apply on hot sunny mornings.
2. **Organic Straw Mulch:** Apply a 4–6 inch layer of dry paddy straw between crop rows to block sunlight.
3. **Living Mulch:** Intercrop with cowpea or clover to smother emerging weed shoots naturally.''';
    }

    if (q.contains('spray') || q.contains('weather') || q.contains('ವಿಂಡೋ') || q.contains('ಸಿಂಪರಣೆ')) {
      if (languageCode == 'kn') {
        return '''🌦️ **ಸೂಕ್ತ ಕಳೆನಾಶಕ ಸಿಂಪರಣಾ ನಿಯಮಗಳು:**
• **ಗಾಳಿಯ ವೇಗ:** 3 ರಿಂದ 8 ಕಿ.ಮೀ/ಗಂಟೆ (10 ಕಿ.ಮೀ ಗಿಂತ ಹೆಚ್ಚಿದ್ದರೆ ಔಷಧ ತೇಲಿಹೋಗುತ್ತದೆ).
• **ಸಮಯ:** ಮುಂಜಾನೆ 7:00 ರಿಂದ 10:30 ಅಥವಾ ಸಂಜೆ 4:00 ರಿಂದ 6:30.
• **ಮಳೆ ಮುನ್ನೆಚ್ಚರಿಕೆ:** ಸಿಂಪಡಿಸಿದ ಕನಿಷ್ಠ 3 ರಿಂದ 4 ಗಂಟೆ ಮಳೆ ಬರಬಾರದು (Rainfastness).''';
      }
      return '''🌦️ **Optimal Spray Window Protocol:**
• **Wind Speed:** 3–8 km/h. Strictly avoid spraying if winds exceed 10 km/h to prevent chemical drift damage.
• **Best Hours:** Early morning (7:00 AM – 10:30 AM) or late afternoon (4:00 PM – 6:30 PM) when humidity is favorable.
• **Rainfastness:** Ensure at least 3–4 hours of clear weather post-spraying for systemic herbicide uptake.''';
    }

    // General fallback
    if (languageCode == 'kn') {
      return '''🌱 **ವೀಡ್‌ಗಾರ್ಡ್ ಕೃಷಿ AI ಸಹಾಯಕ:**
ನಮಸ್ಕಾರ! ನಿಮ್ಮ ಪ್ರಶ್ನೆಗೆ ಸಂಬಂಧಿಸಿದಂತೆ:
• ಕಳೆನಾಶಕಗಳನ್ನು ಯಾವಾಗಲೂ ಸರಿಯಾದ ಪ್ರಮಾಣದಲ್ಲಿ, ಸ್ವಚ್ಛ ನೀರಿನೊಂದಿಗೆ (pH 6.0) ಬಳಸಿ.
• ಸಮಗ್ರ ಕಳೆ ನಿರ್ವಹಣೆಗಾಗಿ (IWM) ರಾಸಾಯನಿಕ ಮತ್ತು ಸಾವಯವ ಕಳೆ ಕೀಳುವ ವಿಧಾನಗಳನ್ನು ಒಟ್ಟಿಗೆ ಬಳಸಿ.
• ಯಾವುದೇ ನಿರ್ದಿಷ್ಟ ಕಳೆ ಅಥವಾ ಬೆಳೆಗೆ ಸೂಕ್ತ ಶಿಫಾರಸು ತಿಳಿಯಲು ಕಳೆಯ ಹೆಸರು ಅಥವಾ ಫೋಟೋ ಸ್ಕ್ಯಾನ್ ಬಳಸಿ.''';
    }
    return '''🌱 **WeedGuard Agronomy Advisory:**
Hello! Here are key agronomic recommendations:
• **Spray Precision:** Always maintain calibrated flat-fan nozzles and ensure water pH is between 5.5 and 6.5.
• **Integrated Weed Management (IWM):** Combine mechanical weeding with targeted spot spraying to reduce chemical dependency by 40%–75%.
• **Crop Safety:** Ensure crop leaves are dry before applying selective post-emergent herbicides to avoid phytotoxicity.''';
  }
}
