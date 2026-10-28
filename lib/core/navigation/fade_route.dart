import 'package:flutter/material.dart';

/// Ekranlar arası yumuşak geçiş (splash → onboarding → ana iskelet).
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
