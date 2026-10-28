import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/settings.dart';
import '../../core/layout/responsive.dart';
import '../../core/navigation/fade_route.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/app_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../shell/main_shell.dart';

/// Tablette yazılar ve buton aşırı yayılmasın.
const _maxContentWidth = 480.0;

class _OnboardingPage {
  const _OnboardingPage(this.illustration, this.title, this.description);

  final String illustration;
  final String title;
  final String description;
}

const _pages = [
  _OnboardingPage(
    'assets/illustrations/onboarding_1.svg',
    'Harekete küçük\nbir mola ver.',
    'Masa başında geçen saatlerin arasına kısa esneme molaları ekle.',
  ),
  _OnboardingPage(
    'assets/illustrations/onboarding_2.svg',
    'Vücudunu\nihmal etme.',
    'Boyun, omuz, sırt ve bilek egzersizleriyle günlük rutinine hareket kat.',
  ),
  _OnboardingPage(
    'assets/illustrations/onboarding_3.svg',
    'Her gün biraz\ndaha iyi.',
    'Günlük hedeflerini tamamla, serini koru ve gelişimini takip et.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    await AppPrefs.setOnboardingCompleted();
    if (!mounted) return;
    final settings = SettingsScope.of(context);
    // Giriş zorunlu; oturum açıksa (ör. onboarding sıfırlandıysa) doğrudan
    // uygulamaya geçilir.
    final signedIn = AuthService.instance.currentUser != null;
    Navigator.of(context).pushReplacement(
      fadeRoute(signedIn ? const MainShell() : const LoginScreen()),
    );
    // Uygulamaya ilk girişte bildirim izni istenir; verilmezse ayar kapanır.
    final granted = await NotificationService.instance.requestPermission();
    if (!granted) {
      settings.update((s) => s.copyWith(notificationsEnabled: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yatay telefonda butonun etrafındaki boşluklar daralır.
    final short = MediaQuery.sizeOf(context).height < 500;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9, 0.9),
            radius: 1.1,
            colors: [Color(0xFFDDF6E9), AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  // Son sayfada "Atla" gösterilmiyor.
                  child: AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _isLast,
                      child: TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: const Text(
                          'Atla',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _OnboardingPageView(page: _pages[i]),
                ),
              ),
              _PageDots(count: _pages.length, current: _page),
              Padding(
                padding: short
                    ? const EdgeInsets.only(top: 12, bottom: 12)
                    : const EdgeInsets.only(top: 28, bottom: 24),
                child: ResponsiveCenter(
                  maxWidth: _maxContentWidth,
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(_isLast ? 'Başlayalım' : 'Devam Et'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Yatay telefon gibi kısa ve geniş alanlarda çizim solda, yazı sağda.
        final sideBySide =
            constraints.maxHeight < 420 &&
            constraints.maxWidth > constraints.maxHeight * 1.4;

        Widget texts(TextAlign align) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: align == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              page.title,
              textAlign: align,
              style: textTheme.displayLarge?.copyWith(
                fontSize: sideBySide ? 26 : 32,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            SizedBox(height: sideBySide ? 10 : 14),
            Text(
              page.description,
              textAlign: align,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: sideBySide ? 15 : 17,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        );

        if (sideBySide) {
          final art = (constraints.maxHeight * 0.85).clamp(80.0, 300.0);
          return ResponsiveCenter(
            maxWidth: 760,
            child: Row(
              children: [
                SvgPicture.asset(page.illustration, width: art, height: art),
                const SizedBox(width: 32),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(child: texts(TextAlign.start)),
                  ),
                ),
              ],
            ),
          );
        }

        // Kısa ekranlarda çizim küçülür; yine sığmazsa sayfa kaydırılabilir.
        final art = (constraints.maxHeight * 0.5).clamp(96.0, 340.0);
        return Center(
          child: SingleChildScrollView(
            child: ResponsiveCenter(
              maxWidth: _maxContentWidth,
              child: Column(
                children: [
                  SvgPicture.asset(page.illustration, width: art, height: art),
                  const SizedBox(height: 24),
                  texts(TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: i == current ? 32 : 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.secondaryFixedDim
                  : const Color(0xFFD5E3DA),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
      ],
    );
  }
}
