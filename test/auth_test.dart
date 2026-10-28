import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitdesk/core/data/activity.dart';
import 'package:fitdesk/core/data/exercise_catalog.dart';
import 'package:fitdesk/features/auth/login_screen.dart';
import 'package:fitdesk/features/auth/register_screen.dart';
import 'package:fitdesk/features/home/widgets/break_timer_card.dart';
import 'package:fitdesk/features/shell/main_shell.dart';
import 'package:fitdesk/features/splash/splash_screen.dart';
import 'package:fitdesk/main.dart';

import 'test_fakes.dart';

final wednesdayMorning = DateTime(2026, 10, 21, 10);

Future<void> launch(
  WidgetTester tester, {
  Map<String, Object> prefs = const {'onboarding_completed': true},
  Size size = const Size(412, 915),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const FitDeskApp());
  await tester.pump(SplashScreen.minDuration);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => BreakTimerCard.clock = () => wednesdayMorning);
  tearDown(() => BreakTimerCard.clock = DateTime.now);

  testWidgets('Oturum yoksa açılışta giriş sayfası gösterilir', (tester) async {
    useFakeBackend(user: null);
    await launch(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets('Oturum açıksa doğrudan ana sayfa açılır ve ad görünür', (
    tester,
  ) async {
    useFakeBackend();
    await launch(tester);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Merhaba Deniz!'), findsOneWidget);
  });

  testWidgets('Onboarding bitince giriş sayfasına geçilir', (tester) async {
    useFakeBackend(user: null);
    await launch(tester, prefs: {});
    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('E-posta ile giriş: hatalı şifrede uyarı, doğrusunda ana sayfa', (
    tester,
  ) async {
    useFakeBackend(user: null);
    await launch(tester);

    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();
    expect(find.text('Geçerli bir e-posta gir.'), findsOneWidget);
    expect(find.text('Şifreni gir.'), findsOneWidget);

    await tester.enterText(field('E-posta'), 'deniz@example.com');
    await tester.enterText(field('Şifre'), 'yanlis');
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();
    expect(find.text('E-posta ya da şifre hatalı.'), findsOneWidget);

    await tester.enterText(field('Şifre'), 'gizli123');
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);
    // Ad yoksa e-postanın baş kısmı kullanılır.
    expect(find.text('Merhaba deniz!'), findsOneWidget);
  });

  testWidgets('Uyarılar alana yazmaya başlayınca kaybolur', (tester) async {
    useFakeBackend(user: null);
    await launch(tester);

    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();
    expect(find.text('Geçerli bir e-posta gir.'), findsOneWidget);
    expect(find.text('Şifreni gir.'), findsOneWidget);

    // Yalnızca yazılan alanın uyarısı kaybolur, değer hâlâ geçersiz olsa da.
    await tester.enterText(field('E-posta'), 'den');
    await tester.pump();
    expect(find.text('Geçerli bir e-posta gir.'), findsNothing);
    expect(find.text('Şifreni gir.'), findsOneWidget);

    // Bir sonraki gönderimde yeniden denetlenir.
    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();
    expect(find.text('Geçerli bir e-posta gir.'), findsOneWidget);

    await tester.enterText(field('E-posta'), 'deniz@example.com');
    await tester.enterText(field('Şifre'), 'yanlis');
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();
    expect(find.text('E-posta ya da şifre hatalı.'), findsOneWidget);

    await tester.enterText(field('Şifre'), 'yanlis1');
    await tester.pump();
    expect(find.text('E-posta ya da şifre hatalı.'), findsNothing);
  });

  testWidgets('Kayıt olunca ad ana sayfada görünür', (tester) async {
    useFakeBackend(user: null);
    await launch(tester);
    await tester.enterText(field('E-posta'), 'yeni@example.com');
    await tester.tap(find.text('Kayıt ol'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    // Giriş sayfasındaki e-posta taşınır.
    expect(find.text('yeni@example.com'), findsOneWidget);

    await tester.enterText(field('Adın'), 'Elif Demir');
    await tester.enterText(field('Şifre (en az 6 karakter)'), '123');
    await tester.tap(find.text('Kayıt Ol'));
    await tester.pump();
    expect(find.text('Şifre en az 6 karakter olmalı.'), findsOneWidget);

    await tester.enterText(field('Şifre (en az 6 karakter)'), '123456');
    await tester.tap(find.text('Kayıt Ol'));
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Merhaba Elif!'), findsOneWidget);
  });

  testWidgets('Google penceresi kapatılırsa giriş sayfasında kalınır', (
    tester,
  ) async {
    final auth = useFakeBackend(user: null)..googleCancels = true;
    await launch(tester);
    await tester.tap(find.text('Google ile devam et'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    auth.googleCancels = false;
    await tester.tap(find.text('Google ile devam et'));
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Merhaba Ada!'), findsOneWidget);
  });

  testWidgets('Şifremi unuttum sıfırlama bağlantısı gönderir', (tester) async {
    final auth = useFakeBackend(user: null);
    await launch(tester);
    await tester.enterText(field('E-posta'), 'deniz@example.com');
    await tester.tap(find.text('Şifremi unuttum'));
    await tester.pumpAndSettle();
    expect(find.text('Şifreni sıfırla'), findsOneWidget);
    await tester.tap(find.text('Bağlantı Gönder'));
    await tester.pumpAndSettle();
    expect(auth.resetEmails, ['deniz@example.com']);
    expect(find.textContaining('sıfırlama bağlantısı'), findsOneWidget);
  });

  testWidgets('Cihazdaki egzersiz kaydı girişte hesaba aktarılır', (
    tester,
  ) async {
    useFakeBackend();
    final at = wednesdayMorning.subtract(const Duration(hours: 1));
    await launch(
      tester,
      prefs: {
        'onboarding_completed': true,
        'activity_log':
            '[{"id": "neck_rotation", "at": ${at.millisecondsSinceEpoch}}]',
      },
    );
    final cloud = FakeActivityCloud.store[FakeAuthService.testUser.uid]!;
    expect(cloud.values.single.exerciseId, 'neck_rotation');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('activity_log'), isNull);

    final activity = ActivityScope.of(
      tester.element(find.byType(BreakTimerCard)),
    );
    expect(activity.total, 1);

    // Yeni egzersiz de buluta yazılır.
    activity.record(ExerciseCatalog.all.first, at: wednesdayMorning);
    await tester.pump();
    expect(cloud, hasLength(2));
    expect(activity.total, 2);
  });

  testWidgets('Çıkış yapınca giriş sayfası açılır, kayıt hesapta kalır', (
    tester,
  ) async {
    useFakeBackend();
    // Çıkış satırı alt menünün altında kalmasın.
    await launch(tester, size: const Size(412, 2000));
    final activity = ActivityScope.of(
      tester.element(find.byType(BreakTimerCard)),
    );
    activity.record(ExerciseCatalog.all.first, at: wednesdayMorning);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    expect(find.text('deniz@example.com'), findsWidgets);
    await tester.tap(find.text('Çıkış Yap'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Çıkış Yap'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(activity.total, 0);
    expect(FakeActivityCloud.store[FakeAuthService.testUser.uid], hasLength(1));
  });

  testWidgets('E-postadaki boşluklar şifre alanına geçince silinir', (
    tester,
  ) async {
    useFakeBackend(user: null);
    await launch(tester);
    await tester.enterText(field('E-posta'), '  deniz@example.com ');
    await tester.tap(field('Şifre'));
    await tester.pump();
    expect(find.text('deniz@example.com'), findsOneWidget);
  });

  testWidgets('Boş bir yere dokununca alandan çıkılır', (tester) async {
    useFakeBackend(user: null);
    await launch(tester);
    bool emailFocused() => tester
        .widget<EditableText>(
          find.descendant(
            of: field('E-posta'),
            matching: find.byType(EditableText),
          ),
        )
        .focusNode
        .hasFocus;

    await tester.tap(field('E-posta'));
    await tester.pump();
    expect(emailFocused(), isTrue);
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(emailFocused(), isFalse);
  });

  testWidgets(
    'Kayda geçince giriş uyarıları silinir, geçersiz e-posta taşınmaz',
    (tester) async {
      useFakeBackend(user: null);
      await launch(tester);
      await tester.enterText(field('E-posta'), 'samet@gmail');
      await tester.tap(find.text('Giriş Yap'));
      await tester.pump();
      expect(find.text('Geçerli bir e-posta gir.'), findsOneWidget);

      await tester.tap(find.text('Kayıt ol'));
      await tester.pumpAndSettle();
      expect(find.text('samet@gmail'), findsNothing);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Geçerli bir e-posta gir.'), findsNothing);
      expect(find.text('Şifreni gir.'), findsNothing);
      expect(find.text('samet@gmail'), findsNothing);
    },
  );

  testWidgets('Kayıtta ad büyük harfle başlar, boşluk şifre reddedilir ve '
      'eski sunucu hatası silinir', (tester) async {
    useFakeBackend(user: null);
    await launch(tester);
    await tester.tap(find.text('Kayıt ol'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Adın'), 'ilker ışık');
    expect(find.text('İlker Işık'), findsOneWidget);

    await tester.enterText(field('E-posta'), 'deniz@example.com');
    await tester.enterText(field('Şifre (en az 6 karakter)'), '123456');
    await tester.tap(find.text('Kayıt Ol'));
    await tester.pumpAndSettle();
    expect(find.text('Bu e-posta ile zaten bir hesap var.'), findsOneWidget);

    const charsError =
        'Şifrede yalnızca harf (Türkçe karakter hariç), rakam, _ ve . '
        'kullanılabilir.';
    await tester.enterText(field('Şifre (en az 6 karakter)'), '      ');
    await tester.tap(find.text('Kayıt Ol'));
    await tester.pump();
    expect(find.text(charsError), findsOneWidget);
    expect(find.text('Bu e-posta ile zaten bir hesap var.'), findsNothing);

    for (final password in ['abc 123', 'şifre123', 'abc!123']) {
      await tester.enterText(field('Şifre (en az 6 karakter)'), password);
      await tester.tap(find.text('Kayıt Ol'));
      await tester.pump();
      expect(find.text(charsError), findsOneWidget, reason: password);
    }

    await tester.enterText(field('Şifre (en az 6 karakter)'), 'Ab_1.9');
    await tester.tap(find.text('Kayıt Ol'));
    await tester.pumpAndSettle();
    expect(find.text(charsError), findsNothing);
  });

  testWidgets('Kayıttan geri dönülünce giriş formu boşalır; kayıt formu her '
      'açılışta boş gelir', (tester) async {
    useFakeBackend(user: null);
    await launch(tester);
    await tester.enterText(field('E-posta'), 'deniz@example.com');
    await tester.enterText(field('Şifre'), 'gizli1');

    await tester.tap(find.text('Kayıt ol'));
    await tester.pumpAndSettle();
    expect(find.text('deniz@example.com'), findsOneWidget);
    await tester.enterText(field('Adın'), 'Deniz');

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('deniz@example.com'), findsNothing);
    expect(find.text('gizli1'), findsNothing);

    await tester.tap(find.text('Kayıt ol'));
    await tester.pumpAndSettle();
    expect(find.text('Deniz'), findsNothing);
    expect(find.text('deniz@example.com'), findsNothing);
  });

  testWidgets('Kayıt sayfasından var olan Google hesabına girilince uyarılır', (
    tester,
  ) async {
    useFakeBackend(user: null).googleAccountExists = true;
    await launch(tester);
    await tester.tap(find.text('Kayıt ol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Google ile devam et'));
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.textContaining('zaten bir hesabın vardı'), findsOneWidget);
  });

  testWidgets('Kayıt sürerken sistem geri tuşu sayfayı kapatmaz', (
    tester,
  ) async {
    final auth = useFakeBackend(user: null);
    await launch(tester);
    await tester.tap(find.text('Kayıt ol'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Adın'), 'Elif');
    await tester.enterText(field('E-posta'), 'elif@example.com');
    await tester.enterText(field('Şifre (en az 6 karakter)'), '123456');

    auth.registerDelay = const Duration(seconds: 1);
    await tester.tap(find.text('Kayıt Ol'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(MainShell), findsOneWidget);
  });

  for (final size in const [
    Size(320, 568),
    Size(412, 915),
    Size(768, 1024),
    Size(915, 412),
  ]) {
    testWidgets(
      'Giriş ve kayıt sayfaları ${size.width.toInt()}x${size.height.toInt()} '
      'ekranda taşmaz',
      (tester) async {
        useFakeBackend(user: null);
        await launch(tester, size: size);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Giriş Yap'));
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Kayıt ol'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kayıt ol'));
        await tester.pumpAndSettle();
        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // En uzun uyarı "…" ile kesilmeden alt satırlara sığar.
        await tester.enterText(field('Şifre (en az 6 karakter)'), 'abc 123');
        await tester.ensureVisible(find.text('Kayıt Ol'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kayıt Ol'));
        await tester.pump();
        final error = find.textContaining('Şifrede yalnızca harf');
        expect(error, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(error);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
