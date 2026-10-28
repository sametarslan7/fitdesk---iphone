import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// İstatistik kartlarının başlık satırı: simge, başlık, sağda küçük rozet.
class StatCardTitle extends StatelessWidget {
  const StatCardTitle({
    super.key,
    required this.icon,
    required this.title,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final badge = this.badge;

    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.all(Radius.circular(99)),
            ),
            child: Text(
              badge,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
