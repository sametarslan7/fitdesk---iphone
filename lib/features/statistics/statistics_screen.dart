import 'package:flutter/material.dart';

import '../../core/data/activity.dart';
import '../../core/data/settings.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import 'widgets/achievements.dart';
import 'widgets/daily_goal_card.dart';
import 'widgets/summary_cards.dart';
import 'widgets/top_areas_card.dart';
import 'widgets/weekly_activity_card.dart';

/// Gelişim özeti; tamamlanan egzersiz kaydından hesaplanır. İlk açılışta
/// boştur, kullanıcı egzersiz yaptıkça dolar.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final activity = ActivityScope.of(context);
    final dailyGoal = SettingsScope.of(context).value.dailyGoal;
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final weekCounts = activity.weekCounts(now);
    final weekTotal = weekCounts.fold(0, (sum, c) => sum + c);
    final totalMinutes = activity.totalSeconds ~/ 60;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = Responsive.sizeOf(width) == ScreenSize.expanded;
        final maxWidth = wide
            ? Responsive.maxWideWidth
            : Responsive.maxSingleColumnWidth;
        final inset = Responsive.horizontalInset(width, maxWidth: maxWidth);
        final gap = Responsive.sectionSpacing(width);
        const cardGap = 12.0;

        final summary = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TotalCompletedCard(total: activity.total, thisWeek: weekTotal),
            const SizedBox(height: cardGap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: MetricCard(
                      icon: Icons.local_fire_department_outlined,
                      iconColor: AppColors.streak,
                      iconBackground: AppColors.streak.withValues(alpha: 0.12),
                      label: 'Mevcut Seri',
                      tag: 'Aktif',
                      parts: [('${activity.currentStreak(now)}', 'Gün')],
                    ),
                  ),
                  const SizedBox(width: cardGap),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.primary,
                      iconBackground: AppColors.secondaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      label: 'Toplam Süre',
                      tag: 'Toplam',
                      parts: [
                        ('${totalMinutes ~/ 60}', 'sa'),
                        ('${totalMinutes % 60}', 'dk'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final weekly = WeeklyActivityCard(
          counts: weekCounts,
          todayIndex: todayIndex,
        );
        final goal = DailyGoalCard(
          counts: weekCounts,
          todayIndex: todayIndex,
          goal: dailyGoal,
        );
        final areas = TopAreasCard(areas: activity.topAreasThisMonth(now));
        final record = PersonalRecordCard(
          longestStreak: activity.longestStreak,
          weeklyPeak: activity.weeklyPeak,
        );
        final badges = BadgesSection(badges: activity.badges(dailyGoal));

        final List<Widget> children;
        if (wide) {
          children = [
            const _Intro(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      summary,
                      const SizedBox(height: cardGap),
                      weekly,
                      const SizedBox(height: cardGap),
                      goal,
                    ],
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      areas,
                      const SizedBox(height: cardGap),
                      record,
                      SizedBox(height: gap),
                      badges,
                    ],
                  ),
                ),
              ],
            ),
          ];
        } else {
          children = [
            const _Intro(),
            const SizedBox(height: 16),
            summary,
            const SizedBox(height: cardGap),
            weekly,
            const SizedBox(height: cardGap),
            goal,
            const SizedBox(height: cardGap),
            areas,
            const SizedBox(height: cardGap),
            record,
            SizedBox(height: gap),
            badges,
          ];
        }

        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                inset,
                padding.top + AppHeader.height + 8,
                inset,
                // Alt menü yüksekliği padding.bottom içinde zaten var.
                padding.bottom + 16,
              ),
              children: children,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppHeader(
                subtitle: 'İstatistikler',
                maxContentWidth: maxWidth,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.all(Radius.circular(99)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 14,
                color: AppColors.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'VERİ ANALİZİ',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'İstatistikler',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gelişimini keşfet, istikrarını koru.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
