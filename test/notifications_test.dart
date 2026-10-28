import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitdesk/core/config/dev_flags.dart';
import 'package:fitdesk/core/data/activity.dart';
import 'package:fitdesk/core/data/exercise_catalog.dart';
import 'package:fitdesk/core/notifications/break_reminders.dart';
import 'package:fitdesk/core/notifications/notification_service.dart';
import 'package:fitdesk/features/exercises/exercises_screen.dart';
import 'package:fitdesk/features/home/widgets/break_timer_card.dart';
import 'package:fitdesk/features/splash/splash_screen.dart';
import 'package:fitdesk/main.dart';
import 'test_fakes.dart';

typedef Scheduled = ({
  DateTime at,
  String title,
  String body,
  String payload,
  bool sound,
});

/// Kurulan bildirimleri kaydeden sahte servis.
class FakeNotifications extends NotificationService {
  final scheduled = <int, Scheduled>{};
  final tapController = StreamController<String>.broadcast();
  bool grantPermission = true;
  int permissionRequests = 0;

  @override
  Stream<String> get taps => tapController.stream;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grantPermission;
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required bool sound,
  }) async => scheduled[id] = (
    at: at,
    title: title,
    body: body,
    payload: payload,
    sound: sound,
  );

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<void> cancelAll() async => scheduled.clear();
}

/// 21 Ekim 2026 Çarşamba 10:00, varsayılan mesai (Pzt–Cum 09:00–18:00) içinde.
final wednesdayMorning = DateTime(2026, 10, 21, 10);

late FakeNotifications notifications;

Future<void> passSplash(
  WidgetTester tester, [
  Map<String, Object>? prefs,
]) async {
  SharedPreferences.setMockInitialValues(
    prefs ?? {'onboarding_completed': true},
  );
  tester.view.physicalSize = const Size(412, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const FitDeskApp());
  await tester.pump(SplashScreen.minDuration);
  await tester.pumpAndSettle();
}

Map<String, Object> withSettings(String json) => {
  'onboarding_completed': true,
  'settings': json,
};

Future<void> toBackground(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

Future<void> toForeground(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

/// Bugünden [offset] gün sonraki günlük bildirim.
Scheduled? daily(int offset, int kind) =>
    notifications.scheduled[BreakReminders.dailyId(offset, kind)];

Duration testable(int minutes) =>
    Duration(seconds: minutes * DevFlags.secondsPerIntervalUnit);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    useFakeBackend();
    notifications = FakeNotifications();
    NotificationService.instance = notifications;
    BreakTimerCard.clock = () => wednesdayMorning;
    BreakReminders.clock = () => wednesdayMorning;
  });
  tearDown(() {
    NotificationService.instance = NotificationService();
    BreakTimerCard.clock = DateTime.now;
    BreakReminders.clock = DateTime.now;
  });

  testWidgets(
    'Çalışma günleri için mesai, hedef ve sayaç hatırlatmaları kurulur',
    (tester) async {
      await passSplash(tester);

      // Bugün: mesai başı geçti; hedef 17:00'de, mesai sonu 18:00'de.
      expect(daily(0, BreakReminders.workStartKind), isNull);
      expect(daily(0, BreakReminders.goalKind)!.at, DateTime(2026, 10, 21, 17));
      expect(
        daily(0, BreakReminders.goalKind)!.body,
        'Bugünkü hedefine 8 egzersiz kaldı. Mesai bitmeden kısa bir mola ver.',
      );
      final end = daily(0, BreakReminders.workEndKind)!;
      expect(end.at, DateTime(2026, 10, 21, 18));
      expect(end.title, 'Bugünkü mesain bitti');
      expect(
        end.body,
        'Eve dönmeden Boyun, Omuz ve Sırt & Omurga egzersizlerine göz '
        'atabilirsin.',
      );
      expect(end.payload, NotificationService.openExercises);

      // Yarın (Perşembe) tam gün; sayaç başlatılmazsa da hatırlatılır.
      expect(
        daily(1, BreakReminders.workStartKind)!.at,
        DateTime(2026, 10, 22, 9),
      );
      expect(
        daily(1, BreakReminders.idleKind)!.at,
        DateTime(
          2026,
          10,
          22,
          9,
        ).add(testable(BreakReminders.idleReminderMinutes)),
      );

      // Cumartesi ve Pazar çalışma günü değil.
      for (final offset in [3, 4]) {
        for (final kind in [1, 2, 3, 4]) {
          expect(daily(offset, kind), isNull);
        }
      }
      expect(
        daily(5, BreakReminders.workStartKind)!.at,
        DateTime(2026, 10, 26, 9),
      );

      // Uygulama açıkken bugünkü sayaç bildirimleri kurulmaz.
      expect(notifications.scheduled[BreakReminders.idleTodayId], isNull);
    },
  );

  testWidgets('Sayaç hiç başlatılmazsa arka planda hatırlatılır', (
    tester,
  ) async {
    await passSplash(tester);
    await toBackground(tester);

    final idle = notifications.scheduled[BreakReminders.idleTodayId]!;
    expect(
      idle.at,
      wednesdayMorning.add(testable(BreakReminders.idleReminderMinutes)),
    );
    expect(idle.title, 'Sayacı başlatmayı unuttun mu?');

    await toForeground(tester);
    expect(notifications.scheduled[BreakReminders.idleTodayId], isNull);
  });

  testWidgets('Sayaç çalışırken arka planda mola zamanı bildirilir', (
    tester,
  ) async {
    await passSplash(tester);
    await tester.tap(find.text('Çalışmaya Başla'));
    await tester.pump(const Duration(seconds: 1));
    await toBackground(tester);

    final reminder = notifications.scheduled[BreakReminders.breakId]!;
    expect(reminder.at, wednesdayMorning.add(testable(30)));
    expect(reminder.title, 'Mola zamanı!');
    expect(reminder.sound, isTrue);
    expect(notifications.scheduled[BreakReminders.idleTodayId], isNull);

    await toForeground(tester);
    expect(notifications.scheduled[BreakReminders.breakId], isNull);
  });

  testWidgets('Duraklatılıp unutulan sayaç hatırlatılır', (tester) async {
    await passSplash(tester);
    await tester.tap(find.text('Çalışmaya Başla'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Duraklat'));
    await tester.pump();
    await toBackground(tester);

    final paused = notifications.scheduled[BreakReminders.pausedId]!;
    expect(
      paused.at,
      wednesdayMorning.add(testable(BreakReminders.pausedReminderMinutes)),
    );
    expect(paused.title, 'Sayacın duraklatılmış');
    expect(notifications.scheduled[BreakReminders.breakId], isNull);
    await toForeground(tester);
  });

  testWidgets('Sayaç bildirimi mesai sonrasına düşerse kurulmaz', (
    tester,
  ) async {
    final lateAfternoon = DateTime(2026, 10, 21, 17, 59, 50);
    BreakTimerCard.clock = () => lateAfternoon;
    BreakReminders.clock = () => lateAfternoon;
    await passSplash(tester);
    await tester.tap(find.text('Çalışmaya Başla'));
    await tester.pump();
    await toBackground(tester);

    expect(notifications.scheduled[BreakReminders.breakId], isNull);
    expect(daily(0, BreakReminders.workEndKind), isNotNull);
    await toForeground(tester);
  });

  testWidgets('Günlük hedefe ulaşılınca bugünkü hedef bildirimi kalkar', (
    tester,
  ) async {
    await passSplash(tester, withSettings('{"dailyGoal": 4}'));
    expect(
      daily(0, BreakReminders.goalKind)!.body,
      startsWith('Bugünkü hedefine 4 egzersiz kaldı.'),
    );

    final activity = ActivityScope.of(
      tester.element(find.byType(BreakTimerCard)),
    );
    final exercise = ExerciseCatalog.all.first;
    activity.record(exercise, at: wednesdayMorning);
    await tester.pump();
    expect(
      daily(0, BreakReminders.goalKind)!.body,
      startsWith('Bugünkü hedefine 3 egzersiz kaldı.'),
    );

    // Aynı an aynı egzersiz tek kayıt sayılır (bulutta belge kimliği).
    for (var i = 1; i <= 3; i++) {
      activity.record(exercise, at: wednesdayMorning.add(Duration(minutes: i)));
    }
    await tester.pump();
    expect(daily(0, BreakReminders.goalKind), isNull);
    // Yarının hedef hatırlatması durur.
    expect(daily(1, BreakReminders.goalKind), isNotNull);
  });

  testWidgets('Odak modu tüm hatırlatmaları susturur', (tester) async {
    await passSplash(tester, withSettings('{"focusModeEnabled": true}'));
    expect(notifications.scheduled, isEmpty);

    await tester.tap(find.text('Çalışmaya Başla'));
    await tester.pump(const Duration(seconds: 1));
    await toBackground(tester);
    expect(notifications.scheduled, isEmpty);
    await toForeground(tester);
  });

  testWidgets('Ses kapalıysa bildirimler sessiz kurulur', (tester) async {
    await passSplash(tester, withSettings('{"soundEnabled": false}'));
    expect(notifications.scheduled, isNotEmpty);
    expect(notifications.scheduled.values.every((n) => !n.sound), isTrue);
  });

  testWidgets('Bildirimler kapatılınca hepsi kaldırılır', (tester) async {
    await passSplash(tester);
    expect(notifications.scheduled, isNotEmpty);

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masa Başı Bildirimleri'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty);
  });

  testWidgets('İzin verilmezse bildirimler açılmaz', (tester) async {
    notifications.grantPermission = false;
    await passSplash(tester, withSettings('{"notificationsEnabled": false}'));
    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masa Başı Bildirimleri'));
    await tester.pumpAndSettle();

    expect(notifications.permissionRequests, 1);
    expect(
      find.text(
        'Bildirim izni verilmedi. İzni telefonun ayarlarından açabilirsin.',
      ),
      findsOneWidget,
    );
    expect(notifications.scheduled, isEmpty);
  });

  testWidgets('Onboarding bitince bildirim izni istenir', (tester) async {
    notifications.grantPermission = false;
    await passSplash(tester, {});
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Başlayalım'));
    await tester.pumpAndSettle();

    expect(notifications.permissionRequests, 1);
    // İzin verilmediği için ayar kapandı, bildirim de kalmadı.
    expect(notifications.scheduled, isEmpty);
  });

  testWidgets('Mesai sonu bildirimine dokununca Egzersizler açılır', (
    tester,
  ) async {
    await passSplash(tester);
    expect(find.byType(ExercisesScreen), findsNothing);

    notifications.tapController.add(NotificationService.openExercises);
    await tester.pumpAndSettle();
    expect(find.byType(ExercisesScreen), findsOneWidget);
  });
}
