import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';

/// Ayar grubunun üstündeki büyük harfli başlık ("ÇALIŞMA & MOLA TERCİHLERİ").
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Satırları ince çizgilerle ayrılmış tek kart.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 64,
                color: AppColors.surfaceContainerHigh,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Simge, başlık, açıklama ve sağda kontrol (anahtar, değer, ok).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Satırın altında tam genişlikte gösterilen içerik (çipler gibi).
  final Widget? below;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    final below = this.below;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceContainerLow,
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
            if (below != null) ...[const SizedBox(height: 10), below],
          ],
        ),
      ),
    );
  }
}

/// Satırın sağındaki "30 dk ›" gibi değer + ok.
class SettingsValue extends StatelessWidget {
  const SettingsValue(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(Radius.circular(99)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.onSurface),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Seçilebilir küçük hap (mola süresi, saat, odak bölgesi).
class SettingsPill extends StatelessWidget {
  const SettingsPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : AppColors.onSurfaceVariant;
    final icon = this.icon;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerLow,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
