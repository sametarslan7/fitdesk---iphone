import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitdesk/core/config/dev_flags.dart';
import 'package:fitdesk/core/data/activity.dart';
import 'package:fitdesk/core/data/exercise_catalog.dart';
import 'package:fitdesk/core/data/settings.dart';
import 'package:fitdesk/core/widgets/tip_banner.dart';
import 'package:fitdesk/features/exercises/exercise_actions.dart';
import 'package:fitdesk/features/home/widgets/break_timer_card.dart';
import 'package:fitdesk/features/splash/splash_screen.dart';
import 'package:fitdesk/main.dart';

import 'test_fakes.dart';

const onboardedPrefs = <String, Object>{'onboarding_completed': true};

/// Testlerde sayacın gördüğü zaman: 21 Ekim 2026 Çarşamba 10:00, yani
/// varsayılan mesai (Pazartesi – Cuma, 09:00 – 18:00) içinde.
final wednesdayMorning = DateTime(2026, 10, 21, 10);

/// Ayarlarda sadece verilen alanları değiştiren önayarlar.
Map<String, Object> prefsWithSettings(String settingsJson) => {
  'onboarding_completed': true,
  'settings': settingsJson,
};

/// Ana sayfa sayacının göstermesi gereken metin (DevFlags'e göre dk ya da sn).
String timerText(int interval, {int elapsed = 0}) {
  final s = interval * DevFlags.secondsPerIntervalUnit - elapsed;
  final mm = (s ~/ 60).toString().padLeft(2, '0');
  final ss = (s % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

/// Mola sayacı kartındaki ana düğme.
ButtonStyleButton timerButton(WidgetTester tester, String label) =>
    tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );

Future<void> passSplash(WidgetTester tester) async {
  await tester.pumpWidget(const FitDeskApp());
  await tester.pump(SplashScreen.minDuration);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    useFakeBackend();
    BreakTimerCard.clock = () => wednesdayMorning;
  });
  tearDown(() => BreakTimerCard.clock = DateTime.now);

  testWidgets('İlk açılışta onboarding gösterilir ve tamamlanınca kaydedilir', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await passSplash(tester);

    expect(find.text('Harekete küçük\nbir mola ver.'), findsOneWidget);
    expect(find.text('Atla'), findsOneWidget);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Her gün biraz\ndaha iyi.'), findsOneWidget);

    await tester.tap(find.text('Başlayalım'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Egzersizler'), findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_completed'), isTrue);
  });

  testWidgets('Onboarding görüldüyse splash sonrası alt menü açılır', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(onboardedPrefs);
    await passSplash(tester);

    for (final label in [
      'Ana Sayfa',
      'Egzersizler',
      'İstatistikler',
      'Profil',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.byIcon(Icons.account_circle_outlined).last);
    await tester.pump();
    expect(find.byIcon(Icons.account_circle), findsOneWidget);
  });

  // Dar telefon, telefon, tablet dikey, tablet yatay, telefon yatay.
  for (final size in const [
    Size(320, 640),
    Size(412, 915),
    Size(768, 1024),
    Size(1180, 820),
    Size(915, 412),
  ]) {
    testWidgets('Ana sayfa ${size.width.toInt()}x${size.height.toInt()} '
        'ekranda taşmadan ve ortalı çizilir', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(onboardedPrefs);
      await passSplash(tester);

      // Sayaç kartın tam ortasında olmalı.
      final timer = find.text(timerText(30));
      final card = find
          .ancestor(of: timer, matching: find.byType(Material))
          .first;
      expect(
        tester.getCenter(timer).dx,
        moreOrLessEquals(tester.getCenter(card).dx, epsilon: 1),
      );
      // Taşma (overflow) olmamalı.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Ana sayfa en alta kaydırılınca altta fazla boşluk kalmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(onboardedPrefs);
    await passSplash(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    // Son öğe (ipucu kutusu) ile alt menünün (64px) arası.
    final tipBottom = tester.getBottomLeft(find.byType(TipBanner)).dy;
    final gap = (915 - 64) - tipBottom;
    expect(gap, inInclusiveRange(8, 24));
  });

  testWidgets('Onboarding tablette ve yatay telefonda taşmaz', (tester) async {
    for (final size in const [
      Size(1180, 820),
      Size(915, 412),
      Size(320, 640),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      SharedPreferences.setMockInitialValues({});
      await passSplash(tester);
      expect(find.text('Devam Et'), findsOneWidget);
      expect(
        tester.getSize(find.byType(FilledButton)).width,
        lessThanOrEqualTo(480),
      );
      expect(tester.takeException(), isNull);
    }
    tester.view.reset();
  });

  testWidgets(
    'Ana sayfadaki mola sayacı başlar, duraklar; aralık seansı bozmaz',
    (tester) async {
      // Sayfanın tamamı kaydırmadan sığsın.
      tester.view.physicalSize = const Size(412, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(onboardedPrefs);
      await passSplash(tester);

      expect(find.text(timerText(30)), findsOneWidget);
      await tester.tap(find.text('Çalışmaya Başla'));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(timerText(30, elapsed: 3)), findsOneWidget);

      await tester.tap(find.text('Duraklat'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(timerText(30, elapsed: 3)), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);

      // Aralık seçenekleri ana sayfada yok, sadece ayarlarda.
      expect(find.text('15 dk'), findsNothing);

      // Duraklatılmış seans sürerken aralık ayarlardan değişirse seans bozulmaz.
      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mola Hatırlatıcı Aralığı'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('45 dk'));
      await tester.pump();
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.text(timerText(30, elapsed: 3)), findsOneWidget);
    },
  );

  Future<void> openExercisesTab(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(onboardedPrefs);
    await passSplash(tester);
    await tester.tap(find.byIcon(Icons.self_improvement_outlined));
    await tester.pumpAndSettle();
  }

  for (final size in const [
    Size(320, 640),
    Size(412, 915),
    Size(768, 1024),
    Size(1180, 820),
    Size(915, 412),
  ]) {
    testWidgets('Egzersizler ve bölge sayfası ${size.width.toInt()}x'
        '${size.height.toInt()} ekranda taşmaz', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await openExercisesTab(tester);
      expect(find.text('Vücut Bölgeleri'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Sabit başlığın altında kalmasın diye ekranın ortasına getir.
      await Scrollable.ensureVisible(
        tester.element(find.text('Boyun')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Boyun'));
      await tester.pumpAndSettle();
      expect(find.text('Boyun Egzersizleri'), findsOneWidget);
      expect(find.text('Seriyi Başlat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Arama Türkçe karakterden bağımsız çalışır', (tester) async {
    await openExercisesTab(tester);

    await tester.enterText(find.byType(TextField), 'dondurme');
    await tester.pumpAndSettle();
    expect(find.text('Boyun Döndürme'), findsOneWidget);
    expect(find.text('Bilek ve Parmak Döndürme'), findsOneWidget);
    expect(find.text('Vücut Bölgeleri'), findsNothing);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Aramana uygun egzersiz bulunamadı.'), findsOneWidget);

    await tester.tap(find.byTooltip('Aramayı temizle'));
    await tester.pumpAndSettle();
    expect(find.text('Vücut Bölgeleri'), findsOneWidget);
  });

  testWidgets('Favoriye eklenen egzersiz kaydedilir ve listelenir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openExercisesTab(tester);
    expect(find.text('Popüler Egzersizler'), findsOneWidget);

    await tester.tap(find.byTooltip('Favorilere ekle').first);
    await tester.pumpAndSettle();
    expect(find.text('Favori Egzersizler'), findsOneWidget);
    expect(find.text('Tümünü Gör (1)'), findsOneWidget);
    // Popüler bölüm favorilerle birlikte kalır.
    expect(find.text('Popüler Egzersizler'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_exercises'), ['neck_side_stretch']);

    await tester.tap(find.text('Tümünü Gör (1)'));
    await tester.pumpAndSettle();
    expect(find.text('1 egzersiz'), findsOneWidget);
  });

  testWidgets('Ana sayfadaki bölge kartı bölge sayfasını alt menüyle açar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(onboardedPrefs);
    await passSplash(tester);

    await tester.tap(find.text('Omuz').last);
    await tester.pumpAndSettle();
    expect(find.text('Omuz Egzersizleri'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);

    // Bölge sayfası ana sayfa sekmesinde açılır; geri ana sayfaya döner.
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Omuz Egzersizleri'), findsNothing);
    expect(find.text('SONRAKİ MOLAYA KALAN SÜRE'), findsOneWidget);

    // Açık sekmeye tekrar dokununca da ana sayfaya dönülür.
    await tester.tap(find.text('Omuz').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Omuz Egzersizleri'), findsNothing);
    expect(find.text('SONRAKİ MOLAYA KALAN SÜRE'), findsOneWidget);
  });

  testWidgets('Egzersiz seansı bilgi, geri sayım ve süreyle tamamlanır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final activity = ActivityController();
    addTearDown(activity.dispose);
    final exercise = ExerciseCatalog.byId('neck_rotation')!;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            ActivityScope(controller: activity, child: child!),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => startExercise(context, exercise),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    expect(find.text('Egzersiz Bilgisi'), findsOneWidget);
    expect(find.text('Nasıl Uygulanır?'), findsOneWidget);

    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(find.text('HAZIR MISIN?'), findsOneWidget);

    // 3-2-1 geri sayımdan sonra süre başlar; bitmeden tamamlanamaz.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.text('Sıra Sende'), findsOneWidget);
    final complete = find.ancestor(
      of: find.text('Tamamladım'),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    );
    expect(tester.widget<FilledButton>(complete).onPressed, isNull);

    for (var i = 0; i < exercise.durationSeconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(complete).onPressed, isNotNull);

    await tester.tap(complete);
    await tester.pumpAndSettle();
    expect(find.text('Harika iş!'), findsOneWidget);

    // Tamamlanan egzersiz kaydedilir.
    expect(activity.total, 1);
    expect(activity.today(DateTime.now()).single.exercise.id, exercise.id);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('activity_log'), contains('neck_rotation'));

    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    expect(find.text('aç'), findsOneWidget);
  });

  for (final size in const [
    Size(320, 640),
    Size(412, 915),
    Size(768, 1024),
    Size(1180, 820),
    Size(915, 412),
  ]) {
    testWidgets('İstatistikler ${size.width.toInt()}x${size.height.toInt()} '
        'ekranda taşmadan çizilir', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(onboardedPrefs);
      await passSplash(tester);
      await tester.tap(find.byIcon(Icons.bar_chart_outlined));
      await tester.pumpAndSettle();

      expect(find.text('TAMAMLANAN EGZERSİZ'), findsOneWidget);
      expect(find.text('Haftalık Aktivite'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Sayfanın sonuna kadar kaydırınca da taşma olmamalı.
      await tester.drag(find.byType(ListView).last, const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(find.text('Kazanılan Rozetler'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> openProfileTab(
    WidgetTester tester, {
    Map<String, Object> prefs = onboardedPrefs,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    await passSplash(tester);
    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
  }

  for (final size in const [
    Size(320, 640),
    Size(412, 915),
    Size(768, 1024),
    Size(1180, 820),
    Size(915, 412),
  ]) {
    testWidgets(
      'Profil ve ayarlar ${size.width.toInt()}x${size.height.toInt()} '
      'ekranda taşmaz',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await openProfileTab(tester);
        expect(find.text('Mola Hatırlatıcı Aralığı'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(ListView).last, const Offset(0, -5000));
        await tester.pumpAndSettle();
        expect(find.textContaining('FitDesk v'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(ListView).last, const Offset(0, 5000));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mola Hatırlatıcı Aralığı'));
        await tester.pumpAndSettle();
        expect(
          find.text('Molalar arasındaki çalışma süresini belirle.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Mola aralığı Kaydet ile kaydedilir ve sayaca uygulanır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openProfileTab(tester);
    await tester.tap(find.text('Mola Hatırlatıcı Aralığı'));
    await tester.pumpAndSettle();

    // Bu sayfada sadece mola aralığı var.
    expect(find.text('Günlük Egzersiz Hedefi'), findsNothing);

    await tester.tap(find.text('45 dk'));
    await tester.pump();
    expect(
      find.text('Değişiklik yapıldı • henüz kaydedilmedi'),
      findsOneWidget,
    );

    // Kaydetmeden geri: onay sorulur, düzenlemeye devam edilir.
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Kaydedilmemiş Değişiklikler'), findsOneWidget);
    await tester.tap(find.text('Düzenlemeye Devam Et'));
    await tester.pumpAndSettle();
    expect(
      find.text('Molalar arasındaki çalışma süresini belirle.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(
      find.text('Molalar arasındaki çalışma süresini belirle.'),
      findsNothing,
    );
    expect(find.text('45 dk'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings'), contains('"breakIntervalMinutes":45'));

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text(timerText(45)), findsOneWidget);
  });

  testWidgets('Çalışma günleri seçilir, kaydedilir ve hiç gün kalmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Varsayılan günlerle (Pazartesi – Cuma).
    await openProfileTab(tester, prefs: {'onboarding_completed': true});
    // Diğer sekmelerde de gün kısaltmaları var; sadece görünenler.
    Finder day(String name) => find.text(name).hitTestable();

    expect(find.text('Pazartesi – Cuma · 5 gün'), findsOneWidget);

    // Haftada 2 gün: Salı ve Perşembe.
    for (final name in ['Pzt', 'Çar', 'Cum']) {
      await tester.tap(day(name));
      await tester.pump();
    }
    expect(find.text('Salı, Perşembe · 2 gün'), findsOneWidget);

    await tester.tap(day('Cmt'));
    await tester.pump();
    expect(find.text('Sal, Per, Cmt · 3 gün'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings'), contains('"workDays":[2,4,6]'));

    // Son gün kaldırılamaz.
    await tester.tap(day('Sal'));
    await tester.tap(day('Per'));
    await tester.pump();
    expect(find.text('Cumartesi · 1 gün'), findsOneWidget);
    await tester.tap(day('Cmt'));
    await tester.pump();
    expect(find.text('Cumartesi · 1 gün'), findsOneWidget);
    expect(find.text('En az bir çalışma günü seçili olmalı.'), findsOneWidget);
  });

  testWidgets('Çalışma günü olmayan günde mola sayacı başlatılamaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Çarşamba çalışma günü değil.
    SharedPreferences.setMockInitialValues(
      prefsWithSettings('{"workDays":[1,2,4,5]}'),
    );
    await passSplash(tester);

    expect(find.text('BUGÜN ÇALIŞMA GÜNÜN DEĞİL'), findsOneWidget);
    expect(find.text('Çalışmaya Başla'), findsNothing);
    expect(timerButton(tester, 'Bugün Dinlenme Günü').onPressed, isNull);
    expect(
      find.textContaining('Sonraki çalışma günün Perşembe.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mesai başlamadan mola sayacı başlatılamaz', (tester) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    BreakTimerCard.clock = () => DateTime(2026, 10, 21, 8, 30);
    SharedPreferences.setMockInitialValues(onboardedPrefs);
    await passSplash(tester);

    expect(find.text('MESAİN HENÜZ BAŞLAMADI'), findsOneWidget);
    expect(timerButton(tester, 'Mesai 09:00 ile başlar').onPressed, isNull);

    // Mesai başlayınca kart kendiliğinden açılır.
    BreakTimerCard.clock = () => DateTime(2026, 10, 21, 9);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Çalışmaya Başla'), findsOneWidget);
  });

  for (final (hour, label) in [
    (7, 'Mesai 09:00 ile başlar'),
    (20, 'Mesai Bitti'),
  ]) {
    testWidgets('Mesai dışı kart ($label) en dar ekranda taşmaz', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      BreakTimerCard.clock = () => DateTime(2026, 10, 21, hour);
      SharedPreferences.setMockInitialValues(onboardedPrefs);
      await passSplash(tester);
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mesai bitince süren sayaç durur ve yeniden başlatılamaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    BreakTimerCard.clock = () => DateTime(2026, 10, 21, 17, 59);
    SharedPreferences.setMockInitialValues(onboardedPrefs);
    await passSplash(tester);
    await tester.tap(find.text('Çalışmaya Başla'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(timerText(30, elapsed: 2)), findsOneWidget);

    BreakTimerCard.clock = () => DateTime(2026, 10, 21, 18);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BUGÜNKÜ MESAİN BİTTİ'), findsOneWidget);
    expect(find.text(timerText(30)), findsOneWidget);
    expect(timerButton(tester, 'Mesai Bitti').onPressed, isNull);
    expect(
      find.text('Sonraki çalışma günün Perşembe, mesai 09:00 ile başlar.'),
      findsOneWidget,
    );
  });

  testWidgets('Mesai saati değişince süren sayaç durur', (tester) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(onboardedPrefs);
    await passSplash(tester);
    await tester.tap(find.text('Çalışmaya Başla'));
    await tester.pump(const Duration(seconds: 3));

    // Saat 10:00 iken mesai bitişi 09:30 yapılırsa mesai bitmiş olur.
    final settings = SettingsScope.of(
      tester.element(find.byType(BreakTimerCard)),
    );
    settings.update(
      (s) => s.copyWith(workEnd: const TimeOfDay(hour: 9, minute: 30)),
    );
    await tester.pump();
    expect(find.text('BUGÜNKÜ MESAİN BİTTİ'), findsOneWidget);
    expect(find.text(timerText(30)), findsOneWidget);
  });

  testWidgets('Bugün çalışma günlerinden çıkarılınca süren sayaç durur', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(onboardedPrefs);
    await passSplash(tester);
    await tester.tap(find.text('Çalışmaya Başla'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(timerText(30, elapsed: 3)), findsOneWidget);

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çar').hitTestable());
    await tester.pump();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Bugün Dinlenme Günü'), findsOneWidget);
    expect(find.text(timerText(30)), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(timerText(30)), findsOneWidget);
  });

  testWidgets('Değişiklikler atılınca ayar değişmez', (tester) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openProfileTab(tester);
    await tester.tap(find.text('Günlük Egzersiz Hedefi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Molalar arasındaki çalışma süresini belirle.'),
      findsNothing,
    );

    await tester.tap(find.text('12'));
    await tester.pump();
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Değişiklikleri At'));
    await tester.pumpAndSettle();

    expect(
      find.text('Molalar arasındaki çalışma süresini belirle.'),
      findsNothing,
    );
    expect(find.text('8 egzersiz'), findsOneWidget);
  });
}
