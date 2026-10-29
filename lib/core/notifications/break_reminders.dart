import 'package:flutter/material.dart';

import '../config/dev_flags.dart';
import '../data/activity.dart';
import '../data/settings.dart';
import 'notification_service.dart';

/// Ana sayfadaki mola sayacının durumu.
enum BreakTimerStatus { idle, running, paused, finished }

/// Sayaç durumu değişince bitiş anıyla (çalışıyor/bitti) birlikte çağrılır.
typedef BreakSessionCallback =
    void Function(BreakTimerStatus status, DateTime? endsAt);

/// Kurulacak tek bir bildirim.
typedef PlannedNotification = ({
  DateTime at,
  String title,
  String body,
  String payload,
});

/// Hatırlatma bildirimlerini ayarlara, sayaca ve bugünkü ilerlemeye göre
/// planlar. Her çalışma günü (önümüzdeki [horizonDays] gün):
/// - Mesai başlangıcı: sayacı başlatmayı hatırlatır.
/// - Sayaç başlatılmadı: mesai içinde [idleReminderMinutes] boyunca sayaç
///   hiç çalışmadıysa.
/// - Hedefe ulaşılmadı: mesai bitmeden [goalReminderMinutesBeforeEnd] önce,
///   günlük hedef henüz tamamlanmadıysa.
/// - Mesai bitimi: egzersizlere göz atmayı önerir.
///
/// Bugünkü sayaç bildirimleri (mola zamanı, duraklatılmış sayaç, başlatılmamış
/// sayaç) sadece uygulama arka plandayken kurulur; açıkken kart zaten
/// gösterir. Oturum açık değilse, bildirimler kapalıysa ya da odak modu
/// açıksa hiçbiri kurulmaz; çıkış yapılınca kurulu olanlar da kaldırılır.
class BreakReminders with WidgetsBindingObserver {
  BreakReminders(this._settings, this._activity) {
    _settings.addListener(_replan);
    _activity.addListener(_replan);
    WidgetsBinding.instance.addObserver(this);
  }

  final SettingsController _settings;
  final ActivityController _activity;

  /// Şimdiki zaman; testler sabit bir an verebilsin diye değiştirilebilir.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static const horizonDays = 7;

  /// Sayaç bu kadar süre başlatılmazsa hatırlatılır.
  static const idleReminderMinutes = 60;

  /// Duraklatılmış sayaç bu kadar süre sonra hatırlatılır.
  static const pausedReminderMinutes = 15;

  static const goalReminderMinutesBeforeEnd = 60;

  /// Geliştirmede sayaç bekleme süreleri de saniye sayılır (bkz. [DevFlags]).
  static Duration _testable(int minutes) =>
      Duration(seconds: minutes * DevFlags.secondsPerIntervalUnit);

  static const breakId = 1;
  static const pausedId = 2;
  static const idleTodayId = 3;

  /// Günlük bildirimler: 100 + gün sırası * 10 + tür.
  static int dailyId(int dayOffset, int kind) => 100 + dayOffset * 10 + kind;
  static const workStartKind = 1;
  static const idleKind = 2;
  static const goalKind = 3;
  static const workEndKind = 4;

  NotificationService get _service => NotificationService.instance;

  BreakTimerStatus _status = BreakTimerStatus.idle;
  DateTime? _endsAt;

  /// Sayacın boşta/duraklatılmış duruma geçtiği an.
  DateTime _idleSince = clock();
  DateTime? _pausedSince;
  bool _inForeground = true;
  bool _signedIn = false;

  /// Oturum açılınca ya da kapanınca çağrılır.
  set signedIn(bool value) {
    if (value == _signedIn) return;
    _signedIn = value;
    _replan();
  }

  /// Son kurulan plan; sadece değişen bildirimler yeniden kurulur. Null iken
  /// eski kayıtlar bilinmediği için önce hepsi temizlenir.
  Map<int, PlannedNotification>? _applied;
  bool? _appliedSound;

  /// Eşitlemeler sırayla çalışır; biri bitmeden başlayan diğerine karışmaz.
  Future<void> _queue = Future.value();

  /// Mola sayacı durumu değişince çağrılır.
  void updateBreakSession(BreakTimerStatus status, DateTime? endsAt) {
    if (status == _status && endsAt == _endsAt) return;
    final now = clock();
    if (status == BreakTimerStatus.idle && _status != BreakTimerStatus.idle) {
      _idleSince = now;
    }
    _pausedSince = status == BreakTimerStatus.paused
        ? (_status == BreakTimerStatus.paused ? _pausedSince : now)
        : null;
    _status = status;
    _endsAt = endsAt;
    _replan();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _inForeground) return;
    _inForeground = foreground;
    _replan();
  }

  /// Bildirimleri şu anki planla eşitler; ayarlar ilk yüklenince de çağrılır.
  Future<void> sync() => _queue = _queue.then((_) => _apply());

  void _replan() => sync();

  /// Şu anki duruma göre kurulması gereken bildirimler.
  @visibleForTesting
  Map<int, PlannedNotification> plan() {
    final s = _settings.value;
    if (!_signedIn || !s.notificationsEnabled || s.focusModeEnabled) {
      return const {};
    }

    final now = clock();
    final today = DateTime(now.year, now.month, now.day);
    final planned = <int, PlannedNotification>{};

    void add(int id, DateTime at, String title, String body, String payload) {
      if (at.isAfter(now)) {
        planned[id] = (at: at, title: title, body: body, payload: payload);
      }
    }

    for (var offset = 0; offset < horizonDays; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      if (!s.workDays.contains(day.weekday)) continue;
      final start = _at(day, s.workStart);
      final end = _at(day, s.workEnd);
      bool inHours(DateTime t) => !t.isBefore(start) && t.isBefore(end);

      add(
        dailyId(offset, workStartKind),
        start,
        'Mesain başladı',
        'Mola sayacını başlat, molalarını sana hatırlatalım.',
        NotificationService.openHome,
      );

      // Bugün sayacın durumu bilindiği için ayrıca planlanır.
      final idleAt = start.add(_testable(idleReminderMinutes));
      if (offset > 0 && inHours(idleAt)) {
        add(
          dailyId(offset, idleKind),
          idleAt,
          _idleTitle,
          _idleBody,
          NotificationService.openHome,
        );
      }

      final remaining = offset == 0
          ? s.dailyGoal - _activity.today(now).length
          : s.dailyGoal;
      final goalAt = end.subtract(
        const Duration(minutes: goalReminderMinutesBeforeEnd),
      );
      if (remaining > 0 && goalAt.isAfter(start)) {
        add(
          dailyId(offset, goalKind),
          goalAt,
          'Hedefine henüz ulaşmadın',
          'Bugünkü hedefine $remaining egzersiz kaldı. '
              'Mesai bitmeden kısa bir mola ver.',
          NotificationService.openExercises,
        );
      }

      add(
        dailyId(offset, workEndKind),
        end,
        'Bugünkü mesain bitti',
        _workEndBody(s),
        NotificationService.openExercises,
      );

      if (offset == 0 && !_inForeground) {
        _planTimer(add, now, start, inHours);
      }
    }
    return planned;
  }

  /// Bugünkü sayaca bağlı bildirimler; mesai dışına düşenler kurulmaz.
  void _planTimer(
    void Function(int, DateTime, String, String, String) add,
    DateTime now,
    DateTime start,
    bool Function(DateTime) inHours,
  ) {
    void addIfInHours(int id, DateTime at, String title, String body) {
      if (inHours(at)) add(id, at, title, body, NotificationService.openHome);
    }

    /// Hatırlatma anı geçtiyse (uygulama açıkken beklenmiş) şimdiden sayılır.
    DateTime after(DateTime since, Duration wait) {
      final at = since.add(wait);
      return at.isAfter(now) ? at : now.add(wait);
    }

    switch (_status) {
      case BreakTimerStatus.running:
        if (_endsAt case final endsAt?) {
          addIfInHours(
            breakId,
            endsAt,
            'Mola zamanı!',
            'Birkaç dakikalık esneme için kalk, vücudun teşekkür edecek.',
          );
        }
      case BreakTimerStatus.paused:
        addIfInHours(
          pausedId,
          after(_pausedSince ?? now, _testable(pausedReminderMinutes)),
          'Sayacın duraklatılmış',
          'Kaldığın yerden devam et, sonraki molan seni bekliyor.',
        );
      case BreakTimerStatus.idle:
        final since = _idleSince.isAfter(start) ? _idleSince : start;
        addIfInHours(
          idleTodayId,
          after(since, _testable(idleReminderMinutes)),
          _idleTitle,
          _idleBody,
        );
      case BreakTimerStatus.finished:
        break;
    }
  }

  static const _idleTitle = 'Sayacı başlatmayı unuttun mu?';
  static const _idleBody =
      'Bir süredir mola sayacın kapalı. Başlat, esneme zamanını kaçırma.';

  static String _workEndBody(AppSettings s) {
    final names = [for (final area in s.focusAreas) area.name];
    if (names.isEmpty) {
      return 'Eve dönmeden egzersizlere göz atıp kısa bir esneme yapabilirsin.';
    }
    final list = names.length == 1
        ? names.first
        : '${names.sublist(0, names.length - 1).join(', ')} ve ${names.last}';
    return 'Eve dönmeden $list egzersizlerine göz atabilirsin.';
  }

  static DateTime _at(DateTime day, TimeOfDay time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  Future<void> _apply() async {
    final plan = this.plan();
    final sound = _settings.value.soundEnabled;
    // Ses değişince hepsi yeni kanalla yeniden kurulur.
    final previous = sound == _appliedSound ? _applied : null;
    _applied = plan;
    _appliedSound = sound;
    if (previous == null) await _service.cancelAll();
    for (final id in previous?.keys ?? const <int>[]) {
      if (!plan.containsKey(id)) await _service.cancel(id);
    }
    for (final MapEntry(key: id, value: n) in plan.entries) {
      if (previous != null && previous[id] == n) continue;
      await _service.scheduleAt(
        id: id,
        at: n.at,
        title: n.title,
        body: n.body,
        payload: n.payload,
        sound: sound,
      );
    }
  }

  void dispose() {
    _settings.removeListener(_replan);
    _activity.removeListener(_replan);
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// [BreakReminders]ı alt ağaca sağlar.
class BreakRemindersScope extends InheritedWidget {
  const BreakRemindersScope({
    super.key,
    required this.reminders,
    required super.child,
  });

  final BreakReminders reminders;

  static BreakReminders of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BreakRemindersScope>()!.reminders;

  @override
  bool updateShouldNotify(BreakRemindersScope oldWidget) =>
      reminders != oldWidget.reminders;
}
