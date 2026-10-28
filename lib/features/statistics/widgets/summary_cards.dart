import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';

/// Üstteki büyük sayı: toplam tamamlanan egzersiz.
class TotalCompletedCard extends StatelessWidget {
  const TotalCompletedCard({
    super.key,
    required this.total,
    required this.thisWeek,
  });

  final int total;
  final int thisWeek;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: const Icon(
              Icons.verified_outlined,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TAMAMLANAN EGZERSİZ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      '$total',
                      style: textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '+$thisWeek bu hafta',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Küçük ölçüm kartı: "Mevcut Seri 3 Gün", "Toplam Süre 3 sa 25 dk".
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.tag,
    required this.parts,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String tag;

  /// Sayı ve birim çiftleri: [('3', 'sa'), ('25', 'dk')].
  final List<(String, String)> parts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final numberStyle = textTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.onSurface,
    );
    final unitStyle = textTheme.labelMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconBackground,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 8),
              // Dar kartta etiket simgeye çarpmasın, kısalsın.
              Expanded(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                    ),
                    child: Text(
                      tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  for (final (number, unit) in parts) ...[
                    TextSpan(text: number, style: numberStyle),
                    TextSpan(text: ' $unit ', style: unitStyle),
                  ],
                ],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
