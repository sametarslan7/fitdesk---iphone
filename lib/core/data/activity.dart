import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../storage/app_prefs.dart';
import 'activity_cloud.dart';
import 'exercise_catalog.dart';

/// Tamamlanmış tek bir egzersiz.
class CompletedExercise {
  const CompletedExercise(this.exercise, this.completedAt);

  final Exercise exercise;
  final DateTime completedAt;

  String get name => exercise.name;
  int get durationSeconds => exercise.durationSeconds;
  BodyArea get area => exercise.area;
}

class AreaStat {
  const AreaStat(this.area, this.count);

  final BodyArea area;
  final int count;
}

class AchievementBadge {
  const AchievementBadge(
    this.name,
    this.detail,
    this.icon, {
    this.earned = false,
  });

  final String name;
  final String detail;
  final IconData icon;
  final bool earned;

  AchievementBadge withEarned(bool earned) =>
      AchievementBadge(name, detail, icon, earned: earned);
}

const weekdayShortNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const weekdayNames = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

/// Tamamlanan egzersizlerin kaydı. Hesaba bağlıyken ([connect]) bulutta,
/// değilken cihazda saklanır. İstatistikler, ana sayfadaki ilerleme ve seri bu
/// kayıttan hesaplanır.
class ActivityController extends ChangeNotifier {
  /// Eskiden yeniye sıralı.
  final _entries = <CompletedExercise>[];

  ActivityCloud? _cloud;
  StreamSubscription<List<ActivityRecord>>? _cloudSubscription;

  static const _eyeMasterCount = 10;

  List<CompletedExercise> get entries => List.unmodifiable(_entries);

  /// Cihazdaki kaydı okur (hesaba bağlı değilken).
  Future<void> load() async {
    _replaceWith(await _readLocal());
  }

  /// Kaydı kullanıcının bulut kopyasına bağlar. Cihazda giriş öncesinden
  /// kalan kayıt bir kez hesaba aktarılıp cihazdan silinir.
  Future<void> connect(ActivityCloud cloud) async {
    _cloudSubscription?.cancel();
    _cloud = cloud;
    _replaceWith(const []);
    _cloudSubscription = cloud.watch().listen(
      // İptal edilen eski aboneliğin geç gelen verisi yok sayılır.
      (records) {
        if (_cloud == cloud) _replaceWith(records);
      },
      onError: (Object e) => debugPrint('Egzersiz kaydı okunamadı: $e'),
    );

    final local = await _readLocal();
    if (local.isEmpty || _cloud != cloud) return;
    // Çevrimdışıyken yazma sunucuya ulaşana kadar tamamlanmaz; o zamana dek
    // cihazdaki kopya da kalır, aktarım bir sonraki açılışta tekrarlanır.
    try {
      await cloud.addAll(local);
      await AppPrefs.clearActivity();
    } catch (e) {
      debugPrint('Cihazdaki egzersiz kaydı hesaba aktarılamadı: $e');
    }
  }

  /// Hesaptan çıkınca kayıt ekrandan temizlenir (bulutta kalır).
  void disconnect() {
    _cloudSubscription?.cancel();
    _cloudSubscription = null;
    _cloud = null;
    _replaceWith(const []);
  }

  static Future<List<ActivityRecord>> _readLocal() async {
    final json = await AppPrefs.activityJson();
    if (json == null) return const [];
    try {
      return [
        for (final item in jsonDecode(json) as List)
          if (item case {'id': final String id, 'at': final int at})
            (exerciseId: id, at: DateTime.fromMillisecondsSinceEpoch(at)),
      ];
    } on FormatException {
      // Bozuk kayıt uygulamayı açılmaz hale getirmesin.
      return const [];
    }
  }

  void _replaceWith(List<ActivityRecord> records) {
    _entries
      ..clear()
      ..addAll([
        for (final r in records)
          // Katalogdan kaldırılmış egzersizler sessizce düşer.
          if (ExerciseCatalog.byId(r.exerciseId) case final exercise?)
            CompletedExercise(exercise, r.at),
      ])
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    notifyListeners();
  }

  void record(Exercise exercise, {DateTime? at}) {
    final entry = CompletedExercise(exercise, at ?? DateTime.now());
    _entries
      ..add(entry)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    notifyListeners();

    if (_cloud case final cloud?) {
      // Firestore yazmayı önce cihazda tutar; çevrimdışıyken de kaybolmaz.
      cloud
          .addAll([(exerciseId: exercise.id, at: entry.completedAt)])
          .catchError((Object e) => debugPrint('Egzersiz kaydedilemedi: $e'));
      return;
    }
    final json = jsonEncode([
      for (final e in _entries)
        {'id': e.exercise.id, 'at': e.completedAt.millisecondsSinceEpoch},
    ]);
    // Yazmalar sırayla yapılır; aksi halde art arda kayıtta eski liste en son
    // yazılıp yenileri silebilir.
    _saving = _saving.then((_) => AppPrefs.setActivityJson(json));
  }

  @override
  void dispose() {
    _cloudSubscription?.cancel();
    super.dispose();
  }

  Future<void> _saving = Future.value();

  // Gün hesapları takvim günüyle yapılır; saat farkıyla (Duration) yapılırsa
  // yaz saati geçişlerinde gün 23/25 saat sürer ve sayımlar kayar.
  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  static DateTime _addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  /// Haftanın pazartesisi.
  static DateTime _weekStart(DateTime t) => _addDays(_day(t), 1 - t.weekday);

  Map<DateTime, int> get _perDay {
    final perDay = <DateTime, int>{};
    for (final e in _entries) {
      final day = _day(e.completedAt);
      perDay[day] = (perDay[day] ?? 0) + 1;
    }
    return perDay;
  }

  int get total => _entries.length;

  int get totalSeconds => _entries.fold(0, (sum, e) => sum + e.durationSeconds);

  /// Bugün tamamlananlar, en yenisi başta.
  List<CompletedExercise> today(DateTime now) => [
    for (final e in _entries.reversed)
      if (_day(e.completedAt) == _day(now)) e,
  ];

  /// Bu haftanın günlük egzersiz sayıları (Pazartesi'den başlayarak).
  List<int> weekCounts(DateTime now) {
    final start = _weekStart(now);
    final perDay = _perDay;
    return [for (var i = 0; i < 7; i++) perDay[_addDays(start, i)] ?? 0];
  }

  /// Art arda egzersiz yapılan gün sayısı. Bugün henüz egzersiz yoksa seri
  /// dünden sayılır (gün bitene kadar bozulmaz).
  int currentStreak(DateTime now) {
    final days = _perDay.keys.toSet();
    var day = _day(now);
    if (!days.contains(day)) day = _addDays(day, -1);
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = _addDays(day, -1);
    }
    return streak;
  }

  int get longestStreak {
    final days = _perDay.keys.toList()..sort();
    var longest = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      run = previous != null && day == _addDays(previous, 1) ? run + 1 : 1;
      longest = math.max(longest, run);
      previous = day;
    }
    return longest;
  }

  /// Bir haftada (Pzt–Paz) tamamlanan en çok egzersiz.
  int get weeklyPeak {
    final perWeek = <DateTime, int>{};
    for (final e in _entries) {
      final week = _weekStart(e.completedAt);
      perWeek[week] = (perWeek[week] ?? 0) + 1;
    }
    return perWeek.values.fold(0, math.max);
  }

  /// Bu ay en çok çalışılan bölgeler, çoktan aza.
  List<AreaStat> topAreasThisMonth(DateTime now, {int limit = 3}) {
    final counts = <String, int>{};
    for (final e in _entries) {
      if (e.completedAt.year != now.year || e.completedAt.month != now.month) {
        continue;
      }
      counts[e.area.id] = (counts[e.area.id] ?? 0) + 1;
    }
    final stats = [
      for (final area in BodyAreas.all)
        if (counts[area.id] case final count?) AreaStat(area, count),
    ]..sort((a, b) => b.count.compareTo(a.count));
    return stats.take(limit).toList();
  }

  /// Tüm rozetler; kazanılanlar [AchievementBadge.earned] ile işaretli.
  List<AchievementBadge> badges(int dailyGoal) {
    final eyeCount = _entries
        .where((e) => e.area.id == BodyAreas.eyes.id)
        .length;
    return [
      _firstStep.withEarned(total > 0),
      _eyeMaster.withEarned(eyeCount >= _eyeMasterCount),
      _weeklyChampion.withEarned(_hadPerfectWeek(dailyGoal)),
    ];
  }

  /// Herhangi bir haftanın 7 gününün hepsinde günlük hedefe ulaşıldı mı.
  bool _hadPerfectWeek(int dailyGoal) {
    final perDay = _perDay;
    final weeks = {for (final day in perDay.keys) _weekStart(day)};
    return weeks.any(
      (start) => List.generate(
        7,
        (i) => _addDays(start, i),
      ).every((day) => (perDay[day] ?? 0) >= dailyGoal),
    );
  }

  static const _firstStep = AchievementBadge(
    'İlk Adım',
    'İlk egzersiz',
    Icons.directions_walk_rounded,
  );
  static const _eyeMaster = AchievementBadge(
    'Göz Dinlendirici',
    '$_eyeMasterCount göz egzersizi',
    Icons.visibility_outlined,
  );
  static const _weeklyChampion = AchievementBadge(
    'Haftalık Şampiyon',
    'Bir hafta her gün hedef',
    Icons.emoji_events_outlined,
  );
}

/// Egzersiz kaydını alt ağaca sağlar; değişince dinleyen sayfalar yeniden
/// çizilir.
class ActivityScope extends InheritedNotifier<ActivityController> {
  const ActivityScope({
    super.key,
    required ActivityController controller,
    required super.child,
  }) : super(notifier: controller);

  static ActivityController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActivityScope>()!.notifier!;

  /// Dinlemeden erişim (buton geri çağrıları için).
  static ActivityController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ActivityScope>()!.notifier!;
}
