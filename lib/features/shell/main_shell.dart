import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/data/exercise_catalog.dart';
import '../../core/layout/responsive.dart';
import '../../core/navigation/tab_navigator.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../exercises/area_exercises_screen.dart';
import '../exercises/exercises_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../statistics/statistics_screen.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _tabs = [
  _Tab('Ana Sayfa', Icons.home_outlined, Icons.home_rounded),
  _Tab('Egzersizler', Icons.self_improvement_outlined, Icons.self_improvement),
  _Tab('İstatistikler', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
  _Tab('Profil', Icons.account_circle_outlined, Icons.account_circle),
];

/// Alt menüyü taşıyan ana iskelet; sekmeler arası geçişte ekran durumları korunur.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _homeTab = 0;
  static const _exercisesTab = 1;
  static const _profileTab = 3;

  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _exercisesNavigatorKey = GlobalKey<NavigatorState>();
  final _profileNavigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription<String>? _notificationTaps;

  @override
  void initState() {
    super.initState();
    final notifications = NotificationService.instance;
    if (notifications.takeLaunchPayload() case final payload?) {
      _openFromNotification(payload);
    }
    _notificationTaps = notifications.taps.listen(_openFromNotification);
  }

  @override
  void dispose() {
    _notificationTaps?.cancel();
    super.dispose();
  }

  /// Bildirime dokununca ilgili sekme açılır.
  void _openFromNotification(String payload) {
    if (payload == NotificationService.openExercises) {
      _openExercises();
    } else {
      setState(() => _index = _homeTab);
      _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  void _goTo(int index) {
    // Açık sekmeye tekrar dokunulunca sekmenin ilk sayfasına dönülür.
    if (index == _index) {
      final navigator = switch (index) {
        _homeTab => _homeNavigatorKey.currentState,
        _exercisesTab => _exercisesNavigatorKey.currentState,
        _profileTab => _profileNavigatorKey.currentState,
        _ => null,
      };
      navigator?.popUntil((route) => route.isFirst);
    }
    setState(() => _index = index);
  }

  /// Ana sayfadaki bağlantılar egzersiz listesini en baştan açar.
  void _openExercises() {
    setState(() => _index = _exercisesTab);
    _exercisesNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  /// Bölge sayfası ana sayfa sekmesinde açılır; geri dönünce ana sayfaya
  /// dönülür.
  void _openArea(BodyArea area) {
    _homeNavigatorKey.currentState?.push(AreaExercisesScreen.route(area));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          TabNavigator(
            navigatorKey: _homeNavigatorKey,
            active: _index == _homeTab,
            rootBuilder: (_) => HomeScreen(
              onOpenExercises: _openExercises,
              onOpenArea: _openArea,
            ),
          ),
          TabNavigator(
            navigatorKey: _exercisesNavigatorKey,
            active: _index == _exercisesTab,
            rootBuilder: (_) => const ExercisesScreen(),
          ),
          const StatisticsScreen(),
          TabNavigator(
            navigatorKey: _profileNavigatorKey,
            active: _index == _profileTab,
            rootBuilder: (_) => const ProfileScreen(),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(currentIndex: _index, onTap: _goTo),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F143828),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            // Tablette sekmeler ekranın iki ucuna dağılmasın, ortada dursun.
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.maxSingleColumnWidth,
                  minHeight: 64,
                  maxHeight: 64,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: _BottomBarItem(
                          tab: _tabs[i],
                          selected: i == currentIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primaryContainer
        : AppColors.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Seçili sekmenin ikonu gölgeli bir hap içinde öne çıkar.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryFixed : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x33143828),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : const [],
              ),
              child: Icon(
                selected ? tab.activeIcon : tab.icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            // Dar ekranda etiket alt satıra kaymak yerine biraz küçülür.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
