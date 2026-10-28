import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/data/activity.dart';

/// Bu hafta günlük hedefin kaç gün tutturulduğu: yüzde halkası ve gün çipleri.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({
    super.key,
    required this.counts,
    required this.todayIndex,
    required this.goal,
  });

  final List<int> counts;
  final int todayIndex;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final daysSoFar = todayIndex + 1;
    final metDays = [
      for (var i = 0; i < daysSoFar; i++) counts[i] >= goal,
    ].where((met) => met).length;
    final ratio = metDays / daysSoFar;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günlük Hedef Başarısı',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Sayıya göre değişen ek ("5'inde", "4'ünde") yok.
                      'Bu hafta $metDays / $daysSoFar gün hedefine ulaştın '
                      '(günde $goal egzersiz).',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox.square(
                dimension: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: ratio,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      color: AppColors.primaryContainer,
                      backgroundColor: AppColors.surfaceContainerHigh,
                    ),
                    Center(
                      child: Text(
                        '%${(ratio * 100).round()}',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                Expanded(
                  child: _DayChip(
                    day: weekdayShortNames[i],
                    state: i > todayIndex
                        ? _DayState.future
                        : counts[i] >= goal
                        ? _DayState.met
                        : i == todayIndex
                        ? _DayState.inProgress
                        : _DayState.missed,
                  ),
                ),
                if (i < 6) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

enum _DayState {
  met('hedef tamamlandı'),
  missed('hedef tamamlanmadı'),
  inProgress('bugün, devam ediyor'),
  future('henüz gelmedi');

  const _DayState(this.description);
  final String description;
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.state});

  final String day;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final met = state == _DayState.met;

    final Widget mark = switch (state) {
      _DayState.met => const CircleAvatar(
        radius: 10,
        backgroundColor: AppColors.primaryContainer,
        child: Icon(Icons.check_rounded, size: 14, color: AppColors.onPrimary),
      ),
      _DayState.inProgress => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.secondary, width: 2),
        ),
      ),
      _DayState.missed => const CircleAvatar(
        radius: 10,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: Icon(
          Icons.close_rounded,
          size: 13,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      _DayState.future => const CircleAvatar(
        radius: 10,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: Icon(Icons.remove_rounded, size: 13, color: AppColors.outline),
      ),
    };

    return Semantics(
      label: '$day: ${state.description}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: met
              ? AppColors.secondaryContainer.withValues(alpha: 0.35)
              : AppColors.surfaceContainerLow,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                day,
                style: textTheme.labelSmall?.copyWith(
                  color: met ? AppColors.onSurface : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 6),
            mark,
          ],
        ),
      ),
    );
  }
}
