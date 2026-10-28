import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/data/activity.dart';
import 'stat_card_title.dart';

/// Bu haftanın günlük egzersiz sayıları (çubuk grafik). Bugün koyu ve
/// üstünde değeriyle; geçmiş günler açık yeşil; gelecek günler gri.
class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({
    super.key,
    required this.counts,
    required this.todayIndex,
  });

  /// Pazartesi'den başlayarak 7 gün.
  final List<int> counts;
  final int todayIndex;

  static const _chartHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = counts.fold(0, (sum, c) => sum + c);
    final maxCount = math.max(1, counts.reduce(math.max));

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StatCardTitle(
            icon: Icons.bar_chart_rounded,
            title: 'Haftalık Aktivite',
            badge: 'Bu Hafta',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: _chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < counts.length; i++)
                  Expanded(
                    child: _Bar(
                      day: weekdayShortNames[i],
                      count: counts[i],
                      fraction: counts[i] / maxCount,
                      isToday: i == todayIndex,
                      isFuture: i > todayIndex,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Bu hafta '),
                        TextSpan(
                          text: '$total egzersiz',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ' tamamladın.'),
                      ],
                    ),
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.count,
    required this.fraction,
    required this.isToday,
    required this.isFuture,
  });

  final String day;
  final int count;
  final double fraction;
  final bool isToday;
  final bool isFuture;

  static const _labelHeight = 22.0;
  static const _valueHeight = 24.0;
  static const _stubHeight = 6.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = isToday
        ? AppColors.primary
        : isFuture || count == 0
        ? AppColors.surfaceContainerHigh
        : AppColors.secondaryFixedDim.withValues(alpha: 0.55);
    final message = isFuture
        ? '$day: henüz gelmedi'
        : '$day: $count egzersiz${isToday ? ' (bugün)' : ''}';

    return Tooltip(
      message: message,
      excludeFromSemantics: true,
      child: Semantics(
        label: message,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final plotHeight =
                constraints.maxHeight - _labelHeight - _valueHeight;
            final barHeight = math.max(_stubHeight, plotHeight * fraction);

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                // Yalnızca bugünün değeri yazılır; diğerleri dokununca görünür.
                SizedBox(
                  height: _valueHeight,
                  child: isToday
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 1,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.all(
                                Radius.circular(99),
                              ),
                            ),
                            child: Text(
                              '$count',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                FractionallySizedBox(
                  widthFactor: 0.68,
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                        bottom: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: _labelHeight,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      day,
                      style: textTheme.labelSmall?.copyWith(
                        color: isToday
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
