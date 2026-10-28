import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tasarımdaki beyaz, 16px köşeli, hafif gölgeli kart.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = AppColors.surfaceContainerLowest,
    this.onTap,
  });

  static const radius = BorderRadius.all(Radius.circular(16));

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
