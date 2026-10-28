import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/data/exercise_catalog.dart';

/// Vücut bölgelerine göre egzersiz kategorileri (2 sütunlu ızgara).
class BodyAreaSection extends StatelessWidget {
  const BodyAreaSection({
    super.key,
    required this.areas,
    required this.onSeeAll,
    required this.onAreaTap,
  });

  final List<BodyArea> areas;
  final VoidCallback onSeeAll;
  final ValueChanged<BodyArea> onAreaTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = ExerciseCatalog.all.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tüm Egzersizler',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            InkWell(
              onTap: onSeeAll,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tümünü Gör ($total)',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // Dar alanda 2, geniş alanda 4 sütun (3 sütunda 4 bölgeden
              // biri tek başına kalıyordu).
              crossAxisCount: constraints.maxWidth >= 600 ? 4 : 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              // Büyük yazı ayarında kart da uzar.
              mainAxisExtent: MediaQuery.textScalerOf(context).scale(64),
            ),
            children: [
              for (final area in areas)
                AppCard(
                  onTap: () => onAreaTap(area),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceContainerLow,
                        child: Icon(
                          area.icon,
                          size: 19,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              area.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelLarge,
                            ),
                            Text(
                              '${ExerciseCatalog.countFor(area)} egzersiz',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
