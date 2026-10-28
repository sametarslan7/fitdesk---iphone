import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/navigation/fade_route.dart';
import '../../core/storage/app_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const minDuration = Duration(milliseconds: 1800);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    final onboarding = AppPrefs.isOnboardingCompleted();
    final user = AuthService.instance.restoreSession();
    await Future<void>.delayed(SplashScreen.minDuration);
    final onboardingDone = await onboarding;
    final signedIn = await user != null;
    if (!mounted) return;

    final Widget next = !onboardingDone
        ? const OnboardingScreen()
        : signedIn
        ? const MainShell()
        : const LoginScreen();
    Navigator.of(context).pushReplacement(fadeRoute(next));
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [Color(0xFFDDF4E7), AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Expanded(child: Center(child: AppLogo(size: 120))),
              _LoadingDots(animation: _dots),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends AnimatedWidget {
  const _LoadingDots({required Animation<double> animation})
    : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                const Color(0xFFCDEFDD),
                AppColors.secondaryFixedDim,
                _pulse(t, i),
              ),
            ),
          ),
      ],
    );
  }

  /// Noktaları sırayla yakıp söndürür.
  double _pulse(double t, int index) {
    final phase = (t - index / 3) % 1.0;
    return phase < 0.5 ? phase * 2 : (1 - phase) * 2;
  }
}
