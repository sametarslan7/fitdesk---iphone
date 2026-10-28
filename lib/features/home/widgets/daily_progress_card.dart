import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';

/// Günlük hedefe göre tamamlanan egzersiz sayısı ve seri bilgisi.
class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({
    super.key,
    required this.completed,
    required this.goal,
    required this.streakDays,
  });

  final int completed;
  final int goal;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ratio = goal == 0 ? 0.0 : (completed / goal).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Günlük İlerlemen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (streakDays > 0)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 15,
                        color: AppColors.streak,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$streakDays günlük seri',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$completed',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ $goal egzersiz',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.outline),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  // Sayıya göre değişen ek ("%38'ini", "%30'unu") yok.
                  'Hedef: %$percent tamamlandı',
                  textAlign: TextAlign.end,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.all(Radius.circular(99)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ratio,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryContainer,
                        AppColors.secondary,
                        AppColors.secondaryContainer,
                      ],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.eco_outlined,
                size: 15,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _encouragement(ratio),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _encouragement(double ratio) {
    if (ratio >= 1) return 'Bugünkü hedefini tamamladın, tebrikler!';
    if (ratio > 0) return 'Harika gidiyorsun, omurgan sana teşekkür ediyor!';
    return 'İlk molanı verdiğinde ilerlemen burada görünecek.';
  }
}
