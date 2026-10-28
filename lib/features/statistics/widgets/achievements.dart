import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/data/activity.dart';

/// Koyu yeşil "Kişisel Rekorun" kartı.
class PersonalRecordCard extends StatelessWidget {
  const PersonalRecordCard({
    super.key,
    required this.longestStreak,
    required this.weeklyPeak,
  });

  final int longestStreak;
  final int weeklyPeak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondaryFixed,
                child: Icon(
                  Icons.military_tech_outlined,
                  size: 20,
                  color: AppColors.onSecondaryFixed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kişisel Rekorun',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RecordTile(
                  icon: Icons.emoji_events_outlined,
                  label: 'EN UZUN SERİ',
                  value: '$longestStreak Gün',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RecordTile(
                  icon: Icons.bolt_rounded,
                  label: 'HAFTALIK ZİRVE',
                  value: '$weeklyPeak Egzersiz',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.spa_outlined,
                size: 18,
                color: AppColors.secondaryFixed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  longestStreak == 0
                      ? 'İlk egzersizini tamamla, rekorların burada görünsün.'
                      : 'Harika bir istikrar! Masa başı duruş sağlığın her '
                            'geçen gün güçleniyor.',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.secondaryFixed),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.secondaryFixed,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rozetler: başlık + yan yana kartlar. Kazanılmayanlar soluk ve kilitli.
class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key, required this.badges});

  final List<AchievementBadge> badges;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final earned = badges.where((b) => b.earned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Kazanılan Rozetler',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 11,
              backgroundColor: AppColors.secondaryContainer.withValues(
                alpha: 0.6,
              ),
              child: Text(
                '$earned',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final badge in badges) ...[
                Expanded(child: _BadgeCard(badge: badge)),
                if (badge != badges.last) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final earned = badge.earned;

    return Semantics(
      label: earned ? null : 'Kilitli rozet',
      child: Opacity(
        opacity: earned ? 1 : 0.55,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: earned
                    ? AppColors.secondaryContainer.withValues(alpha: 0.4)
                    : AppColors.surfaceContainerHigh,
                child: Icon(
                  earned ? badge.icon : Icons.lock_outline_rounded,
                  size: 24,
                  color: earned ? AppColors.primary : AppColors.outline,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.detail,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: earned ? AppColors.secondary : AppColors.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
