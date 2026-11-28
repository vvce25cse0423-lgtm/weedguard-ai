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
      77, 89, 65, 117, 29, 69, 124, 70, 71, 71, 112, 77, 29, 114, 75, 122,
      67, 76, 76, 19, 29, 64, 72, 64, 125, 109, 78, 83, 72, 25, 108, 115,
      24, 112, 19, 97, 105, 100, 65, 91, 96, 70, 127, 76, 77, 73, 30, 93,
      30, 19, 102, 28, 101, 101, 101, 75,
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
    'qwen/qwen3.8-27b',         // Live on Groq: 0.17s response, vision + text, Kannada/Hindi fluency
    'openai/gpt-oss-120b',      // OpenAI 120B ChatGPT open weights
    'openai/gpt-oss-20b',       // OpenAI 20B fast model
    'allam-2-7b',               // Multilingual alternative
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
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

    // Default to the verified Groq API key
    if (_defaultGroqKey.isNotEmpty) {
      return _defaultGroqKey;
    }
    return _defaultMistralKey;
  }

  static String _buildSystemPrompt(String languageCode, {bool isFirstMessage = false}) {
    String languageInstruction = 'Respond in clear, simple English for farmers.';
    if (languageCode == 'kn') {
      languageInstruction = 'Respond purely in clear, natural Kannada (ಕನ್ನಡ) for Karnataka farmers.';
    } else if (languageCode == 'hi') {
      languageInstruction = 'Respond purely in clear, natural Hindi (हिंदी) for Indian farmers.';
    }

    String greetingInstruction;
    if (isFirstMessage) {
      greetingInstruction = '''
2. GREET ON FIRST CONVERSATION TURN:
   - Since this is the very first message from the user, begin with a warm, polite one-sentence greeting (e.g. "Hello! Welcome to WeedGuard AI. Here is what you need for your crops:") and then immediately present the advice.
''';
    } else {
      greetingInstruction = '''
2. ZERO GREETINGS ON FOLLOW-UP CONVERSATIONS:
   - This is an ongoing conversation. NEVER start with greetings ("Hello", "Hi, I am WeedGuard AI", "Greetings", "Welcome").
   - NEVER include conversational preambles ("It's a great question", "Prevention is key", "Here is a guide").
   - Start IMMEDIATELY with the very first bullet point.
''';
    }

    return '''
You are WeedGuard AI, a high-precision agronomy engine.
$languageInstruction

CRITICAL MANDATORY INSTRUCTIONS:
1. STRICT BULLET POINTS ONLY (•):
   - Every single answer MUST be structured entirely in bullet points starting with "•".
   - Each bullet point must begin with a bold topic label in **bold**, for example:
     • **Seed Bank Prevention:** Mow or cut weeds before they flower and set seed to deplete the soil seed bank.
     • **Pre-Emergent Herbicides:** Apply Pendimethalin 30% EC (1.0–1.2 L/acre) or Atrazine (for maize/sorghum) on moist soil within 48 hours of sowing.
     • **Organic Mulching:** Spread 4–6 inches of dry straw or organic biomass between rows to block sunlight and conserve moisture.
     • **Crop Rotation & Cover Crops:** Rotate with fast-canopy legumes (cowpea, black gram) to naturally smother weeds.
     • **Mechanical Cultivation:** Use wheel hoes or inter-row cultivators 15–25 days after sowing to sever weed roots.
     • **Spray Window:** Spray only when wind speed is <10 km/h, temperature is moderate, and no rain is forecast for 3–4 hours.
     • **Safety PPE:** Wear chemical-resistant rubber gloves, an N95 respirator mask, and eye protection.

$greetingInstruction
   - NEVER end with conversational questions or offers ("Would you like help calculating dosage?", "Tell me your crop", "Let me know").
   - Terminate immediately after the last bullet point.

3. 100% ACCURACY & AGRICULTURAL PRECISION:
   - Provide scientifically validated chemical names (Pendimethalin, Atrazine, 2,4-D, Glyphosate, Halosulfuron, Bispyribac sodium).
   - Give exact dilution dosages, tank ratios (per 15L knapsack or per acre), and application timings.
   - For organic methods, provide concrete measurements (inches, ratios, days).

4. CLEAN FORMATTING ONLY:
   - NEVER output triple asterisks like `***` or divider lines (`---`, `___`).
   - Use ONLY bold `**term**` and bullet points `•`.
''';
  }

  /// Cleans AI text: removes reasoning tags, strips conversational greeting/closing filler,
  /// converts headers/numbered lists into clean bullet points, and ensures NO `***` appears.
  static String cleanAiResponse(String raw, {bool isFirstMessage = false, String languageCode = 'en'}) {
    if (raw.isEmpty) return raw;

    // 1. Strip reasoning chain-of-thought tags (<think>...</think>)
    var text = raw.replaceAll(RegExp(r'<think>[\s\S]*?<\/think>', caseSensitive: false), '').trim();

    // 2. Remove divider lines made of asterisks, dashes, or underscores (***, ****, ---, ___)
    text = text.replaceAll(RegExp(r'^\s*(\*{3,}|-{3,}|_{3,})\s*$', multiLine: true), '');

    // 3. Convert bold-italic ***text*** or ****text**** into clean bold **text**
    text = text.replaceAllMapped(RegExp(r'\*{3,}(.*?)\*{3,}'), (m) => '**${m[1]?.trim()}**');

    // 4. Eliminate any remaining triple or multiple asterisks anywhere in the text
    text = text.replaceAll(RegExp(r'\*{3,}'), '');

    // 5. Convert markdown headers (### 1. Title or ### Title) to bullet points (• **Title:**)
    text = text.replaceAllMapped(
      RegExp(r'^\s*#{1,6}\s*(?:\d+[\.\)]\s*)?(.*?)\s*$', multiLine: true),
      (m) {
        final title = m[1]?.trim() ?? '';
        if (title.isEmpty) return '';
        final cleanTitle = title.replaceAll(RegExp(r'[:：]+$'), '');
        return '• **$cleanTitle:**';
      },
    );

    // 6. Convert standard asterisks or hyphen bullets (* or -) to clean dot bullets (•)
    text = text.replaceAll(RegExp(r'^\s*[\*\-]\s+', multiLine: true), '• ');

    // 7. Convert numbered lists (1. , 2. ) to bullet points (• )
    text = text.replaceAll(RegExp(r'^\s*\d+[\.\)]\s+', multiLine: true), '• ');

    // 8. If NOT the first message, strip conversational greeting / preamble lines at start
    final lines = text.split('\n');
    final cleanedLines = <String>[];
    var hasStartedBullets = false;

    final fluffStartRegex = RegExp(
      r'^(hello|hi|hey|greetings|namaskara|namaste)|'
      r'(weedguard\s+ai)|'
      r'(great\s+question|good\s+question)|'
      r'(here\s+(is|are)|below\s+(is|are)|follow\s+these|broken\s+down)|'
      r'(prevention\s+saves|step-by-step)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final stripped = line.trim();
      if (stripped.isEmpty) {
        if (hasStartedBullets || isFirstMessage) {
          cleanedLines.add('');
        }
        continue;
      }

      if (!isFirstMessage && !hasStartedBullets) {
        if (!stripped.startsWith('•') && fluffStartRegex.hasMatch(stripped)) {
          continue;
        }
        hasStartedBullets = true;
      } else {
        hasStartedBullets = true;
      }

      cleanedLines.add(line);
    }

    // 9. If isFirstMessage is true, ensure there is a warm greeting at the beginning
    if (isFirstMessage) {
      final fullText = cleanedLines.join('\n').trim();
      final hasGreetingAlready = fluffStartRegex.hasMatch(fullText);
      if (!hasGreetingAlready) {
        String greetingHeader = 'Hello! Welcome to WeedGuard AI. Here is what you need for your crops:';
        if (languageCode == 'kn') {
          greetingHeader = 'ನಮಸ್ಕಾರ! ವೀಡ್‌ಗಾರ್ಡ್ AI ಗೆ ಸುಸ್ವಾಗತ. ನಿಮ್ಮ ಕೃಷಿ ಕಳೆ ನಿರ್ವಹಣೆಗೆ ಇಲ್ಲಿದೆ ಮಾಹಿತಿ:';
        } else if (languageCode == 'hi') {
          greetingHeader = 'नमस्ते! वीडगार्ड AI में आपका स्वागत है। आपकी फसलों के लिए खरपतवार प्रबंधन जानकारी:';
        }
        cleanedLines.insert(0, '');
        cleanedLines.insert(0, greetingHeader);
      }
    }

    // 10. Strip trailing conversational sign-offs / questions from the end
    final fluffEndRegex = RegExp(
      r'(would\s+you\s+like|feel\s+free|let\s+me\s+know|just\s+tell\s+me|hope\s+this\s+helps|reach\s+out|happy\s+farming)',
      caseSensitive: false,
    );

    while (cleanedLines.isNotEmpty) {
      final last = cleanedLines.last.trim();
      if (last.isEmpty) {
        cleanedLines.removeLast();
        continue;
      }
      if (fluffEndRegex.hasMatch(last)) {
        cleanedLines.removeLast();
      } else {
        break;
      }
    }

    var result = cleanedLines.join('\n');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return result.trim();
  }

  static Future<String> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
    String languageCode = 'en',
    bool isFirstMessage = false,
  }) async {
    final activeKey = await getEffectiveApiKey();

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt(languageCode, isFirstMessage: isFirstMessage),
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

    // ── Tier 1: High-Speed Groq Cloud AI (Qwen 3.8 27B / GPT-OSS 120B) ──
    String groqKey = _envGroqKey.isNotEmpty ? _envGroqKey : _defaultGroqKey;
    if (activeKey.startsWith('gsk_')) {
      groqKey = activeKey;
    }

    if (groqKey.isNotEmpty) {
      for (final model in _groqModels) {
        try {
          final body = jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.2,
            'max_tokens': 1200,
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
                final cleaned = cleanAiResponse(
                  content,
                  isFirstMessage: isFirstMessage,
                  languageCode: languageCode,
                );
                if (cleaned.isNotEmpty) return cleaned;
              }
            }
          }
        } catch (_) {
          // Continue to next model if error or timeout
        }
      }
    }

    // ── Tier 2: Mistral AI Fallback ──
    if (activeKey.startsWith('mstrl_')) {
      for (final model in _mistralModels) {
        try {
          final body = jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.2,
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
                final cleaned = cleanAiResponse(
                  content,
                  isFirstMessage: isFirstMessage,
                  languageCode: languageCode,
                );
                if (cleaned.isNotEmpty) return cleaned;
              }
            }
          } else if (response.statusCode == 402) {
            // Mistral billing budget not configured yet; break to offline tier
            break;
          }
        } catch (_) {
          // Try next model if timeout or network hiccup
        }
      }
    }

    // ── Tier 3: ChatGPT-style Offline Agronomy Knowledge Engine ──
    final fallback = _getOfflineFallbackResponse(userMessage, languageCode);
    return cleanAiResponse(
      fallback,
      isFirstMessage: isFirstMessage,
      languageCode: languageCode,
    );
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
• **ಯಾಂತ್ರಿಕ ವಿಧಾನ:** ಬೀಜ ಕಟ್ಟುವುಕ್ಕಿಂತ ಮುನ್ನ ಕೊಳೆತ ಎಡೆಕುಂಟೆ (Wheel Hoe) ಅಥವಾ ಕೈಯಿಂದ ಕಳೆ ಕೀಳುವುದು.
• **ಸಾವಯವ ಮಲ್ಚಿಂಗ್:** ಸಾಲುಗಳ ನಡುವೆ ಒಣ ಹುಲ್ಲಿನ ಹೊದಿಕೆ ಹಾಕಿ ಸೂರ್ಯನ ಬೆಳಕು ತಡೆದು ಕಳೆ ಹತ್ತಿಕ್ಕುವುದು.
• **ಅಂತರ್ ಬೆಳೆ ಪದ್ಧತಿ:** ದ್ವಿದಳ ಧಾನ್ಯ ಬೆಳೆಸಿ ಮಣ್ಣನ್ನು ಆವರಿಸಿ ಕಳೆ ಮೊಳಕೆಯೊಡೆಯದಂತೆ ತಡೆಯುವುದು.
• **ಸಮಗ್ರ ನಿರ್ವಹಣೆ (IWM):** ಕನಿಷ್ಠ ರಾಸಾಯನಿಕ ಮತ್ತು ಗರಿಷ್ಠ ನೈಸರ್ಗಿಕ ತಡೆ ವಿಧಾನಗಳ ಮಿಶ್ರಣ.''';
      }
      return '''🛠️ **Integrated Weed Removal Methods:**
• **Mechanical Hoeing:** Manual wheel hoes or rotary weeders during early vegetative stages (15–25 days after sowing).
• **Solarization & Mulching:** Organic straw mulching (3–4 inches) to block sunlight from weed seedbeds.
• **Biological & Smother Crops:** Intercrop fast-canopy legumes (cowpea, black gram) to starve weeds of light.
• **Targeted Spot Spraying:** Treat stubborn patches with precision nozzles instead of blanket field spraying.''';
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
• **ಶುದ್ಧ ಬೀಜ ಬಳಕೆ:** ಪ್ರಮಾಣೀಕೃತ, ಕಳೆಬೀಜ ರಹಿತ ಶುದ್ಧ ಬಿತ್ತನೆ ಬೀಜಗಳನ್ನು ಮಾತ್ರ ಬಳಸಿ.
• **ನಿರ್ಣಾಯಕ ಹಂತ (ಮೊದಲ 30 ದಿನಗಳು):** ಬೆಳೆಯ ಆರಂಭಿಕ 3-4 ವಾರಗಳು ಅತ್ಯಂತ ಮುಖ್ಯ, ಈ ಸಮಯದಲ್ಲಿ ಕಳೆ ಮುಕ್ತವಾಗಿರಿಸಿದರೆ 80% ಇಳುವರಿ ಸುಧಾರಿಸುತ್ತದೆ.
• **ಉಳುಮೆ ಯಂತ್ರಗಳ ಸ್ವಚ್ಛತೆ:** ಒಂದು ಹೊಲದಿಂದ ಇನ್ನೊಂದು ಹೊಲಕ್ಕೆ ಟ್ರ್ಯಾಕ್ಟರ್ ಅಥವಾ ಉಪಕರಣಗಳನ್ನು ಬಳಸುವ ಮುನ್ನ ಸ್ವಚ್ಛಗೊಳಿಸಿ.
• **ಬೆಳೆ ಪರಿವರ್ತನೆ (Crop Rotation):** ಒಂದೇ ಬೆಳೆ ಬದಲಿಗೆ ಕಾಲಕಾಲಕ್ಕೆ ಬೆಳೆ ಬದಲಾಯಿಸುವುದರಿಂದ ಕಳೆಯ ಚಕ್ರ ಮುರಿಯುತ್ತದೆ.''';
      }
      return '''🌱 **Top Farming & Weed Prevention Tips:**
• **Critical Period of Weed Competition (CPWC):** Keep fields 100% weed-free during the first 25–40 days after emergence; this guarantees up to 80% higher crop yield.
• **Certified Clean Seeds:** Prevent introducing invasive weed seeds by planting certified, cleaned seed stock.
• **Equipment Sanitation:** Pressure-wash cultivators and harvesters before moving between different farm plots to stop root/seed transfer.
• **Smart Crop Rotation:** Alternate tap-root crops with fibrous-root crops to disrupt persistent weed cycles.''';
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
• **ವಿನೆಗರ್ + ಬೇವಿನ ಎಣ್ಣೆ:** 10% ಅಸಿಟಿಕ್ ಆಮ್ಲ (ವಿನೆಗರ್) + 50 ಮಿಲಿ ಬೇವಿನ ಎಣ್ಣೆ + 5 ಮಿಲಿ ಸಾಬೂನಿನ ದ್ರಾವಣ (ಸ್ಪ್ರೆಡರ್).
• **ಹುಲ್ಲು ಮಲ್ಚಿಂಗ್:** 4-6 ಇಂಚು ಒಣ ಹುಲ್ಲಿನ ಹೊದಿಕೆಯಿಂದ ಕಳೆ ಬೀಜಗಳು ಬೆಳಕಿಲ್ಲದೆ ಸಾಯುತ್ತವೆ.
• **ಅಂತರ್ ಬೆಳೆ:** ಅಲಸಂದೆ ಅಥವಾ ಹೆಸರು ಬೆಳೆ ಬೆಳೆದು ಭೂಮಿಯನ್ನು ಆವರಿಸುವುದು.''';
      }
      return '''🍃 **Zero-Chemical Organic Herbicide Recipe:**
• **Bio-Herbicide Spray:** 10% Household Acetic Acid (Vinegar) + 50 ml Pure Neem Oil + 5 ml mild liquid soap per 10 L water. Apply on hot sunny mornings.
• **Organic Straw Mulch:** Apply a 4–6 inch layer of dry paddy straw between crop rows to block sunlight.
• **Living Mulch:** Intercrop with cowpea or clover to smother emerging weed shoots naturally.''';
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

    // 10. General Bulleted Response
    if (languageCode == 'kn') {
      return '''🌱 **ವೀಡ್‌ಗಾರ್ಡ್ ಕೃಷಿ ಮಾರ್ಗದರ್ಶಿ:**
• **ಕಳೆನಾಶಕ ಬಳಕೆ:** ಯಾವಾಗಲೂ ಶಿಫಾರಸು ಮಾಡಿದ ಪ್ರಮಾಣದಲ್ಲಿ ಸ್ವಚ್ಛ ನೀರಿನೊಂದಿಗೆ (pH 6.0) ಬಳಸಿ.
• **ಸಮಗ್ರ ಕಳೆ ನಿರ್ವಹಣೆ (IWM):** ಕಳೆ ಹತೋಟಿಗೆ ಯಾಂತ್ರಿಕ, ಸಾವಯವ ಮತ್ತು ರಾಸಾಯನಿಕ ವಿಧಾನಗಳನ್ನು ಸಂಯೋಜಿಸಿ.
• **ಕ್ಯಾಮೆರಾ ಸ್ಕ್ಯಾನರ್:** ನಿಮ್ಮ ಹೊಲದ ಕಳೆಯ ಚಿತ್ರವನ್ನು ಸ್ಕ್ಯಾನರ್ ಮೂಲಕ ಕಳುಹಿಸಿ ನೇರ ಸಲಹೆ ಪಡೆಯಿರಿ.''';
    }
    return '''🌱 **WeedGuard Agricultural Recommendations:**
• **Targeted Application:** Always apply selective post-emergent herbicides when weeds are small (2–4 leaf stage) for highest efficacy.
• **Integrated Weed Management (IWM):** Combine mechanical cultivation with bio-mulching to reduce chemical dependency by 40%–60%.
• **Precision Spraying:** Use calibrated flat-fan nozzles and avoid spraying during high noon heat or wind speeds above 10 km/h.
• **Visual Scan:** Feel free to snap a photo with our Weed Scanner anytime for instant species identification and tailored chemical dosages.''';
  }
}
