import 'package:flutter/material.dart';

import '../../../core/data/exercise_catalog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';

/// Vücut bölgesi kartları: dar alanda 2, geniş alanda 4 sütun.
class AreaGrid extends StatelessWidget {
  const AreaGrid({super.key, required this.areas, required this.onAreaTap});

  final List<BodyArea> areas;
  final ValueChanged<BodyArea> onAreaTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // 8 bölge 2 ya da 4 sütuna düzgün bölünür.
          crossAxisCount: constraints.maxWidth >= 560 ? 4 : 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          // Büyük yazı ayarında kart da uzar.
          mainAxisExtent: MediaQuery.textScalerOf(context).scale(128),
        ),
        children: [
          for (final area in areas)
            _AreaCard(area: area, onTap: () => onAreaTap(area)),
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.onTap});

  final BodyArea area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = ExerciseCatalog.countFor(area);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.secondaryContainer.withValues(
                  alpha: 0.35,
                ),
                child: Icon(area.icon, size: 21, color: AppColors.primary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                ),
                child: Text(
                  '$count',
                  semanticsLabel: '$count egzersiz',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            area.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            area.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
