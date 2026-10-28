import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/data/activity.dart';
import 'stat_card_title.dart';

/// Bu ay en çok çalışılan bölgeler; çubuk uzunluğu toplamdaki payı.
class TopAreasCard extends StatelessWidget {
  const TopAreasCard({super.key, required this.areas});

  final List<AreaStat> areas;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = areas.fold(0, (sum, a) => sum + a.count);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StatCardTitle(
            icon: Icons.accessibility_new_rounded,
            title: 'En Çok Çalışılan Bölgeler',
            badge: 'Bu Ay',
          ),
          if (areas.isEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Bu ay henüz egzersiz yapmadın. Tamamladığın egzersizlerin '
              'bölgeleri burada görünecek.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          for (final stat in areas) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  stat.area.icon,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat.area.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge,
                  ),
                ),
                Text(
                  '${stat.count} egzersiz',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text(
                    '%${(stat.count / total * 100).round()}',
                    textAlign: TextAlign.end,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(99)),
              child: LinearProgressIndicator(
                value: stat.count / total,
                minHeight: 8,
                color: AppColors.primaryContainer,
                backgroundColor: AppColors.surfaceContainerHigh,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
