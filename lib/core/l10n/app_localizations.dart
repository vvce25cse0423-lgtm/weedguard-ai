import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('kn'),
    Locale('hi'),
  ];

  static final Map<String, Map<String, String>> _strings = {
    // ── Common ──
    'app_name':        {'en': 'WeedGuard AI',     'kn': 'ವೀಡ್‌ಗಾರ್ಡ್ AI', 'hi': 'वीडगार्ड AI'},
    'tagline':         {'en': 'Healthier Crops · Higher Yields', 'kn': 'ಆರೋಗ್ಯಕರ ಬೆಳೆಗಳು · ಹೆಚ್ಚಿನ ಇಳುವರಿ', 'hi': 'स्वस्थ फसलें · अधिक उपज'},
    'save':            {'en': 'Save',    'kn': 'ಉಳಿಸಿ',   'hi': 'सहेजें'},
    'cancel':          {'en': 'Cancel',  'kn': 'ರದ್ದು',   'hi': 'रद्द करें'},
    'confirm':         {'en': 'Confirm', 'kn': 'ದೃಢೀಕರಿಸಿ', 'hi': 'पुष्टि करें'},
    'delete':          {'en': 'Delete',  'kn': 'ಅಳಿಸಿ',   'hi': 'हटाएं'},
    'loading':         {'en': 'Loading…', 'kn': 'ಲೋಡ್ ಆಗುತ್ತಿದೆ…', 'hi': 'लोड हो रहा है…'},
    'error':           {'en': 'Error',   'kn': 'ದೋಷ',     'hi': 'त्रुटि'},
    'retry':           {'en': 'Retry',   'kn': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ', 'hi': 'पुनः प्रयास करें'},
    'back':            {'en': 'Back',    'kn': 'ಹಿಂದೆ',   'hi': 'वापस'},
    'done':            {'en': 'Done',    'kn': 'ಮುಗಿದಿದೆ', 'hi': 'हो गया'},
    'yes':             {'en': 'Yes',     'kn': 'ಹೌದು',    'hi': 'हाँ'},
    'no':              {'en': 'No',      'kn': 'ಇಲ್ಲ',     'hi': 'नहीं'},

    // ── Navigation ──
    'nav_dashboard':   {'en': 'Dashboard', 'kn': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್', 'hi': 'डैशबोर्ड'},
    'nav_fields':      {'en': 'Fields',    'kn': 'ಹೊಲಗಳು',        'hi': 'खेत'},
    'nav_history':     {'en': 'History',   'kn': 'ಇತಿಹಾಸ',        'hi': 'इतिहास'},
    'nav_settings':    {'en': 'Settings',  'kn': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',  'hi': 'सेटिंग्स'},

    // ── Dashboard ──
    'dashboard_greeting_morning': {'en': 'Good Morning', 'kn': 'ಶುಭ ಬೆಳಿಗ್ಗೆ', 'hi': 'सुप्रभात'},
    'dashboard_greeting_afternoon':{'en': 'Good Afternoon','kn': 'ಶುಭ ಮಧ್ಯಾಹ್ನ','hi': 'नमस्ते'},
    'dashboard_greeting_evening': {'en': 'Good Evening',  'kn': 'ಶುಭ ಸಂಜೆ',   'hi': 'शुभ संध्या'},
    'dashboard_subtitle':  {'en': "Your farm's health overview", 'kn': 'ನಿಮ್ಮ ಜಮೀನಿನ ಆರೋಗ್ಯ ಅವಲೋಕನ', 'hi': 'आपके खेत का स्वास्थ्य अवलोकन'},
    'total_fields':    {'en': 'Total Fields', 'kn': 'ಒಟ್ಟು ಹೊಲಗಳು', 'hi': 'कुल खेत'},
    'total_scans':     {'en': 'Total Scans',  'kn': 'ಒಟ್ಟು ಸ್ಕ್ಯಾನ್',  'hi': 'कुल स्कैन'},
    'weeds_detected':  {'en': 'Weeds Detected','kn': 'ಕಳೆ ಪತ್ತೆ',   'hi': 'खरपतवार मिले'},
    'recent_scans':    {'en': 'Recent Scans',  'kn': 'ಇತ್ತೀಚಿನ ಸ್ಕ್ಯಾನ್', 'hi': 'हाल के स्कैन'},
    'scan_field':      {'en': 'Scan Field',    'kn': 'ಹೊಲ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ', 'hi': 'खेत स्कैन करें'},
    'view_all':        {'en': 'View All',      'kn': 'ಎಲ್ಲ ನೋಡಿ',       'hi': 'सभी देखें'},
    'no_recent_scans': {'en': 'No recent scans', 'kn': 'ಇತ್ತೀಚಿನ ಸ್ಕ್ಯಾನ್ ಇಲ್ಲ', 'hi': 'हाल के स्कैन नहीं'},

    // ── Fields ──
    'my_fields':       {'en': 'My Fields',     'kn': 'ನನ್ನ ಹೊಲಗಳು',   'hi': 'मेरे खेत'},
    'add_field':       {'en': 'Add field',     'kn': 'ಹೊಲ ಸೇರಿಸಿ',   'hi': 'खेत जोड़ें'},
    'no_fields_yet':   {'en': 'No fields yet', 'kn': 'ಯಾವುದೇ ಹೊಲಗಳಿಲ್ಲ', 'hi': 'अभी कोई खेत नहीं'},
    'no_fields_desc':  {'en': 'Add your first field to start scanning for weeds.',
                        'kn': 'ಕಳೆ ಸ್ಕ್ಯಾನ್ ಪ್ರಾರಂಭಿಸಲು ನಿಮ್ಮ ಮೊದಲ ಹೊಲ ಸೇರಿಸಿ.',
                        'hi': 'खरपतवार स्कैन शुरू करने के लिए अपना पहला खेत जोड़ें।'},
    'field_name':      {'en': 'Field Name',    'kn': 'ಹೊಲದ ಹೆಸರು',   'hi': 'खेत का नाम'},
    'field_size':      {'en': 'Field Size',    'kn': 'ಹೊಲದ ಗಾತ್ರ',   'hi': 'खेत का आकार'},
    'create_field':    {'en': 'Create Field',  'kn': 'ಹೊಲ ರಚಿಸಿ',    'hi': 'खेत बनाएं'},
    'field_info':      {'en': 'Field information', 'kn': 'ಹೊಲದ ಮಾಹಿತಿ', 'hi': 'खेत की जानकारी'},
    'location':        {'en': 'Location',          'kn': 'ಸ್ಥಳ',        'hi': 'स्थान'},
    'planting_details':{'en': 'Planting details',  'kn': 'ಬಿತ್ತನೆ ವಿವರಗಳು', 'hi': 'बुवाई का विवरण'},
    'area_hectares':   {'en': 'Area (hectares)',   'kn': 'ವಿಸ್ತೀರ್ಣ (ಹೆಕ್ಟೇರ್)', 'hi': 'क्षेत्रफल (हेक्टेयर)'},
    'location_label':  {'en': 'Location label or coordinates', 'kn': 'ಸ್ಥಳದ ವಿವರ ಅಥವಾ ನಿರ್ದೇಶಾಂಕಗಳು', 'hi': 'स्थान विवरण या निर्देशांक'},
    'planting_date':   {'en': 'Planting date',     'kn': 'ಬಿತ್ತನೆ ದಿನಾಂಕ', 'hi': 'बुवाई की तारीख'},
    'notes_optional':  {'en': 'Notes (optional)',  'kn': 'ಟಿಪ್ಪಣಿಗಳು (ಐಚ್ಛಿಕ)', 'hi': 'नोट्स (वैकल्पिक)'},
    'enter_field_name':{'en': 'Enter field name',  'kn': 'ಹೊಲದ ಹೆಸರು ನಮೂದಿಸಿ', 'hi': 'खेत का नाम दर्ज करें'},
    'enter_area':      {'en': 'Enter area in hectares', 'kn': 'ಹೆಕ್ಟೇರ್‌ನಲ್ಲಿ ವಿಸ್ತೀರ್ಣ ನಮೂದಿಸಿ', 'hi': 'हेक्टेयर में क्षेत्रफल दर्ज करें'},
    'select_date':     {'en': 'Select date',       'kn': 'ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ', 'hi': 'तारीख चुनें'},
    'add_notes_hint':  {'en': 'Add any additional notes…', 'kn': 'ಹೆಚ್ಚುವರಿ ಟಿಪ್ಪಣಿಗಳನ್ನು ಸೇರಿಸಿ…', 'hi': 'कोई अतिरिक्त नोट्स जोड़ें…'},
    'field_name_req':  {'en': 'Field name is required', 'kn': 'ಹೊಲದ ಹೆಸರು ಅಗತ್ಯವಿದೆ', 'hi': 'खेत का नाम आवश्यक है'},
    'save_field':      {'en': 'Save Field',        'kn': 'ಹೊಲ ಉಳಿಸಿ',    'hi': 'खेत सहेजें'},
    'save_changes':    {'en': 'Save Changes',      'kn': 'ಬದಲಾವಣೆಗಳನ್ನು ಉಳಿಸಿ', 'hi': 'बदलाव सहेजें'},
    'grow_better':     {'en': 'Grow better. Harvest smarter.', 'kn': 'ಉತ್ತಮ ಬೆಳೆ. ಬುದ್ಧಿವಂತ ಕೊಯ್ಲು.', 'hi': 'बेहतर उपज. स्मार्ट कटाई.'},

    // ── Scanner ──
    'scan_title':      {'en': 'Scan Field',       'kn': 'ಹೊಲ ಸ್ಕ್ಯಾನ್',        'hi': 'खेत स्कैन'},
    'take_photo':      {'en': 'Take Photo',        'kn': 'ಫೋಟೋ ತೆಗೆಯಿರಿ',       'hi': 'फोटो लें'},
    'choose_gallery':  {'en': 'Choose from Gallery','kn': 'ಗ್ಯಾಲರಿಯಿಂದ ಆಯ್ಕೆ',  'hi': 'गैलरी से चुनें'},
    'analyzing':       {'en': 'Analyzing image…',  'kn': 'ಚಿತ್ರ ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ…','hi': 'छवि विश्लेषण हो रहा है…'},
    'scan_again':      {'en': 'Scan Again',        'kn': 'ಮತ್ತೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',  'hi': 'फिर स्कैन करें'},

    // ── Detection Result ──
    'analysis_results':{'en': 'Analysis Results',  'kn': 'ವಿಶ್ಲೇಷಣೆ ಫಲಿತಾಂಶಗಳು', 'hi': 'विश्लेषण परिणाम'},
    'crop_identified': {'en': 'Crop Identified',   'kn': 'ಬೆಳೆ ಗುರುತಿಸಲಾಗಿದೆ',  'hi': 'फसल पहचानी गई'},
    'weeds_identified':{'en': 'Weeds Identified',  'kn': 'ಕಳೆಗಳು ಗುರುತಿಸಲಾಗಿದೆ','hi': 'खरपतवार पहचाने गए'},
    'herbicide_rec':   {'en': 'Recommended Herbicides','kn': 'ಶಿಫಾರಸು ಮಾಡಿದ ಸಸ್ಯನಾಶಕಗಳು','hi': 'अनुशंसित शाकनाशक'},
    'no_weeds':        {'en': 'No weeds detected in this scan.','kn': 'ಈ ಸ್ಕ್ಯಾನ್‌ನಲ್ಲಿ ಕಳೆ ಕಂಡುಬಂದಿಲ್ಲ.','hi': 'इस स्कैन में कोई खरपतवार नहीं मिली।'},
    'weed_count':      {'en': 'Weeds',    'kn': 'ಕಳೆ',    'hi': 'खरपतवार'},
    'confidence':      {'en': 'Confidence','kn': 'ವಿಶ್ವಾಸ', 'hi': 'विश्वास'},
    'severity':        {'en': 'Severity',  'kn': 'ತೀವ್ರತೆ', 'hi': 'गंभीरता'},
    'low':             {'en': 'Low',       'kn': 'ಕಡಿಮೆ',  'hi': 'कम'},
    'moderate':        {'en': 'Moderate',  'kn': 'ಮಧ್ಯಮ',  'hi': 'मध्यम'},
    'high':            {'en': 'High',      'kn': 'ಹೆಚ್ಚು',  'hi': 'अधिक'},
    'herbicide':       {'en': 'Herbicide', 'kn': 'ಸಸ್ಯನಾಶಕ','hi': 'शाकनाशक'},
    'dose':            {'en': 'Dose',      'kn': 'ಡೋಸ್',   'hi': 'खुराक'},
    'type':            {'en': 'Type',      'kn': 'ಪ್ರಕಾರ',  'hi': 'प्रकार'},
    'weed_col':        {'en': 'Weed',      'kn': 'ಕಳೆ',    'hi': 'खरपतवार'},
    'safety_note':     {'en': 'Always wear protective gear. Apply during calm weather. Follow label instructions and local regulations.',
                        'kn': 'ಯಾವಾಗಲೂ ರಕ್ಷಣಾ ಸಾಧನಗಳನ್ನು ಧರಿಸಿ. ಶಾಂತ ವಾತಾವರಣದಲ್ಲಿ ಅನ್ವಯಿಸಿ.',
                        'hi': 'हमेशा सुरक्षात्मक गियर पहनें। शांत मौसम में लगाएं।'},
    'view_field_zones':{'en': 'View Field Zones', 'kn': 'ಹೊಲದ ವಲಯಗಳು ನೋಡಿ', 'hi': 'खेत क्षेत्र देखें'},
    'instances':       {'en': 'instances', 'kn': 'ನಿದರ್ಶನಗಳು', 'hi': 'उदाहरण'},
    'instance':        {'en': 'instance',  'kn': 'ನಿದರ್ಶನ',    'hi': 'उदाहरण'},

    // ── History ──
    'scan_history':    {'en': 'Scan History', 'kn': 'ಸ್ಕ್ಯಾನ್ ಇತಿಹಾಸ', 'hi': 'स्कैन इतिहास'},
    'no_history':      {'en': 'No scan history yet', 'kn': 'ಯಾವುದೇ ಸ್ಕ್ಯಾನ್ ಇತಿಹಾಸವಿಲ್ಲ', 'hi': 'अभी कोई स्कैन इतिहास नहीं'},

    // ── Settings ──
    'settings':        {'en': 'Settings',      'kn': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು', 'hi': 'सेटिंग्स'},
    'account':         {'en': 'Account',       'kn': 'ಖಾತೆ',           'hi': 'खाता'},
    'profile':         {'en': 'Profile',       'kn': 'ಪ್ರೊಫೈಲ್',       'hi': 'प्रोफ़ाइल'},
    'application':     {'en': 'Application',   'kn': 'ಅಪ್ಲಿಕೇಶನ್',     'hi': 'एप्लिकेशन'},
    'notifications':   {'en': 'Notifications', 'kn': 'ಅಧಿಸೂಚನೆಗಳು',   'hi': 'सूचनाएं'},
    'language':        {'en': 'Language',      'kn': 'ಭಾಷೆ',           'hi': 'भाषा'},
    'dark_mode':       {'en': 'Dark Mode',     'kn': 'ಡಾರ್ಕ್ ಮೋಡ್',   'hi': 'डार्क मोड'},
    'units':           {'en': 'Units',         'kn': 'ಘಟಕಗಳು',         'hi': 'इकाइयाँ'},
    'metric':          {'en': 'Metric',        'kn': 'ಮೆಟ್ರಿಕ್',       'hi': 'मेट्रिक'},
    'about':           {'en': 'About',         'kn': 'ನಮ್ಮ ಬಗ್ಗೆ',     'hi': 'के बारे में'},
    'privacy_policy':  {'en': 'Privacy Policy','kn': 'ಗೌಪ್ಯತಾ ನೀತಿ', 'hi': 'गोपनीयता नीति'},
    'app_version':     {'en': 'App Version',   'kn': 'ಆ್ಯಪ್ ಆವೃತ್ತಿ', 'hi': 'ऐप संस्करण'},
    'sign_out':        {'en': 'Sign out',      'kn': 'ಸೈನ್ ಔಟ್',      'hi': 'साइन आउट'},
    'sign_out_confirm':{'en': 'Sign out?',     'kn': 'ಸೈನ್ ಔಟ್ ಆಗಬೇಕೇ?','hi': 'साइन आउट करें?'},
    'sign_out_msg':    {'en': 'You will need to sign in again to access your data.',
                        'kn': 'ನಿಮ್ಮ ಡೇಟಾ ಪ್ರವೇಶಿಸಲು ಮತ್ತೆ ಸೈನ್ ಇನ್ ಮಾಡಬೇಕಾಗುತ್ತದೆ.',
                        'hi': 'अपना डेटा एक्सेस करने के लिए आपको फिर से साइन इन करना होगा।'},
    'select_language': {'en': 'Select Language','kn': 'ಭಾಷೆ ಆಯ್ಕೆ ಮಾಡಿ','hi': 'भाषा चुनें'},
    'english':         {'en': 'English',       'kn': 'ಇಂಗ್ಲಿಷ್',      'hi': 'अंग्रेज़ी'},
    'kannada':         {'en': 'Kannada',       'kn': 'ಕನ್ನಡ',          'hi': 'कन्नड़'},
    'hindi':           {'en': 'Hindi',         'kn': 'ಹಿಂದಿ',          'hi': 'हिंदी'},

    // ── Splash ──
    'loading_farm':    {'en': 'Loading your farm…', 'kn': 'ನಿಮ್ಮ ಜಮೀನು ಲೋಡ್ ಆಗುತ್ತಿದೆ…', 'hi': 'आपका खेत लोड हो रहा है…'},
    'login_title':     {'en': 'Sign In',   'kn': 'ಸೈನ್ ಇನ್',  'hi': 'साइन इन करें'},
    // ── Agronomy & Detection Results ──
    'crop_name':       {'en': 'Crop Name',     'kn': 'ಬೆಳೆಯ ಹೆಸರು',    'hi': 'फसल का नाम'},
    'weed_name':       {'en': 'Weed Name',     'kn': 'ಕಳೆಯ ಹೆಸರು',     'hi': 'खरपतवार का नाम'},
    'weed_names_detected': {'en': 'Weed Name(s) Detected', 'kn': 'ಪತ್ತೆಯಾದ ಕಳೆಗಳ ಹೆಸರು', 'hi': 'पहचाने गए खरपतवार'},
    'infestation_level':{'en': 'Infestation Level', 'kn': 'ಕಳೆ ಹರಡುವಿಕೆ ಮಟ್ಟ', 'hi': 'खरपतवार संक्रमण स्तर'},
    'herbicides_name': {'en': 'Herbicides Name', 'kn': 'ಶಿಫಾರಸು ಸಸ್ಯನಾಶಕ ಹೆಸರು', 'hi': 'अनुशंसित शाकनाशक'},
    'buy_herbicide_online': {'en': 'Buy Herbicide Online', 'kn': 'ಸಸ್ಯನಾಶಕವನ್ನು ಆನ್‌ಲೈನ್‌ ಖರೀದಿಸಿ', 'hi': 'ऑनलाइन शाकनाशक खरीदें'},
    'total_weeds_detected': {'en': 'Total Weeds Detected', 'kn': 'ಒಟ್ಟು ಪತ್ತೆಯಾದ ಕಳೆಗಳು', 'hi': 'कुल पहचाने गए खरपतवार'},
    'crop_field_protected': {'en': 'Field Protected', 'kn': 'ರಕ್ಷಿತ ಬೆಳೆ', 'hi': 'संरक्षित फसल'},
    'no_weeds_clean':  {'en': 'No weeds detected - Clean crop', 'kn': 'ಯಾವುದೇ ಕಳೆಗಳಿಲ್ಲ - ಸ್ವಚ್ಛ ಬೆಳೆ', 'hi': 'कोई खरपतवार नहीं - स्वच्छ फसल'},
    'priority_treatment_zone': {'en': 'High Priority Treatment Zone', 'kn': 'ಹೆಚ್ಚಿನ ಆದ್ಯತೆಯ ಚಿಕಿತ್ಸಾ ವಲಯ', 'hi': 'उच्च प्राथमिकता उपचार क्षेत्र'},

    // ── Precision ROI & Savings ──
    'precision_roi_savings': {'en': 'Precision ROI & Savings', 'kn': 'ನಿಖರ ಹೂಡಿಕೆ ಮೌಲ್ಯ & ಉಳಿತಾಯ', 'hi': 'सटीक निवेश लाभ और बचत'},
    'roi_savings_badge':     {'en': 'SAVINGS', 'kn': 'ಉಳಿತಾಯ', 'hi': 'बचत'},
    'roi_saved_per_acre':    {'en': 'saved per acre via Spot Spraying', 'kn': 'ಸ್ಪಾಟ್ ಸಿಂಪರಣೆಯಿಂದ ಪ್ರತಿ ಎಕರೆಗೆ ಉಳಿತಾಯ', 'hi': 'स्पॉट छिड़काव से प्रति एकड़ बचत'},
    'traditional_spray':     {'en': 'Traditional Blanket Spray', 'kn': 'ಸಾಂಪ್ರದಾಯಿಕ ಪೂರ್ಣ ಸಿಂಪರಣೆ', 'hi': 'पारंपरिक पूर्ण छिड़काव'},
    'weedguard_spot_spray':  {'en': 'WeedGuard Spot Spray', 'kn': 'ವೀಡ್‌ಗಾರ್ಡ್ ನಿಖರ ಸ್ಪಾಟ್ ಸಿಂಪರಣೆ', 'hi': 'वीडगार्ड सटीक स्पॉट छिड़काव'},
    'water_saved_label':     {'en': 'water saved', 'kn': 'ನೀರಿನ ಉಳಿತಾಯ', 'hi': 'पानी की बचत'},
    'less_soil_residue':     {'en': '70% less soil chemical residue', 'kn': '೭೦% ಕಡಿಮೆ ಮಣ್ಣಿನ ರಾಸಾಯನಿಕ ಶೇಷ', 'hi': '70% कम रासायनिक अवशेष'},
    'chemical':              {'en': 'chemical', 'kn': 'ರಾಸಾಯನಿಕ', 'hi': 'रसायन'},

    // ── Zero Chemical Bio & Organic Solutions ──
    'zero_chemical_bio':     {'en': 'Zero-Chemical Bio & Organic Solutions', 'kn': 'ರಾಸಾಯನಿಕ ಮುಕ್ತ ಸಾವಯವ & ಜೈವಿಕ ನಿಯಂತ್ರಣ', 'hi': 'शून्य-रासायनिक जैविक एवं प्राकृतिक उपचार'},
    'bio_subtitle':          {'en': 'Eco-friendly alternatives & non-toxic management', 'kn': 'ಪರಿಸರಸ್ನೇಹಿ ಪರ್ಯಾಯಗಳು ಮತ್ತು ನೈಸರ್ಗಿಕ ಕಳೆ ನಿರ್ವಹಣೆ', 'hi': 'पर्यावरण-अनुकूल विकल्प एवं गैर-विषाक्त खरपतवार प्रबंधन'},
    'eco_mode':              {'en': 'ECO MODE', 'kn': 'ಪರಿಸರ ಮೋಡ್', 'hi': 'इको मोड'},
    'natural_bio_herbicide': {'en': 'Natural Contact Bio-Herbicide', 'kn': 'ನೈಸರ್ಗಿಕ ಸಂಪರ್ಕ ಜೈವಿಕ ಸಸ್ಯನಾಶಕ', 'hi': 'प्राकृतिक संपर्क बायो-हर्बिसाइड'},
    'natural_bio_detail':    {'en': 'Mix 1 Litre White Vinegar (20% Acetic Acid) + 100g Rock Salt + 20ml Lemon/Neem Oil. Spray directly on weed leaves during bright sun at noon for instant foliar desiccation.',
                              'kn': '೧ ಲೀಟರ್ ಬಿಳಿ ವಿನೆಗರ್ (೨೦% ಅಸಿಟಿಕ್ ಆಮ್ಲ) + ೧೦೦ ಗ್ರಾಂ ಕಲ್ಲುಪ್ಪು + ೨೦ ಮಿ.ಲೀ ಬೇವಿನ ಎಣ್ಣೆ ಮಿಶ್ರಣ ಮಾಡಿ. ಮಧ್ಯಾಹ್ನದ ಬಿಸಿಲಿನಲ್ಲಿ ಕಳೆ ಎಲೆಗಳ ಮೇಲೆ ನೇರವಾಗಿ ಸಿಂಪಡಿಸಿ.',
                              'hi': '1 लीटर सफेद सिरका + 100 ग्राम सेंधा नमक + 20 मिली नीम का तेल मिलाएं। दोपहर की तेज धूप में खरपतवार की पत्तियों पर सीधे छिड़कें।'},
    'certified_organic':     {'en': 'Certified Organic', 'kn': 'ಪ್ರಮಾಣೀಕೃತ ಸಾವಯವ', 'hi': 'प्रमाणित जैविक'},
    'mechanical_cultivation':{'en': 'Mechanical Inter-Cultivation', 'kn': 'ಯಾಂತ್ರಿಕ ಎಡೆಕುಂಟೆ ಕಳೆ ನಿರ್ವಹಣೆ', 'hi': 'यांत्रिक निराई-गुड़ाई'},
    'mechanical_detail':     {'en': 'Use twin-wheel hand hoe or shallow blade harrow at 15–20 days after crop emergence. Cut weeds at crown level before seed setting to deplete root carbohydrates.',
                              'kn': 'ಬೆಳೆ ಬಂದ ೧೫-೨೦ ದಿನಗಳಲ್ಲಿ ಕೈ ಕುಂಟೆ ಅಥವಾ ವೀಡರ್ ಬಳಸಿ. ಬೀಜ ಕಟ್ಟುವ ಮೊದಲೇ ಕಳೆಗಳ ಬೇರುಗಳನ್ನು ತೆಗೆದುಹಾಕಿ.',
                              'hi': 'फसल उगने के 15-20 दिनों के बाद व्हील हो या वीडर का उपयोग करें। बीज बनने से पहले खरपतवार की जड़ों को नष्ट करें।'},
    'physical_control':      {'en': 'Physical Control', 'kn': 'ಭೌತಿಕ ನಿಯಂತ್ರಣ', 'hi': 'भौतिक नियंत्रण'},
    'bio_mulching':          {'en': 'Bio-Mulching & Shading', 'kn': 'ಜೈವಿಕ ಹೊದಿಕೆ & ಮಣ್ಣು ರಕ್ಷಣೆ (ಮಲ್ಚಿಂಗ್)', 'hi': 'बायो-मल्चिंग एवं छाया'},
    'bio_mulching_detail':   {'en': 'Apply 8–10 cm dry paddy straw or sugarcane trash mulch between crop rows. Prevents sunlight penetration (zero weed germination) and conserves 35% soil moisture.',
                              'kn': 'ಸಾಲುಗಳ ನಡುವೆ ಒಣ ಹುಲ್ಲು ಅಥವಾ ಕಬ್ಬಿನ ರವದಿಯ ೮-೧೦ ಸೆಂ.ಮೀ ಹೊದಿಕೆ ಹಾಕಿ. ಸೂರ್ಯನ ಬೆಳಕು ತಡೆದು ಕಳೆ ಮೊಳಕೆಯಾಗುವುದನ್ನು ನಿಲ್ಲಿಸುತ್ತದೆ ಮತ್ತು ತೇವಾಂಶ ಉಳಿಸುತ್ತದೆ.',
                              'hi': 'फसल की कतारों के बीच 8-10 सेमी सूखी पुआल या पत्तों की मल्चिंग लगाएं। यह धूप रोककर खरपतवार उगने से रोकता है और नमी बनाए रखता है।'},
    'moisture_saver':        {'en': 'Moisture Saver', 'kn': 'ತೇವಾಂಶ ಸಂರಕ್ಷಕ', 'hi': 'नमी संरक्षक'},

    // ── Herbicide Resistance Warning ──
    'herbicide_resistance_warning': {'en': 'Herbicide Resistance Warning', 'kn': 'ಸಸ್ಯನಾಶಕ ನಿರೋಧಕತೆ ಎಚ್ಚರಿಕೆ', 'hi': 'शाकनाशी प्रतिरोधक चेतावनी'},
    'post_spray_tracker':    {'en': 'Post-Spray Mortality Tracker', 'kn': 'ಸಿಂಪರಣೆ ನಂತರದ ಕಳೆ ನಿರ್ಮೂಲನೆ ಟ್ರ್ಯಾಕರ್', 'hi': 'छिड़काव बाद खरपतवार नियंत्रण ट्रैकर'},
    'followup_audit':        {'en': 'Follow-up Efficacy Audit', 'kn': 'ದಕ್ಷತೆ ಪರಿಶೀಲನಾ ಲೆಕ್ಕಪರಿಶೋಧನೆ', 'hi': 'प्रभावशीलता ऑडिट'},
    'eradicated_badge':      {'en': 'ERADICATED', 'kn': 'ನಿರ್ಮೂಲನೆ', 'hi': 'नष्ट'},
    'initial_scan':          {'en': 'Initial Scan', 'kn': 'ಆರಂಭಿಕ ಸ್ಕ್ಯಾನ್', 'hi': 'प्रारंभिक स्कैन'},
    'rescan':                {'en': 'Rescan', 'kn': 'ಮರು ಸ್ಕ್ಯಾನ್', 'hi': 'पुनः स्कैन'},
    'weeds_remaining':       {'en': 'Weeds Remaining', 'kn': 'ಉಳಿದಿರುವ ಕಳೆಗಳು', 'hi': 'शेष खरपतवार'},
    'resistance_alert_msg':  {'en': 'Low weed mortality detected. Weeds may have developed tolerance to the active ingredient. Switch to an alternative Mode of Action (MoA) herbicide group.',
                              'kn': 'ಕಡಿಮೆ ಕಳೆ ನಿರ್ಮೂಲನೆ ಪತ್ತೆಯಾಗಿದೆ! ಕಳೆಗಳು ಈ ರಾಸಾಯನಿಕಕ್ಕೆ ನಿರೋಧಕತೆ ಬೆಳೆಸಿಕೊಂಡಿರಬಹುದು. ಪರ್ಯಾಯ ಸಸ್ಯನಾಶಕ ಗುಂಪನ್ನು (HRAC MoA) ಬಳಸಿ ಅಥವಾ ಯಾಂತ್ರಿಕವಾಗಿ ತೆಗೆಯಿರಿ.',
                              'hi': 'कम खरपतवार नियंत्रण मिला। खरपतवारों में इस रसायन के प्रति सहनशीलता आ सकती है। वैकल्पिक रासायनिक समूह (MoA) अपनाएं।'},
    'efficacy_success_msg':  {'en': 'Excellent treatment efficacy. Weed population has been drastically reduced with healthy crop recovery.',
                              'kn': 'ಉತ್ತಮ ಕಳೆ ನಿಯಂತ್ರಣ ಫಲಿತಾಂಶ. ಕಳೆಗಳು ಗಣನೀಯವಾಗಿ ಕಡಿಮೆಯಾಗಿದ್ದು ಬೆಳೆ ಆರೋಗ್ಯಕರವಾಗಿ ಚೇತರಿಸಿಕೊಳ್ಳುತ್ತಿದೆ.',
                              'hi': 'उत्कृष्ट उपचार परिणाम। खरपतवारों की संख्या बहुत कम हो गई है और फसल स्वस्थ है।'},
  };

  String get(String key) {
    final lang = locale.languageCode;
    return _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;
  }

  // Convenience getters
  String get appName => get('app_name');
  String get tagline => get('tagline');
  String get save => get('save');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get delete => get('delete');
  String get loading => get('loading');
  String get error => get('error');
  String get retry => get('retry');
  String get back => get('back');
  String get done => get('done');
  String get navDashboard => get('nav_dashboard');
  String get navFields => get('nav_fields');
  String get navHistory => get('nav_history');
  String get navSettings => get('nav_settings');
  String get myFields => get('my_fields');
  String get addField => get('add_field');
  String get noFieldsYet => get('no_fields_yet');
  String get noFieldsDesc => get('no_fields_desc');
  String get fieldName => get('field_name');
  String get fieldSize => get('field_size');
  String get cropType => get('crop_type');
  String get scanTitle => get('scan_title');
  String get takePhoto => get('take_photo');
  String get chooseGallery => get('choose_gallery');
  String get analyzing => get('analyzing');
  String get scanAgain => get('scan_again');
  String get analysisResults => get('analysis_results');
  String get cropIdentified => get('crop_identified');
  String get weedsIdentified => get('weeds_identified');
  String get herbicideRec => get('herbicide_rec');
  String get noWeeds => get('no_weeds');
  String get confidence => get('confidence');
  String get severity => get('severity');
  String get low => get('low');
  String get moderate => get('moderate');
  String get high => get('high');
  String get herbicide => get('herbicide');
  String get dose => get('dose');
  String get type => get('type');
  String get weedCol => get('weed_col');
  String get safetyNote => get('safety_note');
  String get viewFieldZones => get('view_field_zones');
  String get scanHistory => get('scan_history');
  String get noHistory => get('no_history');
  String get settings => get('settings');
  String get account => get('account');
  String get profile => get('profile');
  String get application => get('application');
  String get notifications => get('notifications');
  String get language => get('language');
  String get darkMode => get('dark_mode');
  String get units => get('units');
  String get metric => get('metric');
  String get about => get('about');
  String get privacyPolicy => get('privacy_policy');
  String get appVersion => get('app_version');
  String get signOut => get('sign_out');
  String get signOutConfirm => get('sign_out_confirm');
  String get signOutMsg => get('sign_out_msg');
  String get selectLanguage => get('select_language');
  String get english => get('english');
  String get kannada => get('kannada');
  String get hindi => get('hindi');
  String get loadingFarm => get('loading_farm');
  String get loginTitle => get('login_title');
  String get email => get('email');
  String get password => get('password');
  String get totalFields => get('total_fields');
  String get totalScans => get('total_scans');
  String get weedsDetected => get('weeds_detected');
  String get recentScans => get('recent_scans');
  String get scanField => get('scan_field');
  String get viewAll => get('view_all');
  String get noRecentScans => get('no_recent_scans');
  String get fieldInfo => get('field_info');
  String get locationText => get('location');
  String get plantingDetails => get('planting_details');
  String get areaHectares => get('area_hectares');
  String get locationLabel => get('location_label');
  String get plantingDate => get('planting_date');
  String get notesOptional => get('notes_optional');
  String get enterFieldName => get('enter_field_name');
  String get enterArea => get('enter_area');
  String get selectDate => get('select_date');
  String get addNotesHint => get('add_notes_hint');
  String get fieldNameReq => get('field_name_req');
  String get saveField => get('save_field');
  String get saveChanges => get('save_changes');
  String get growBetter => get('grow_better');

  String translateCrop(String? cropName) {
    if (cropName == null || cropName.trim().isEmpty) return cropName ?? '';
    final lang = locale.languageCode;
    if (lang == 'en') return cropName;

    final lower = cropName.toLowerCase();
    if (lower.contains('tomato')) {
      return lang == 'kn' ? 'ಟೊಮ್ಯಾಟೊ (Tomato)' : 'टमाटर (Tomato)';
    }
    if (lower.contains('paddy') || lower.contains('rice') || lower.contains('oryza')) {
      return lang == 'kn' ? 'ಭತ್ತ (Paddy/Rice)' : 'धान / चावल (Paddy)';
    }
    if (lower.contains('wheat') || lower.contains('triticum')) {
      return lang == 'kn' ? 'ಗೋಧಿ (Wheat)' : 'गेहूं (Wheat)';
    }
    if (lower.contains('cotton') || lower.contains('gossypium')) {
      return lang == 'kn' ? 'ಹತ್ತಿ (Cotton)' : 'कपास (Cotton)';
    }
    if (lower.contains('maize') || lower.contains('corn') || lower.contains('zea')) {
      return lang == 'kn' ? 'ಮೆಕ್ಕೆಜೋಳ (Corn/Maize)' : 'मक्का (Maize)';
    }
    if (lower.contains('sugarcane')) {
      return lang == 'kn' ? 'ಕಬ್ಬು (Sugarcane)' : 'गन्ना (Sugarcane)';
    }
    if (lower.contains('soybean') || lower.contains('soya') || lower.contains('glycine')) {
      return lang == 'kn' ? 'ಸೋಯಾಬೀನ್ (Soybean)' : 'सोयाबीन (Soybean)';
    }
    if (lower.contains('potato') || lower.contains('tuberosum')) {
      return lang == 'kn' ? 'ಆಲೂಗಡ್ಡೆ (Potato)' : 'आलू (Potato)';
    }
    if (lower.contains('chilli') || lower.contains('chili') || lower.contains('pepper')) {
      return lang == 'kn' ? 'ಮೆಣಸಿನಕಾಯಿ (Chilli)' : 'मिर्च (Chilli)';
    }
    if (lower.contains('onion')) {
      return lang == 'kn' ? 'ಈರುಳ್ಳಿ (Onion)' : 'प्याज (Onion)';
    }
    if (lower.contains('groundnut') || lower.contains('peanut')) {
      return lang == 'kn' ? 'ಕಡಲೆಕಾಯಿ (Groundnut)' : 'मूंगफली (Groundnut)';
    }
    if (lower.contains('field crop') || lower.contains('agricultural') || lower.contains('crop field') || lower.contains('cultivation')) {
      return lang == 'kn' ? 'ಕೃಷಿ ಹೊಲದ ಬೆಳೆ (Field Crop)' : 'कृषि खेत की फसल (Field Crop)';
    }

    return cropName;
  }

  String translateWeed(String weedName) {
    if (weedName.trim().isEmpty) return weedName;
    final lang = locale.languageCode;
    if (lang == 'en') return weedName;

    final lower = weedName.toLowerCase();
    if (lower.contains('amaranthus') || lower.contains('pigweed') || lower.contains('chaulai') || lower.contains('amaranth')) {
      return lang == 'kn' ? 'ದಂಟು / ಕಳೆ ಹರಿವೆ (Amaranthus/Pigweed)' : 'चौलाई / अमरंथस (Amaranthus)';
    }
    if (lower.contains('cyperus') || lower.contains('nutgrass') || lower.contains('sedge') || lower.contains('motha') || lower.contains('nutsedge')) {
      return lang == 'kn' ? 'ಭದ್ರಮುಷ್ಟಿ / ಜೇಕು (Nutgrass/Cyperus)' : 'मोथा / साइपरस (Nutgrass)';
    }
    if (lower.contains('parthenium') || lower.contains('congress') || lower.contains('carrot grass') || lower.contains('gajjar')) {
      return lang == 'kn' ? 'ಕಾಂಗ್ರೆಸ್ ಹುಲ್ಲು / ಪಾರ್ಥೇನಿಯಂ (Parthenium)' : 'गाजर घास / पार्थेनियम (Parthenium)';
    }
    if (lower.contains('echinochloa') || lower.contains('barnyard') || lower.contains('jungle rice') || lower.contains('shama')) {
      return lang == 'kn' ? 'ಕಾಡು ಭತ್ತ / ಜಾವಡೆ ಹುಲ್ಲು (Barnyard Grass)' : 'सांवा घास (Barnyard Grass)';
    }
    if (lower.contains('cynodon') || lower.contains('bermuda') || lower.contains('hariali') || lower.contains('dub') || lower.contains('doob')) {
      return lang == 'kn' ? 'ಗರಿಕೆ ಹುಲ್ಲು (Bermuda Grass)' : 'दूब घास (Bermuda Grass)';
    }
    if (lower.contains('digitaria') || lower.contains('crabgrass')) {
      return lang == 'kn' ? 'ಏಡಿ ಹುಲ್ಲು (Crabgrass)' : 'केकड़ा घास / क्रेबग्रास (Crabgrass)';
    }
    if (lower.contains('convolvulus') || lower.contains('bindweed') || lower.contains('hiran')) {
      return lang == 'kn' ? 'ಬಳ್ಳಿ ಕಳೆ (Field Bindweed)' : 'हिरनखुरी (Field Bindweed)';
    }
    if (lower.contains('chenopodium') || lower.contains('bathua') || lower.contains('lambsquarters') || lower.contains('lambs')) {
      return lang == 'kn' ? 'ಬಾತುವಾ / ಕಾಡು ಪಾಲಕ್ (Bathua)' : 'बथुआ (Bathua/Lambsquarters)';
    }
    if (lower.contains('solanum') || lower.contains('nightshade') || lower.contains('makoi')) {
      return lang == 'kn' ? 'ಕಾಡು ಕಾಗೆಹಣ್ಣು (Black Nightshade)' : 'मकोय (Black Nightshade)';
    }
    if (lower.contains('eleusine') || lower.contains('goosegrass')) {
      return lang == 'kn' ? 'ರಾಗಿ ಹುಲ್ಲು (Goosegrass)' : 'कोदो घास / गूजग्रास (Goosegrass)';
    }
    if (lower.contains('portulaca') || lower.contains('purslane') || lower.contains('kulfa')) {
      return lang == 'kn' ? 'ಗೋಳಿ ಸೊಪ್ಪು (Purslane)' : 'कुलफा / लोनी (Purslane)';
    }
    if (lower.contains('oxalis') || lower.contains('woodsorrel') || lower.contains('wood sorrel')) {
      return lang == 'kn' ? 'ಹುಳಿ ಸೊಪ್ಪು (Wood Sorrel)' : 'खट्टी मीठी बूಟಿ (Oxalis)';
    }
    if (lower.contains('lantana')) {
      return lang == 'kn' ? 'ಲಂಟಾನ / ರೋಣದ ಗಿಡ (Lantana)' : 'रायमुनिया / लेंटाना (Lantana)';
    }

    return weedName;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'kn', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
