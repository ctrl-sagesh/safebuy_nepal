import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) => LanguageNotifier());

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language');
    if (saved != null) state = saved;
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language') == null;
  }
}
