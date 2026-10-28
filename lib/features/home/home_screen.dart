import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/activity.dart';
import '../../core/data/exercise_catalog.dart';
import '../../core/data/settings.dart';
import '../../core/notifications/break_reminders.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/tip_banner.dart';
import '../exercises/exercise_actions.dart';
import 'home_placeholder_data.dart';
import 'widgets/body_area_section.dart';
import 'widgets/break_timer_card.dart';
import 'widgets/completed_today_section.dart';
import 'widgets/daily_progress_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenExercises,
    required this.onOpenArea,
  });

  final VoidCallback onOpenExercises;
  final ValueChanged<BodyArea> onOpenArea;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Ekran döndürülüp yerleşim değişince sayaç sıfırlanmasın.
  final _timerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final settings = SettingsScope.of(context);
    final activity = ActivityScope.of(context);
    final now = DateTime.now();
    final completedToday = activity.today(now);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = Responsive.sizeOf(width) == ScreenSize.expanded;
        final maxWidth = wide
            ? Responsive.maxWideWidth
            : Responsive.maxSingleColumnWidth;
        final inset = Responsive.horizontalInset(width, maxWidth: maxWidth);
        final gap = Responsive.sectionSpacing(width);

        const greeting = _Greeting();
        final progress = DailyProgressCard(
          completed: completedToday.length,
          goal: settings.value.dailyGoal,
          streakDays: activity.currentStreak(now),
        );
        final timer = BreakTimerCard(
          key: _timerKey,
          intervalMinutes: settings.value.breakIntervalMinutes,
          workDays: settings.value.workDays,
          workStart: settings.value.workStart,
          workEnd: settings.value.workEnd,
          // Aralık, günler ve saatler Profil'den değişir.
          onBreakDue: (exercise) =>
              startExercise(context, exercise, title: 'Mola Egzersizi'),
          onSessionChanged: BreakRemindersScope.of(context).updateBreakSession,
        );
        final completed = CompletedTodaySection(exercises: completedToday);
        final areas = BodyAreaSection(
          areas: placeholderBodyAreas,
          onSeeAll: widget.onOpenExercises,
          onAreaTap: widget.onOpenArea,
        );
        const tip = TipBanner(
          title: '20-20-20 Kuralını Unutma',
          body:
              'Her 20 dakikada bir, 20 saniye boyunca 6 metre uzağa '
              'bakarak göz kaslarını dinlendir.',
        );

        final List<Widget> children;
        if (wide) {
          children = [
            greeting,
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      progress,
                      SizedBox(height: gap),
                      timer,
                    ],
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      completed,
                      SizedBox(height: gap),
                      areas,
                      SizedBox(height: gap),
                      tip,
                    ],
                  ),
                ),
              ],
            ),
          ];
        } else {
          children = [
            greeting,
            const SizedBox(height: 16),
            progress,
            SizedBox(height: gap),
            timer,
            SizedBox(height: gap),
            completed,
            SizedBox(height: gap),
            areas,
            SizedBox(height: gap),
            tip,
          ];
        }

        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                inset,
                padding.top + AppHeader.height + 8,
                inset,
                // Alt menü içeriğin üstünde durduğu için Scaffold, menü
                // yüksekliğini padding.bottom içine zaten ekliyor.
                padding.bottom + 16,
              ),
              children: children,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppHeader(
                subtitle: switch (AuthScope.userOf(context)?.firstName) {
                  final name? => 'Merhaba $name!',
                  null => 'Merhaba!',
                },
                maxContentWidth: maxWidth,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bugün kendini nasıl hissediyorsun?',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Masa başında zinde ve dengede kalmak için doğru andasın.',
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
