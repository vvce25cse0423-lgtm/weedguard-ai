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
    'crop_type':       {'en': 'Crop Type',     'kn': 'ಬೆಳೆ ಪ್ರಕಾರ',   'hi': 'फसल का प्रकार'},
    'create_field':    {'en': 'Create Field',  'kn': 'ಹೊಲ ರಚಿಸಿ',    'hi': 'खेत बनाएं'},

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
    'email':           {'en': 'Email',     'kn': 'ಇಮೇಲ್',     'hi': 'ईमेल'},
    'password':        {'en': 'Password',  'kn': 'ಪಾಸ್‌ವರ್ಡ್', 'hi': 'पासवर्ड'},
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
