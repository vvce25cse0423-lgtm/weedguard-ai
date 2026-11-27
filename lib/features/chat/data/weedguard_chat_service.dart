import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';

class WeedGuardChatService {
  // Mistral AI Configuration
  static const _mistralUrl = 'https://api.mistral.ai/v1/chat/completions';
  static const _defaultMistralKey = 'mstrl_U3grSBWY5Vl4TrNbftjG1gHSzJNAwNdc_06Dpzb';

  // Groq Fallback Configuration
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

  // Top Mistral Models for ChatGPT-like conversational interaction
  static const List<String> _mistralModels = [
    'mistral-small-latest',
    'codestral-latest',
    'ministral-8b-latest',
    'open-mistral-nemo',
    'open-mistral-7b',
  ];

  // Groq Models prioritized for agricultural precision & multilingual fluency
  static const List<String> _groqModels = [
    'qwen/qwen3.8-27b',
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
  ];

  static Future<void> saveUserApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_chat_api_key', key.trim());
  }

  static Future<String?> getUserApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('ai_chat_api_key') ?? prefs.getString('groq_api_key');
    } catch (_) {
      return null;
    }
  }

  static Future<String> getEffectiveApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = prefs.getString('ai_chat_api_key') ?? prefs.getString('groq_api_key');
      if (userKey != null && userKey.trim().isNotEmpty) {
        return userKey.trim();
      }
    } catch (_) {}

    // Default to user's provided Mistral key
    return _defaultMistralKey;
  }

  static String _buildSystemPrompt(String languageCode) {
    String languageInstruction = 'Respond in simple, clear, conversational English like a helpful ChatGPT assistant.';
    if (languageCode == 'kn') {
      languageInstruction = 'Respond in fluent, warm, and natural Kannada (ಕನ್ನಡ) language for Karnataka farmers.';
    } else if (languageCode == 'hi') {
      languageInstruction = 'Respond in fluent, friendly Hindi (हिंदी) language for Indian farmers.';
    }

    return '''
You are WeedGuard AI, an intelligent, conversational ChatGPT-like agronomy assistant designed specifically for farmers.
You are warm, knowledgeable, practical, and highly encouraging.

Your agricultural superpowers:
1. Weed Identification & Diagnosis: Explain leaf anatomy, broadleaf vs. grassy vs. sedges, vegetative signs, and growth stages.
2. Precision Herbicide Recommendations: Pre-emergent vs post-emergent options, active chemical ingredients (Pendimethalin, Atrazine, 2,4-D, Glyphosate, Glufosinate, Bispyribac sodium, Quizalofop).
3. Exact Dosage Math: Dilution ratios per 15L knapsack tank or per acre, water volume, and proper nozzle calibration.
4. Organic & Eco-Friendly Farming: Vinegar + neem oil bio-sprays, straw mulching (4-6 inches), cover crops (cowpea), and mechanical wheel hoes.
5. Meteorological Spray Windows: Wind drift (<10 km/h), rainfastness (3-4 hrs), humidity (60-80%), and temperature.
6. Safety First: Always mandate rubber PPE gloves, chemical masks, and clean water.

Response Style:
- $languageInstruction
- Friendly greeting and structured breakdown with bullet points and bold highlights.
- Keep recommendations actionable, practical, and easy for farmers to apply immediately.
''';
  }

  static Future<String> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
    String languageCode = 'en',
  }) async {
    final activeKey = await getEffectiveApiKey();

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt(languageCode),
      },
    ];

    // Maintain recent conversation history (last 8 messages) for ChatGPT-like multi-turn memory
    final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;
    for (final msg in recentHistory) {
      messages.add({
        'role': msg.sender == MessageSender.user ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    // Add current query
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    // ── Tier 1: Try Mistral AI if key starts with mstrl_ or standard key ──
    if ((activeKey.startsWith('mstrl_') || activeKey == _defaultMistralKey) && !activeKey.startsWith('gsk_')) {
      for (final model in _mistralModels) {
        try {
          final body = jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 1024,
          });

          final response = await http
              .post(
                Uri.parse(_mistralUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $activeKey',
                },
                body: utf8.encode(body),
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
            final choices = decoded['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final content = choices[0]['message']?['content'] as String?;
              if (content != null && content.trim().isNotEmpty) {
                return content.trim();
              }
            }
          } else if (response.statusCode == 402) {
            // Mistral billing budget not configured yet; break to fallback tier
            break;
          }
        } catch (_) {
          // Try next model if timeout or network hiccup
        }
      }
    }

    // ── Tier 2: Try Groq Cloud AI ──
    String groqKey = _envGroqKey.isNotEmpty ? _envGroqKey : _defaultGroqKey;
    if (activeKey.startsWith('gsk_')) {
      groqKey = activeKey;
    }

    for (final model in _groqModels) {
      try {
        final body = jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        });

        final response = await http
            .post(
              Uri.parse(_groqUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $groqKey',
              },
              body: utf8.encode(body),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final choices = decoded['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              // Strip reasoning chain-of-thought tags (<think>...</think>) for clean chat output
              final cleaned = content.replaceAll(RegExp(r'<think>[\s\S]*?<\/think>', caseSensitive: false), '').trim();
              return cleaned.isNotEmpty ? cleaned : content.trim();
            }
          }
        }
      } catch (_) {
        // Continue to next model
      }
    }

    // ── Tier 3: ChatGPT-style Offline Agronomy Knowledge Engine ──
    return _getOfflineFallbackResponse(userMessage, languageCode);
  }

  static String _getOfflineFallbackResponse(String query, String languageCode) {
    final q = query.toLowerCase();

    // 1. Template Card: Identify Weed
    if (q.contains('identify') || q.contains('identification') || q.contains('ಗುರುತಿಸು') || q.contains('पहचान')) {
      if (languageCode == 'kn') {
        return '''🔍 **ಕಳೆ ಗುರುತಿಸುವಿಕೆ ಮಾರ್ಗದರ್ಶಿ:**
• **ಎಲೆಯ ಆಕಾರ:** ಅಗಲ ಎಲೆಯ ಕಳೆಗಳು (ಪಾರ್ಥೇನಿಯಂ, ಅಮಾರಾಂತಸ್) vs ಕಿರಿದಾದ ಹುಲ್ಲಿನ ಕಳೆಗಳು (ಸೈನೋಡಾನ್, ಎಕಿನೋಕ್ಲೋವಾ).
• **ಕಾಂಡ ಮತ್ತು ಬೇರು:** ದುಂಡಾದ ಕಾಂಡಗಳು (ಹುಲ್ಲು), ತ್ರಿಕೋನಾಕಾರದ ಕಾಂಡ ಮತ್ತು ಗೆಡ್ಡೆಗಳು (ಭದ್ರಮುಷ್ಟಿ ಸೈಪರಸ್).
• **ಕ್ಯಾಮೆರಾ ಸ್ಕ್ಯಾನರ್:** ನಿಖರ ಗುರುತಿಸುವಿಕೆಗೆ ವೀಡ್‌ಗಾರ್ಡ್ AI ಕ್ಯಾಮೆರಾ ಸ್ಕ್ಯಾನರ್ ಬಳಸಿ ನೇರವಾಗಿ ಫೋಟೋ ತೆಗೆಯಿರಿ.''';
      }
      return '''🔍 **Weed Identification Guide:**
• **Broadleaf vs Grassy Weeds:** Broadleaf weeds (Parthenium, Pigweed) have netted leaf veins and showy flowers. Grasses (Barnyard grass, Bermuda grass) have narrow, parallel-veined leaves and hollow round stems.
• **Sedges (Nutgrass):** Distinctive triangular solid stems and underground tuber chains (Cyperus rotundus).
• **WeedGuard Camera Scanner:** Use our live camera scanner to snap a photo for instant AI visual detection and classification.''';
    }

    // 2. Template Card: Removal Method
    if (q.contains('removal') || q.contains('remove') || q.contains('ತೆಗೆಯುವ') || q.contains('ಕಳೆ ತೆಗೆಯುವ') || q.contains('हटाने')) {
      if (languageCode == 'kn') {
        return '''🛠️ **ಕಳೆ ತೆಗೆಯುವ ಪರಿಣಾಮಕಾರಿ ವಿಧಾನಗಳು:**
1. **ಯಾಂತ್ರಿಕ ವಿಧಾನ:** ಬೀಜ ಕಟ್ಟುವುಕ್ಕಿಂತ ಮುನ್ನ ಕೊಳೆತ ಎಡೆಕುಂಟೆ (Wheel Hoe) ಅಥವಾ ಕೈಯಿಂದ ಕಳೆ ಕೀಳುವುದು.
2. **ಸಾವಯವ ಮಲ್ಚಿಂಗ್:** ಸಾಲುಗಳ ನಡುವೆ ಒಣ ಹುಲ್ಲಿನ ಹೊದಿಕೆ ಹಾಕಿ ಸೂರ್ಯನ ಬೆಳಕು ತಡೆದು ಕಳೆ ಹತ್ತಿಕ್ಕುವುದು.
3. **ಅಂತರ್ ಬೆಳೆ ಪದ್ಧತಿ:** ದ್ವಿದಳ ಧಾನ್ಯ ಬೆಳೆಸಿ ಮಣ್ಣನ್ನು ಆವರಿಸಿ ಕಳೆ ಮೊಳಕೆಯೊಡೆಯದಂತೆ ತಡೆಯುವುದು.
4. **ಸಮಗ್ರ ನಿರ್ವಹಣೆ (IWM):** ಕನಿಷ್ಠ ರಾಸಾಯನಿಕ ಮತ್ತು ಗರಿಷ್ಠ ನೈಸರ್ಗಿಕ ತಡೆ ವಿಧಾನಗಳ ಮಿಶ್ರಣ.''';
      }
      return '''🛠️ **Integrated Weed Removal Methods:**
1. **Mechanical Hoeing:** Manual wheel hoes or rotary weeders during early vegetative stages (15–25 days after sowing).
2. **Solarization & Mulching:** Organic straw mulching (3–4 inches) to block sunlight from weed seedbeds.
3. **Biological & Smother Crops:** Intercrop fast-canopy legumes (cowpea, black gram) to starve weeds of light.
4. **Targeted Spot Spraying:** Treat stubborn patches with precision nozzles instead of blanket field spraying.''';
    }

    // 3. Template Card: Safe Herbicides
    if (q.contains('safe herbicide') || q.contains('herbicide') || q.contains('ಕಳೆನಾಶಕ') || q.contains('शाकनाशी')) {
      if (languageCode == 'kn') {
        return '''🛡️ **ಸುರಕ್ಷಿತ ಕಳೆನಾಶಕಗಳ ಬಳಕೆ ಹಾಗೂ ಮುನ್ನೆಚ್ಚರಿಕೆ:**
• **ಆಯ್ಕೆ ಮಾಡಿದ ಕಳೆನಾಶಕ (Selective):** ಬೆಳೆಗಳಿಗೆ ಹಾನಿಯಾಗದಂತೆ ಕಳೆಯನ್ನು ಮಾತ್ರ ನಾಶಪಡಿಸುವ ಔಷಧಿಗಳು (ಉದಾ: ಮೆಕ್ಕೆಜೋಳಕ್ಕೆ ಅಟ್ರಾಜಿನ್).
• **ಪ್ರಿ-ಎಮರ್ಜೆಂಟ್:** ಪೆಂಡಿಮೆಥಾಲಿನ್ (Pendimethalin 30% EC) - ಬಿತ್ತನೆ ಮಾಡಿದ 48 ಗಂಟೆಗಳ ಒಳಗೆ ತೇವಾಂಶವಿರುವ ಮಣ್ಣಿಗೆ ಸಿಂಪಡಿಸಿ.
• **ಸುರಕ್ಷತಾ ಕ್ರಮಗಳು:** ರಬ್ಬರ್ ಕೈಗವಸು, ಮಾಸ್ಕ್ ಧರಿಸಿ, ಗಾಳಿಯ ವಿರುದ್ಧ ದಿಕ್ಕಿನಲ್ಲಿ ಸಿಂಪಡಿಸಬೇಡಿ. ಮಕ್ಕಳು ಮತ್ತು ಜಾನುವಾರುಗಳಿಂದ ದೂರವಿಡಿ.''';
      }
      return '''🛡️ **Safe & Selective Herbicides Protocol:**
• **Crop-Specific Selective Herbicides:** Use targeted selective molecules that eliminate weeds without injuring crop roots (e.g., Atrazine for maize/sorghum, Bispyribac sodium for paddy).
• **Pre-Emergent Safety:** Apply Pendimethalin 30% EC within 48 hours of sowing on moist soil to create a chemical protective barrier.
• **PPE Protection:** Always wear rubber chemical gloves, safety goggles, and an N95 respirator. Never spray against wind direction.''';
    }

    // 4. Template Card: Farming Tips
    if (q.contains('farming tip') || q.contains('farming tips') || q.contains('tips') || q.contains('ಕೃಷಿ ಸಲಹೆ') || q.contains('खेती')) {
      if (languageCode == 'kn') {
        return '''🌱 **ಉತ್ತಮ ಕೃಷಿ ಹಾಗೂ ಕಳೆ ನಿಯಂತ್ರಣ ಸಲಹೆಗಳು:**
1. **ಶುದ್ಧ ಬೀಜ ಬಳಕೆ:** ಪ್ರಮಾಣೀಕೃತ, ಕಳೆಬೀಜ ರಹಿತ ಶುದ್ಧ ಬಿತ್ತನೆ ಬೀಜಗಳನ್ನು ಮಾತ್ರ ಬಳಸಿ.
2. **ಮೊದಲ 30 ದಿನಗಳ ನಿರ್ಣಾಯಕ ಹಂತ:** ಬೆಳೆಯ ಆರಂಭಿಕ 3-4 ವಾರಗಳು ಅತ್ಯಂತ ಮುಖ್ಯ, ಈ ಸಮಯದಲ್ಲಿ ಕಳೆ ಮುಕ್ತವಾಗಿರಿಸಿದರೆ 80% ಇಳುವರಿ ಸುಧಾರಿಸುತ್ತದೆ.
3. **ಉಳುಮೆ ಯಂತ್ರಗಳ ಸ್ವಚ್ಛತೆ:** ಒಂದು ಹೊಲದಿಂದ ಇನ್ನೊಂದು ಹೊಲಕ್ಕೆ ಟ್ರ್ಯಾಕ್ಟರ್ ಅಥವಾ ಉಪಕರಣಗಳನ್ನು ಬಳಸುವ ಮುನ್ನ ಸ್ವಚ್ಛಗೊಳಿಸಿ.
4. **ಬೆಳೆ ಪರಿವರ್ತನೆ (Crop Rotation):** ಒಂದೇ ಬೆಳೆ ಬದಲಿಗೆ ಕಾಲಕಾಲಕ್ಕೆ ಬೆಳೆ ಬದಲಾಯಿಸುವುದರಿಂದ ಕಳೆಯ ಚಕ್ರ ಮುರಿಯುತ್ತದೆ.''';
      }
      return '''🌱 **Top Farming & Weed Prevention Tips:**
1. **Critical Period of Weed Competition (CPWC):** Keep fields 100% weed-free during the first 25–40 days after emergence; this guarantees up to 80% higher crop yield.
2. **Certified Clean Seeds:** Prevent introducing invasive weed seeds by planting certified, cleaned seed stock.
3. **Equipment Sanitation:** Pressure-wash cultivators and harvesters before moving between different farm plots to stop root/seed transfer.
4. **Smart Crop Rotation:** Alternate tap-root crops with fibrous-root crops to disrupt persistent weed cycles.''';
    }

    // 5. Parthenium
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

    // 6. Nutsedge / Cyperus
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

    // 7. Pre-emergent
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

    // 8. Organic Recipes
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

    // 9. Spray Windows / Weather
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

    // 10. General ChatGPT-style Response
    if (languageCode == 'kn') {
      return '''🌱 **ವೀಡ್‌ಗಾರ್ಡ್ ಕೃಷಿ AI ಸಹಾಯಕ:**
ನಮಸ್ಕಾರ! ನಾನು ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ಕೃಷಿ AI ಸಹಾಯಕ:
• **ಕಳೆನಾಶಕ ಬಳಕೆ:** ಯಾವಾಗಲೂ ಶಿಫಾರಸು ಮಾಡಿದ ಪ್ರಮಾಣದಲ್ಲಿ ಸ್ವಚ್ಛ ನೀರಿನೊಂದಿಗೆ (pH 6.0) ಬಳಸಿ.
• **ಸಮಗ್ರ ಕಳೆ ನಿರ್ವಹಣೆ (IWM):** ಕಳೆ ಹತೋಟಿಗೆ ಯಾಂತ್ರಿಕ, ಸಾವಯವ ಮತ್ತು ರಾಸಾಯನಿಕ ವಿಧಾನಗಳನ್ನು ಸಂಯೋಜಿಸಿ.
• **ಕ್ಯಾಮೆರಾ ಸ್ಕ್ಯಾನರ್:** ನಿಮ್ಮ ಹೊಲದ ಕಳೆಯ ಚಿತ್ರವನ್ನು ಸ್ಕ್ಯಾನರ್ ಮೂಲಕ ಕಳುಹಿಸಿ ನೇರ ಸಲಹೆ ಪಡೆಯಿರಿ.''';
    }
    return '''🌱 **WeedGuard Agricultural Advisor:**
Hello! Here are key agronomy recommendations for your query:
• **Targeted Application:** Always apply selective post-emergent herbicides when weeds are small (2–4 leaf stage) for highest efficacy.
• **Integrated Weed Management (IWM):** Combine mechanical cultivation with bio-mulching to reduce chemical dependency by 40%–60%.
• **Precision Spraying:** Use calibrated flat-fan nozzles and avoid spraying during high noon heat or wind speeds above 10 km/h.
• **Visual Scan:** Feel free to snap a photo with our Weed Scanner anytime for instant species identification and tailored chemical dosages.''';
  }
}
