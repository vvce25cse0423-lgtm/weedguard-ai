import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weedguard/shared/models/detection_result_model.dart';

class KrishiKendraService {
  static Future<void> sharePrescriptionToDealer({
    required WeedDetectionResult result,
    String? fieldName,
    String? cropType,
    double acreage = 1.0,
    String languageCode = 'en',
    String? dealerPhoneNumber,
  }) async {
    final weeds = result.detections.where((d) => !d.isCrop).map((d) => d.label).toSet().toList();
    final weedListStr = weeds.isNotEmpty ? weeds.join(', ') : 'Mixed Weeds';

    final buffer = StringBuffer();
    if (languageCode == 'kn') {
      buffer.writeln('🌱 *ಕೃಷಿ ಕೇಂದ್ರ / ಔಷಧ ವಿತರಕರಿಗೆ ವಿಚಾರಣೆ*');
      buffer.writeln('ನನ್ನ ಹೊಲದಲ್ಲಿ ವೀಡ್‌ಗಾರ್ಡ್ AI ಮೂಲಕ ಕಳೆ ಪತ್ತೆ ಮಾಡಲಾಗಿದೆ:');
      if (fieldName != null) buffer.writeln('• ಹೊಲ: $fieldName');
      if (cropType != null) buffer.writeln('• ಬೆಳೆ: $cropType');
      buffer.writeln('• ವಿಸ್ತೀರ್ಣ: $acreage ಎಕರೆ');
      buffer.writeln('• ಪತ್ತೆಯಾದ ಕಳೆಗಳು: $weedListStr');
      buffer.writeln('• ಒಟ್ಟು ಕಳೆಗಳ ಸಂಖ್ಯೆ: ${result.weedCount}');
      buffer.writeln('\nದಯವಿಟ್ಟು ಶಿಫಾರಸು ಮಾಡಿದ ಸೂಕ್ತ ಸಸ್ಯನಾಶಕ (Herbicide) ಬೆಲೆ ಮತ್ತು ಲಭ್ಯತೆಯನ್ನು ತಿಳಿಸಿ.');
      buffer.writeln('— WeedGuard AI ಕೃಷಿ ಸಹಾಯ ವ್ಯವಸ್ಥೆ');
    } else if (languageCode == 'hi') {
      buffer.writeln('🌱 *कृषि केंद्र / कीटनाशक डीलर पूछताछ*');
      buffer.writeln('मेरे खेत में वीडगार्ड AI द्वारा खरपतवार पाए गए हैं:');
      if (fieldName != null) buffer.writeln('• खेत: $fieldName');
      if (cropType != null) buffer.writeln('• फसल: $cropType');
      buffer.writeln('• रकबा: $acreage एकड़');
      buffer.writeln('• खरपतवार प्रजाति: $weedListStr');
      buffer.writeln('• कुल संख्या: ${result.weedCount}');
      buffer.writeln('\nकृपया अनुशंसित खरपतवारनाशक दवा की उपलब्धता और मूल्य की जानकारी दें।');
      buffer.writeln('— WeedGuard AI परिशुद्ध कृषि प्रणाली');
    } else {
      buffer.writeln('🌱 *Krishi Kendra / Agro-Dealer Herbicide Inquiry*');
      buffer.writeln('WeedGuard AI Field Scan Diagnostic:');
      if (fieldName != null) buffer.writeln('• Field Plot: $fieldName');
      if (cropType != null) buffer.writeln('• Target Crop: $cropType');
      buffer.writeln('• Field Area: $acreage Acre(s)');
      buffer.writeln('• Identified Weeds: $weedListStr');
      buffer.writeln('• Infestation Level: ${result.severity.name.toUpperCase()} (${result.weedCount} weeds detected)');
      buffer.writeln('\nPlease provide availability and pricing for the prescribed selective herbicides and required dilution stickers.');
      buffer.writeln('— Sent via WeedGuard AI System');
    }

    final message = buffer.toString();

    // Try direct WhatsApp URL if telephone is provided or generic WhatsApp link
    final phone = dealerPhoneNumber?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final Uri whatsappUri = phone.isNotEmpty
        ? Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}')
        : Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback to general Share
    await Share.share(
      message,
      subject: 'WeedGuard AI Herbicide Inquiry',
    );
  }
}
