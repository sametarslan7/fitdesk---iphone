import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda tutulan basit uygulama tercihleri.
abstract final class AppPrefs {
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _favoriteExercisesKey = 'favorite_exercises';
  static const _settingsKey = 'settings';
  static const _activityKey = 'activity_log';
  static const _breakSessionKey = 'break_session';

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  static Future<List<String>> favoriteExerciseIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteExercisesKey) ?? const [];
  }

  static Future<void> setFavoriteExerciseIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteExercisesKey, ids);
  }

  static Future<String?> settingsJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_settingsKey);
  }

  static Future<void> setSettingsJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json);
  }

  static Future<String?> activityJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activityKey);
  }

  static Future<void> setActivityJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activityKey, json);
  }

  static Future<void> clearActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activityKey);
  }

  static Future<String?> breakSessionJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_breakSessionKey);
  }

  static Future<void> setBreakSessionJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_breakSessionKey, json);
  }

  static Future<void> clearBreakSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_breakSessionKey);
  }
}
