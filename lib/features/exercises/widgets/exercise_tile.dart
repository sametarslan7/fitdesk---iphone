import 'package:flutter/material.dart';

import '../../../core/data/exercise_catalog.dart';
import '../../../core/data/favorites.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/text_utils.dart';
import '../../../core/widgets/app_card.dart';

/// Egzersiz satırı: bölge simgesi, ad, süre/zorluk/duruş, favori ve başlat.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exercise,
    required this.onStart,
    this.showSummary = false,
  });

  final Exercise exercise;
  final VoidCallback onStart;

  /// Bölge sayfasında adın altında kısa açıklama da gösterilir.
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onStart,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: Icon(exercise.area.icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showSummary) ...[
                  const SizedBox(height: 2),
                  Text(
                    exercise.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        [
                          TextUtils.duration(exercise.durationSeconds),
                          exercise.difficulty.label,
                          exercise.posture.label,
                        ].join('  •  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          FavoriteButton(exercise: exercise),
          _PlayButton(name: exercise.name, onPressed: onStart),
        ],
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.of(context);
    final selected = favorites.contains(exercise);

    return IconButton(
      onPressed: () => favorites.toggle(exercise),
      tooltip: selected ? 'Favorilerden çıkar' : 'Favorilere ekle',
      isSelected: selected,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.favorite_border_rounded, color: AppColors.outline),
      selectedIcon: const Icon(Icons.favorite_rounded, color: AppColors.error),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.name, required this.onPressed});

  final String name;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name başlat',
      excludeSemantics: true,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.play_arrow_rounded,
              size: 24,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Egzersiz satırlarını dar alanda tek, geniş alanda iki sütunda dizer.
class ExerciseTileList extends StatelessWidget {
  const ExerciseTileList({
    super.key,
    required this.exercises,
    required this.onStart,
    this.showSummary = false,
  });

  final List<Exercise> exercises;
  final ValueChanged<Exercise> onStart;
  final bool showSummary;

  static const _spacing = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - _spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final exercise in exercises)
              SizedBox(
                width: itemWidth,
                child: ExerciseTile(
                  exercise: exercise,
                  showSummary: showSummary,
                  onStart: () => onStart(exercise),
                ),
              ),
          ],
        );
      },
    );
  }
}
