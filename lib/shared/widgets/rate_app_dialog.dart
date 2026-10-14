import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/app_localizations.dart';

class RateAppDialog extends StatefulWidget {
  const RateAppDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RateAppDialog(),
    );
  }

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog> {
  int _selectedStars = 5;
  final Set<String> _selectedExperiences = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getStarTitle(String lang, int stars) {
    if (lang == 'kn') {
      switch (stars) {
        case 5: return 'ಅತ್ಯುತ್ತಮ ಅನುಭವ! 🌟';
        case 4: return 'ತುಂಬಾ ಒಳ್ಳೆಯ ಆ್ಯಪ್! 👍';
        case 3: return 'ಉತ್ತಮ, ಸುಧಾರಣೆಗೆ ಅವಕಾಶವಿದೆ 🙂';
        case 2: return 'ಸಾಧಾರಣ ಅನುಭವ 😐';
        default: return 'ಸುಧಾರಣೆ ಅಗತ್ಯವಿದೆ 🙁';
      }
    } else if (lang == 'hi') {
      switch (stars) {
        case 5: return 'उत्कृष्ट अनुभव! 🌟';
        case 4: return 'बहुत अच्छा ऐप! 👍';
        case 3: return 'अच्छा, सुधार संभव है 🙂';
        case 2: return 'सामान्य अनुभव 😐';
        default: return 'सुधार की आवश्यकता 🙁';
      }
    } else {
      switch (stars) {
        case 5: return 'Outstanding Experience! 🌟';
        case 4: return 'Great Experience! 👍';
        case 3: return 'Good, with room for improvement 🙂';
        case 2: return 'Fair experience 😐';
        default: return 'Needs improvement 🙁';
      }
    }
  }

  List<String> _getExperienceOptions(String lang) {
    if (lang == 'kn') {
      return [
        '🌿 ನಿಖರ ಕಳೆ ಮತ್ತು ಬೆಳೆ ಪತ್ತೆ',
        '🗣️ ಕನ್ನಡ ಧ್ವನಿ ಸಹಾಯಕ (TTS)',
        '🌦️ ಸಿಂಪರಣೆ ಹವಾಮಾನ ಸೂಕ್ತತೆ (Spray Score)',
        '💰 ಹಣ ಮತ್ತು ಔಷಧ ಉಳಿತಾಯ (ROI)',
        '🗺️ ಆದ್ಯತಾ ವಲಯಗಳ ನಕ್ಷೆ (Zone A, B)',
        '🍃 ಜೈವಿಕ & ಸಾವಯವ ಕಳೆ ಪಾಕವಿಧಾನ',
        '📱 ಸುಲಭ ಮತ್ತು ವೇಗದ ಬಳಕೆ',
      ];
    } else if (lang == 'hi') {
      return [
        '🌿 सटीक खरपतवार व फसल पहचान',
        '🗣️ हिंदी वॉयस रिपोर्ट (TTS)',
        '🌦️ मौसम स्प्रे विंडो स्कोर',
        '💰 रसायन व पैसों की बचत (ROI)',
        '🗺️ प्राथमिकता ज़ोन नक्शा (Zone A, B)',
        '🍃 जैविक खरपतवार नुस्खे',
        '📱 सरल व तेज इंटरफेस',
      ];
    } else {
      return [
        '🌿 Accurate Crop & Weed Vision',
        '🗣️ Multilingual Voice Assistant',
        '🌦️ Spray Window Weather Score',
        '💰 Chemical & Money Savings (ROI)',
        '🗺️ Priority Zones Farmland Map',
        '🍃 Zero-Chemical Bio Recipes',
        '📱 Fast & Intuitive Design',
      ];
    }
  }

  Future<void> _submitFeedback(BuildContext context) async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final feedbackMsg = AppLocalizations.of(context).get('feedback_submitted');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('weedguard_user_rating', _selectedStars);
      await prefs.setStringList('weedguard_user_tags', _selectedExperiences.toList());
      if (_commentController.text.trim().isNotEmpty) {
        await prefs.setString('weedguard_user_comment', _commentController.text.trim());
      }
      await prefs.setString('weedguard_rating_date', DateTime.now().toIso8601String());
    } catch (_) {}

    if (!mounted) return;
    nav.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                feedbackMsg,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = l10n.locale.languageCode;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final options = _getExperienceOptions(lang);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('rate_our_app'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.get('rate_app_subtitle'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5C5C5C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE8F0E8)),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPad),
                children: [
                  // Star Rating Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFDE7), Color(0xFFFFF8E1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getStarTitle(lang, _selectedStars),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            final isFilled = starIndex <= _selectedStars;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedStars = starIndex),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: const Color(0xFFFFB300),
                                  size: 42,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang == 'kn'
                              ? 'ರೇಟ್ ಮಾಡಲು ನಕ್ಷತ್ರಗಳನ್ನು ಒತ್ತಿರಿ'
                              : (lang == 'hi' ? 'रेटिंग देने के लिए स्टार दबाएं' : 'Tap stars to rate'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8D6E63)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Experience Question
                  Text(
                    l10n.get('experience_question'),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Experience Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((opt) {
                      final isSelected = _selectedExperiences.contains(opt);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(opt),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF333333),
                        ),
                        backgroundColor: const Color(0xFFF5F5F5),
                        selectedColor: const Color(0xFFC8E6C9),
                        checkmarkColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
                          ),
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedExperiences.add(opt);
                            } else {
                              _selectedExperiences.remove(opt);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Additional Feedback Text Box
                  Text(
                    lang == 'kn'
                        ? 'ಹೆಚ್ಚುವರಿ ಅನಿಸಿಕೆ ಅಥವಾ ಸಲಹೆಗಳು (ಐಚ್ಛಿಕ):'
                        : (lang == 'hi' ? 'अतिरिक्त सुझाव या अनुभव (वैकल्पिक):' : 'Additional comments or suggestions (Optional):'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: lang == 'kn'
                          ? 'ನಿಮ್ಮ ಅನಿಸಿಕೆಯನ್ನು ಇಲ್ಲಿ ಬರೆಯಿರಿ...'
                          : (lang == 'hi' ? 'अपनी समीक्षा यहाँ लिखें...' : 'Write your review here...'),
                      hintStyle: const TextStyle(fontSize: 12.5, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _submitFeedback(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        l10n.get('submit_rating'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
