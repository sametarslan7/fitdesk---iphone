import 'dart:convert';

import 'package:flutter/material.dart';

import '../storage/app_prefs.dart';
import 'exercise_catalog.dart';

/// Kullanıcı tercihleri. Cihazda saklanır; giriş/hesap yok.
@immutable
class AppSettings {
  const AppSettings({
    this.breakIntervalMinutes = 30,
    this.breakDurationMinutes = 3,
    this.dailyGoal = 8,
    this.workStart = const TimeOfDay(hour: 9, minute: 0),
    this.workEnd = const TimeOfDay(hour: 18, minute: 0),
    this.workDays = const {1, 2, 3, 4, 5},
    this.focusAreaIds = const {'neck', 'shoulder', 'back'},
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.focusModeEnabled = false,
  });

  /// Mola hatırlatıcısı seçenekleri (dakika).
  static const breakIntervalOptions = [15, 30, 45];
  static const breakDurationOptions = [2, 3, 5];
  static const dailyGoalOptions = [4, 6, 8, 10, 12, 15];
  static const recommendedDailyGoal = 8;

  final int breakIntervalMinutes;
  final int breakDurationMinutes;
  final int dailyGoal;
  final TimeOfDay workStart;
  final TimeOfDay workEnd;

  /// Çalışılan günler, [DateTime.weekday] değerleriyle (1 = Pazartesi). Boş olmaz.
  final Set<int> workDays;
  final Set<String> focusAreaIds;
  final bool notificationsEnabled;
  final bool soundEnabled;

  /// Toplantı & odak modu: açıkken hatırlatmalar susar.
  final bool focusModeEnabled;

  AppSettings copyWith({
    int? breakIntervalMinutes,
    int? breakDurationMinutes,
    int? dailyGoal,
    TimeOfDay? workStart,
    TimeOfDay? workEnd,
    Set<int>? workDays,
    Set<String>? focusAreaIds,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? focusModeEnabled,
  }) => AppSettings(
    breakIntervalMinutes: breakIntervalMinutes ?? this.breakIntervalMinutes,
    breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    workStart: workStart ?? this.workStart,
    workEnd: workEnd ?? this.workEnd,
    workDays: workDays ?? this.workDays,
    focusAreaIds: focusAreaIds ?? this.focusAreaIds,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
  );

  List<BodyArea> get focusAreas => [
    for (final area in BodyAreas.all)
      if (focusAreaIds.contains(area.id)) area,
  ];

  Map<String, Object> toJson() => {
    'breakIntervalMinutes': breakIntervalMinutes,
    'breakDurationMinutes': breakDurationMinutes,
    'dailyGoal': dailyGoal,
    'workStart': _minutesOf(workStart),
    'workEnd': _minutesOf(workEnd),
    'workDays': (workDays.toList()..sort()),
    'focusAreaIds': focusAreaIds.toList(),
    'notificationsEnabled': notificationsEnabled,
    'soundEnabled': soundEnabled,
    'focusModeEnabled': focusModeEnabled,
  };

  /// Eksik ya da geçersiz alanlar varsayılana döner (eski sürüm verisi).
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const defaults = AppSettings();
    T read<T>(String key, T fallback, [bool Function(T)? valid]) {
      final value = json[key];
      if (value is T && (valid == null || valid(value))) return value;
      return fallback;
    }

    return AppSettings(
      breakIntervalMinutes: read(
        'breakIntervalMinutes',
        defaults.breakIntervalMinutes,
        breakIntervalOptions.contains,
      ),
      breakDurationMinutes: read(
        'breakDurationMinutes',
        defaults.breakDurationMinutes,
        breakDurationOptions.contains,
      ),
      dailyGoal: read(
        'dailyGoal',
        defaults.dailyGoal,
        dailyGoalOptions.contains,
      ),
      workStart: _timeOf(read('workStart', _minutesOf(defaults.workStart))),
      workEnd: _timeOf(read('workEnd', _minutesOf(defaults.workEnd))),
      workDays: _workDaysOf(json['workDays']) ?? defaults.workDays,
      focusAreaIds: json['focusAreaIds'] is List
          ? (json['focusAreaIds'] as List).whereType<String>().toSet()
          : defaults.focusAreaIds,
      notificationsEnabled: read(
        'notificationsEnabled',
        defaults.notificationsEnabled,
      ),
      soundEnabled: read('soundEnabled', defaults.soundEnabled),
      focusModeEnabled: read('focusModeEnabled', defaults.focusModeEnabled),
    );
  }

  /// Geçerli gün yoksa null (varsayılana dönülür).
  static Set<int>? _workDaysOf(Object? value) {
    if (value is! List) return null;
    final days = value.whereType<int>().where((d) => d >= 1 && d <= 7).toSet();
    return days.isEmpty ? null : days;
  }

  static int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

  static TimeOfDay _timeOf(int minutes) =>
      TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);
}

/// Ayarları tutar, değişince dinleyenleri uyarır ve cihaza yazar.
class SettingsController extends ChangeNotifier {
  AppSettings _value = const AppSettings();

  AppSettings get value => _value;

  Future<void> load() async {
    final raw = await AppPrefs.settingsJson();
    if (raw == null) return;
    try {
      _value = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      notifyListeners();
    } on FormatException {
      // Bozuk kayıt: varsayılanlarla devam et.
    } on TypeError {
      // Beklenmeyen biçim: varsayılanlarla devam et.
    }
  }

  void update(AppSettings Function(AppSettings current) change) {
    _value = change(_value);
    notifyListeners();
    AppPrefs.setSettingsJson(jsonEncode(_value.toJson()));
  }
}

/// Ayarları alt ağaca sağlar; değişince dinleyen sayfalar yeniden çizilir.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
