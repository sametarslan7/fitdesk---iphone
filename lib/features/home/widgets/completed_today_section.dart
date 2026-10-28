import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/data/activity.dart';

class CompletedTodaySection extends StatelessWidget {
  const CompletedTodaySection({super.key, required this.exercises});

  final List<CompletedExercise> exercises;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Bugün Tamamlananlar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (exercises.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(99),
                        ),
                      ),
                      child: Text(
                        '${exercises.length} tamamlandı',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.task_alt_rounded,
              size: 20,
              color: AppColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (exercises.isEmpty)
          AppCard(
            child: Text(
              'Bugün henüz egzersiz yapmadın.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final exercise in exercises) ...[
            _CompletedTile(exercise: exercise),
            if (exercise != exercises.last) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _CompletedTile extends StatelessWidget {
  const _CompletedTile({required this.exercise});

  final CompletedExercise exercise;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceContainer,
            child: Icon(exercise.area.icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${exercise.durationSeconds} sn',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '•',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                      ),
                      child: Text(
                        exercise.area.name,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.onSecondaryFixed,
            ),
          ),
        ],
      ),
    );
  }
}
