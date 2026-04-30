import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'app_language';

  static Future<Locale> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      return Locale(languageCode);
    }
    final deviceLocale = WidgetsBinding.instance.window.locale;
    return deviceLocale.languageCode == 'ar' ? Locale('ar') : Locale('en');
  }

  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }

  static String getDirection(Locale locale) {
    return locale.languageCode == 'ar' ? 'rtl' : 'ltr';
  }
}
