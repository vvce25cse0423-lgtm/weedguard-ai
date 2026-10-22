import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';

class AppUsageManualDialog extends StatelessWidget {
  const AppUsageManualDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppUsageManualDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = l10n.locale.languageCode;

    final List<_ManualStep> steps = _getManualSteps(lang);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
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
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF1B5E20),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('app_usage_manual'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.get('app_manual_subtitle'),
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

            // Steps List
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: step.bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: step.borderColor, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: step.accentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                step.stepLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(step.icon, size: 18, color: step.accentColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                step.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: step.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2C3E50),
                            height: 1.45,
                          ),
                        ),
                        if (step.tip != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: step.borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded, size: 15, color: step.accentColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    step.tip!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: step.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<_ManualStep> _getManualSteps(String lang) {
    if (lang == 'kn') {
      return const [
        _ManualStep(
          stepLabel: 'ಹಂತ ೧',
          title: 'ಹೊಲಗಳ ನೋಂದಣಿ & ಎಕರೆ ವಿಸ್ತೀರ್ಣ',
          icon: Icons.landscape_rounded,
          accentColor: Color(0xFF1B5E20),
          bgColor: Color(0xFFF1F8F1),
          borderColor: Color(0xFFC8E6C9),
          description: 'ನಿಮ್ಮ ಕೃಷಿ ಜಮೀನಿನ ಬೆಳೆ ಹಾಗೂ ವಿಸ್ತೀರ್ಣವನ್ನು "ಎಕರೆ" (Acres) ಗಳಲ್ಲಿ ಸೇರಿಸಿ. ಒಂದೇ ಬೆಳೆಯ ಚಿತ್ರಗಳನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿದಾಗ ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಅದೇ ಹೊಲದ ಫೋಲ್ಡರ್‌ನಲ್ಲಿ ಉಳಿಯುತ್ತದೆ.',
          tip: 'ಸಲಹೆ: ಹೊಲದ ವಿವರಗಳಲ್ಲಿ "Edit Acres" ಒತ್ತಿ ಎಕರೆ ವಿಸ್ತೀರ್ಣವನ್ನು ಯಾವಾಗ ಬೇಕಾದರೂ ಬದಲಾಯಿಸಬಹುದು.',
        ),
        _ManualStep(
          stepLabel: 'ಹಂತ ೨',
          title: 'ಕ್ಯಾಮೆರಾ ಸ್ಕ್ಯಾನ್ ಮತ್ತು ಕಳೆ ಗುರುತಿಸುವಿಕೆ',
          icon: Icons.camera_alt_rounded,
          accentColor: Color(0xFF1565C0),
          bgColor: Color(0xFFF0F4FA),
          borderColor: Color(0xFFBBDEFB),
          description: 'ಬೆಳೆ ಮತ್ತು ಕಳೆಗಳ ಸ್ಪಷ್ಟ ಫೋಟೋ ತೆಗೆಯಿರಿ ಅಥವಾ ಗ್ಯಾಲರಿಯಿಂದ ಆಯ್ಕೆಮಾಡಿ. ವೀಡ್‌ಗಾರ್ಡ್ AI ಬೆಳೆ ಹಾಗೂ ಪಾರ್ಥೇನಿಯಂ, ಭದ್ರಮುಷ್ಟಿ, ಅಮರಂಥಸ್‌ನಂತಹ ಅಪಾಯಕಾರಿ ಕಳೆಗಳನ್ನು ನಿಖರವಾಗಿ ಪತ್ತೆ ಮಾಡುತ್ತದೆ.',
          tip: 'ಸಲಹೆ: ಬೆಳಕಿರುವ ಸಮಯದಲ್ಲಿ ನೆಲದಿಂದ ೩೦-೫೦ ಸೆಂ.ಮೀ ಎತ್ತರದಿಂದ ಫೋಟೋ ತೆಗೆಯಿರಿ.',
        ),
        _ManualStep(
          stepLabel: 'ಹಂತ ೩',
          title: 'ವಲಯ ವಿಂಗಡಣೆ (Zone A, B, C...) & ಒಟ್ಟು ಆದ್ಯತಾ ವಲಯಗಳು',
          icon: Icons.grid_view_rounded,
          accentColor: Color(0xFFE65100),
          bgColor: Color(0xFFFFF8F0),
          borderColor: Color(0xFFFFE0B2),
          description: 'ಮೊದಲ ಸ್ಕ್ಯಾನ್ ವಲಯ A (Zone A), ನಂತರದ ಸ್ಕ್ಯಾನ್‌ಗಳು ವಲಯ B, C... ಆಗಿ ದಾಖಲಾಗುತ್ತವೆ. "View Field Zones" ನಲ್ಲಿ ನೈಜ ಫೋಟೋದ ಮೇಲೆಯೇ ಕಳೆ ಪೀಡಿತ ವಲಯವನ್ನು ನೋಡಬಹುದು. "Total Priority Zones" ಗುಂಡಿ ಒತ್ತಿ ಎಲ್ಲ ವಲಯಗಳ ಕಳೆ ಪ್ರಮಾಣದ ನಕ್ಷೆ ವೀಕ್ಷಿಸಿ.',
          tip: 'ಸಲಹೆ: ಅತಿ ಹೆಚ್ಚು ಕಳೆ ಇರುವ ವಲಯಕ್ಕೆ ಮೊದಲ ಆದ್ಯತೆ ನೀಡಿ ಸಿಂಪಡಿಸಿ.',
        ),
        _ManualStep(
          stepLabel: 'ಹಂತ ೪',
          title: 'ಸಸ್ಯನಾಶಕ ಮತ್ತು ಜೈವಿಕ (Eco-Bio) ಔಷಧಗಳು',
          icon: Icons.science_rounded,
          accentColor: Color(0xFF00695C),
          bgColor: Color(0xFFE0F2F1),
          borderColor: Color(0xFFB2DFDB),
          description: 'ಕಳೆ ಜಾತಿಯ ಆಧಾರದ ಮೇಲೆ ಶಿಫಾರಸು ಮಾಡಿದ ಔಷಧ, ಪ್ರಮಾಣ (ಲೀಟರ್‌ಗೆ) ತಿಳಿಯಿರಿ. ಜೊತೆಗೆ ವಿನೆಗರ್, ಉಪ್ಪು ಮತ್ತು ಬೇವಿನ ಎಣ್ಣೆಯ ರಾಸಾಯನಿಕ ಮುಕ್ತ ಜೈವಿಕ ಪಾಕವಿಧಾನಗಳನ್ನು ಬಳಸಿ.',
          tip: 'ಸಲಹೆ: ಸಾವಯವ ನಿಯಂತ್ರಣಕ್ಕಾಗಿ ಎಡೆಕುಂಟೆ ಹೊಡೆಯುವ ಸಮಯ ಹಾಗೂ ಒಣ ಹುಲ್ಲಿನ ಮಲ್ಚಿಂಗ್ ಅನುಸರಿಸಿ.',
        ),
        _ManualStep(
          stepLabel: 'ಹಂತ ೫',
          title: 'ಸಿಂಪರಣೆ ಹವಾಮಾನ ಸೂಕ್ತತೆ (Spray Window)',
          icon: Icons.wb_twilight_rounded,
          accentColor: Color(0xFFF57F17),
          bgColor: Color(0xFFFFFDE7),
          borderColor: Color(0xFFFFF59D),
          description: 'ಮೇಲಿನ ಹವಾಮಾನ ಐಕಾನ್ ಒತ್ತಿ ನಿಮ್ಮ ಊರಿನ ಗಾಳಿಯ ವೇಗ, ತಾಪಮಾನ ಮತ್ತು ಮಳೆ ಬರುವ ಸಮಯವನ್ನು ಪರಿಶೀಲಿಸಿ. ಸೂಕ್ತತೆಯ ಅಂಕ ೭೦% ಕ್ಕಿಂತ ಹೆಚ್ಚಿದ್ದಾಗ ಮಾತ್ರ ಸಿಂಪಡಿಸಿ.',
          tip: 'ಸಲಹೆ: ಬಿರುಗಾಳಿ ಅಥವಾ ತಕ್ಷಣ ಮಳೆ ಬರುವ ಸಂದರ್ಭದಲ್ಲಿ ಸಿಂಪರಣೆ ಮಾಡಬೇಡಿ.',
        ),
        _ManualStep(
          stepLabel: 'ಹಂತ ೬',
          title: 'ಹಣ ಮತ್ತು ರಾಸಾಯನಿಕ ಉಳಿತಾಯ (Precision ROI)',
          icon: Icons.currency_rupee_rounded,
          accentColor: Color(0xFF2E7D32),
          bgColor: Color(0xFFF1F8F1),
          borderColor: Color(0xFFC8E6C9),
          description: 'ಇಡೀ ಹೊಲಕ್ಕೆ ರಾಸಾಯನಿಕ ಚೆಲ್ಲುವ ಬದಲು ಕಳೆ ಇರುವಲ್ಲಿ ಮಾತ್ರ ನಿಖರ ಸಿಂಪರಣೆ ಮಾಡುವುದರಿಂದ ಪ್ರತಿ ಎಕರೆಗೆ ಉಳಿತಾಯವಾಗುವ ಹಣ (₹) ಮತ್ತು ಲೀಟರ್ ರಾಸಾಯನಿಕದ ಲೆಕ್ಕ ಪಡೆಯಿರಿ.',
        ),
        _ManualStep(
          stepLabel: 'ಹಂತ ೭',
          title: 'ಕನ್ನಡ ಧ್ವನಿ ಸಹಾಯಕ (Read Aloud)',
          icon: Icons.record_voice_over_rounded,
          accentColor: Color(0xFF6A1B9A),
          bgColor: Color(0xFFF3E5F5),
          borderColor: Color(0xFFE1BEE7),
          description: 'ಸ್ಕ್ಯಾನ್ ಫಲಿತಾಂಶದ ಪರದೆಯಲ್ಲಿ "Read Aloud" ಗುಂಡಿ ಒತ್ತಿ. ಸಂಪೂರ್ಣ ಕೃಷಿ ವರದಿ ಮತ್ತು ಔಷಧ ಸಿಂಪರಣಾ ಮಾಹಿತಿಯನ್ನು ಸ್ಪಷ್ಟ ಕನ್ನಡದಲ್ಲೇ ಆಲಿಸಬಹುದು.',
        ),
        _ManualStep(
          stepLabel: 'ಹಂತ ೮',
          title: '೭ ದಿನಗಳ ನಂತರ ಮರು ಸ್ಕ್ಯಾನ್ & ನಿರೋಧಕತೆ ಪರೀಕ್ಷೆ',
          icon: Icons.update_rounded,
          accentColor: Color(0xFFC62828),
          bgColor: Color(0xFFFFEBEE),
          borderColor: Color(0xFFFFCDD2),
          description: 'ಔಷಧ ಸಿಂಪಡಿಸಿದ ೭ ಮತ್ತು ೧೪ ದಿನಗಳ ನಂತರ ಮತ್ತೆ ಫೋಟೋ ತೆಗೆದು ಪರಿಶೀಲಿಸಿ. ಕಳೆಗಳು ಸತ್ತಿವೆಯೇ ಅಥವಾ ಆ ಔಷಧಕ್ಕೆ ತಡೆದುಕೊಳ್ಳುವ ಶಕ್ತಿ ಬೆಳೆಸಿಕೊಂಡಿವೆಯೇ ಎಂದು AI ಎಚ್ಚರಿಸುತ್ತದೆ.',
        ),
      ];
    } else if (lang == 'hi') {
      return const [
        _ManualStep(
          stepLabel: 'चरण 1',
          title: 'खेत जोड़ना और एकड़ में क्षेत्रफल दर्ज करना',
          icon: Icons.landscape_rounded,
          accentColor: Color(0xFF1B5E20),
          bgColor: Color(0xFFF1F8F1),
          borderColor: Color(0xFFC8E6C9),
          description: 'अपने खेत का नाम, फसल और आकार एकड़ (Acres) में दर्ज करें। एक ही फसल की तस्वीरें अपने आप उसी खेत फ़ोल्डर में सहेजी जाएंगी।',
          tip: 'सुझाव: खेत के विवरण में जाकर "Edit Acres" दबाकर कभी भी एकड़ क्षेत्रफल बदल सकते हैं।',
        ),
        _ManualStep(
          stepLabel: 'चरण 2',
          title: 'कैमरा स्कैन और खरपतवार की सटीक पहचान',
          icon: Icons.camera_alt_rounded,
          accentColor: Color(0xFF1565C0),
          bgColor: Color(0xFFF0F4FA),
          borderColor: Color(0xFFBBDEFB),
          description: 'फसल और खरपतवार की स्पष्ट तस्वीर खींचें या गैलरी से चुनें। वीडगार्ड AI फसल और मोथा, चौलाई, गाजर घास जैसे खरपतवारों की तुरंत पहचान करेगा।',
          tip: 'सुझाव: दिन की अच्छी रोशनी में 30-50 सेमी की ऊंचाई से तस्वीर लें।',
        ),
        _ManualStep(
          stepLabel: 'चरण 3',
          title: 'क्रमिक ज़ोन (Zone A, B, C...) और कुल प्राथमिकता ज़ोन',
          icon: Icons.grid_view_rounded,
          accentColor: Color(0xFFE65100),
          bgColor: Color(0xFFFFF8F0),
          borderColor: Color(0xFFFFE0B2),
          description: 'पहला स्कैन ज़ोन A (Zone A), दूसरा ज़ोन B, C बनेगा। "View Field Zones" में असली तस्वीर पर ज़ोन ओवरले देखें। "Total Priority Zones" दबाकर पूरे खेत का नक्शा देखें।',
          tip: 'सुझाव: जिस ज़ोन में सबसे ज्यादा खरपतवार हों, पहले वहां छिड़काव करें।',
        ),
        _ManualStep(
          stepLabel: 'चरण 4',
          title: 'रसायन और शून्य-रासायनिक जैविक (Eco-Bio) नुस्खे',
          icon: Icons.science_rounded,
          accentColor: Color(0xFF00695C),
          bgColor: Color(0xFFE0F2F1),
          borderColor: Color(0xFFB2DFDB),
          description: 'खरपतवार की प्रजाति अनुसार अनुशंसित दवा और प्रति लीटर खुराक जानें। साथ ही सिरका, नमक और नीम तेल के प्राकृतिक जैविक विकल्प अपनाएं।',
        ),
        _ManualStep(
          stepLabel: 'चरण 5',
          title: 'मौसम और स्प्रे विंडो स्कोर (Spray Window)',
          icon: Icons.wb_twilight_rounded,
          accentColor: Color(0xFFF57F17),
          bgColor: Color(0xFFFFFDE7),
          borderColor: Color(0xFFFFF59D),
          description: 'मौसम आइकन पर क्लिक करके हवा की गति, तापमान और बारिश की संभावना देखें। स्प्रे स्कोर 70% से अधिक होने पर ही दवा छिड़कें।',
          tip: 'सुझाव: तेज हवा या बारिश की संभावना में छिड़काव न करें।',
        ),
        _ManualStep(
          stepLabel: 'चरण 6',
          title: 'सटीक बचत और रासायनिक कमी (ROI Savings)',
          icon: Icons.currency_rupee_rounded,
          accentColor: Color(0xFF2E7D32),
          bgColor: Color(0xFFF1F8F1),
          borderColor: Color(0xFFC8E6C9),
          description: 'पूरे खेत में अंधाधुंध छिड़काव के बजाय सिर्फ प्रभावित जगहों पर स्पॉट स्प्रे करने से प्रति एकड़ पैसों (₹) और रसायन की बचत देखें।',
        ),
        _ManualStep(
          stepLabel: 'चरण 7',
          title: 'हिंदी वॉयस असिस्टेंट (बोलकर रिपोर्ट सुनें)',
          icon: Icons.record_voice_over_rounded,
          accentColor: Color(0xFF6A1B9A),
          bgColor: Color(0xFFF3E5F5),
          borderColor: Color(0xFFE1BEE7),
          description: 'स्कैन परिणाम स्क्रीन पर "Read Aloud" बटन दबाकर पूरी रिपोर्ट और दवा की सलाह अपनी भाषा हिंदी में सुनें।',
        ),
        _ManualStep(
          stepLabel: 'चरण 8',
          title: '7 दिन बाद पुनः स्कैन और प्रतिरोध अलर्ट',
          icon: Icons.update_rounded,
          accentColor: Color(0xFFC62828),
          bgColor: Color(0xFFFFEBEE),
          borderColor: Color(0xFFFFCDD2),
          description: 'छिड़काव के 7 व 14 दिन बाद दोबारा स्कैन करें। AI जांचेगा कि खरपतवार खत्म हुए या उनमें इस दवा के प्रति प्रतिरोधक क्षमता आ गई है।',
        ),
      ];
    }

    // Default English
    return const [
      _ManualStep(
        stepLabel: 'Step 1',
        title: 'Register Farm Plot & Set Acreage',
        icon: Icons.landscape_rounded,
        accentColor: Color(0xFF1B5E20),
        bgColor: Color(0xFFF1F8F1),
        borderColor: Color(0xFFC8E6C9),
        description: 'Add your farmland parcel and enter size in Acres. Back-to-back crop scans of the same crop automatically group under that dedicated field parcel folder.',
        tip: 'Tip: Tap "Edit Acres" anytime inside the field folder to update your acreage.',
      ),
      _ManualStep(
        stepLabel: 'Step 2',
        title: 'Camera AI Crop & Weed Scan',
        icon: Icons.camera_alt_rounded,
        accentColor: Color(0xFF1565C0),
        bgColor: Color(0xFFF0F4FA),
        borderColor: Color(0xFFBBDEFB),
        description: 'Take clear, well-lit photos of crops and surrounding weeds from 30–50 cm above canopy. WeedGuard AI identifies both the cultivated crop and exact weed species.',
        tip: 'Tip: Ensure good daylight and avoid strong camera blur for best accuracy.',
      ),
      _ManualStep(
        stepLabel: 'Step 3',
        title: 'Sequential Zones (Zone A, B, C...) & Parcel Sketch',
        icon: Icons.grid_view_rounded,
        accentColor: Color(0xFFE65100),
        bgColor: Color(0xFFFFF8F0),
        borderColor: Color(0xFFFFE0B2),
        description: 'Your 1st image becomes Zone A, 2nd becomes Zone B, Zone C... Tap "View Field Zones" to view the uploaded image with priority borders. Tap "Total Priority Zones" in the field folder to see a visual farmland sketch of all scanned points.',
        tip: 'Tip: Always treat high priority zones with the highest weed count first.',
      ),
      _ManualStep(
        stepLabel: 'Step 4',
        title: 'Certified Herbicides & Zero-Chemical Bio Recipes',
        icon: Icons.science_rounded,
        accentColor: Color(0xFF00695C),
        bgColor: Color(0xFFE0F2F1),
        borderColor: Color(0xFFB2DFDB),
        description: 'Access certified chemical recommendations with exact dose per litre, plus eco-friendly bio-herbicide recipes (acetic acid, rock salt, neem oil) and mechanical weeding schedules.',
      ),
      _ManualStep(
        stepLabel: 'Step 5',
        title: 'Spray-Window Weather Score',
        icon: Icons.wb_twilight_rounded,
        accentColor: Color(0xFFF57F17),
        bgColor: Color(0xFFFFFDE7),
        borderColor: Color(0xFFFFF59D),
        description: 'Tap the weather icon to view wind speed, temperature, and rain probability. Only apply spray treatments when the Optimal Spray Score is 70% or higher.',
        tip: 'Tip: Avoid spraying during high winds (>15 km/h) or before rain to prevent wash-off.',
      ),
      _ManualStep(
        stepLabel: 'Step 6',
        title: 'Precision ROI & Chemical Cost Savings',
        icon: Icons.currency_rupee_rounded,
        accentColor: Color(0xFF2E7D32),
        bgColor: Color(0xFFF1F8F1),
        borderColor: Color(0xFFC8E6C9),
        description: 'View financial audits contrasting blanket spraying with AI spot spraying, highlighting money saved (₹) and chemical volume reduction.',
      ),
      _ManualStep(
        stepLabel: 'Step 7',
        title: 'Multilingual Voice Assistant (Read Aloud)',
        icon: Icons.record_voice_over_rounded,
        accentColor: Color(0xFF6A1B9A),
        bgColor: Color(0xFFF3E5F5),
        borderColor: Color(0xFFE1BEE7),
        description: 'Tap "Read Aloud" on detection results to listen to diagnostic summaries, dosage, and safety instructions spoken clearly in your chosen language.',
      ),
      _ManualStep(
        stepLabel: 'Step 8',
        title: '7-Day Follow-Up Rescan & Resistance Alerts',
        icon: Icons.update_rounded,
        accentColor: Color(0xFFC62828),
        bgColor: Color(0xFFFFEBEE),
        borderColor: Color(0xFFFFCDD2),
        description: 'Rescan your field 7 and 14 days after treatment. The app verifies weed kill rate and issues immediate resistance warnings if weeds survive.',
      ),
    ];
  }
}

class _ManualStep {
  final String stepLabel;
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final String description;
  final String? tip;

  const _ManualStep({
    required this.stepLabel,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.description,
    this.tip,
  });
}
