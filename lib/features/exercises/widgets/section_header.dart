import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Bölüm başlığı. Sağdaki metin [onTrailingTap] varsa bağlantı, yoksa rozet.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trailing = this.trailing;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          if (trailing != null && onTrailingTap != null)
            InkWell(
              onTap: onTrailingTap,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailing,
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
            )
          else if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.all(Radius.circular(99)),
              ),
              child: Text(
                trailing,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
