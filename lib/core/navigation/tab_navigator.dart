import 'package:flutter/material.dart';

/// Bir sekmenin kendi gezinme yığını: alt sayfalar alt menünün üstünde değil,
/// sekmenin içinde açılır (alt menü her ekranda görünür).
class TabNavigator extends StatelessWidget {
  const TabNavigator({
    super.key,
    required this.navigatorKey,
    required this.active,
    required this.rootBuilder,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  /// Sekme görünürken sistem geri tuşu önce bu yığını geri alır.
  final bool active;
  final WidgetBuilder rootBuilder;

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      enabled: active,
      onPopWithResult: (_) => navigatorKey.currentState?.maybePop(),
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) =>
            MaterialPageRoute(settings: settings, builder: rootBuilder),
      ),
    );
  }
}
