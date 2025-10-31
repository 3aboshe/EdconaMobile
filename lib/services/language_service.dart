import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _selectedLanguageKey = 'selected_language';

  // Language configurations
  static final List<Map<String, String>> languages = [
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
    },
    {
      'code': 'ar',
      'name': 'Arabic',
      'nativeName': 'العربية',
    },
    {
      'code': 'ckb',
      'name': 'Kurdish (Sorani)',
      'nativeName': 'كوردي',
    },
    {
      'code': 'bhn',
      'name': 'Kurdish (Bahdini)',
      'nativeName': 'به‌دینی',
    },
    {
      'code': 'arc',
      'name': 'Assyrian',
      'nativeName': 'ܐܬܘܪܝܐ',
    },
  ];

  static Future<String> getSelectedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageKey) ?? 'en';
  }

  static Future<void> setSelectedLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, languageCode);
  }

  
  static Map<String, String> getLanguageByCode(String code) {
    return languages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => languages.first, // Default to English
    );
  }
}