import 'dart:ui';

import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';

/// Sekme sayfalarının üstünde sabit duran, buzlu cam görünümlü başlık:
/// logo (ya da geri butonu), başlık ve alt başlık.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.title = AppLogo.appName,
    required this.subtitle,
    this.onBack,
    this.maxContentWidth = Responsive.maxSingleColumnWidth,
  });

  static const height = 60.0;

  final String title;
  final String subtitle;

  /// Verilirse logo yerine geri butonu gösterilir (alt sayfalar).
  final VoidCallback? onBack;

  /// Sayfa içeriğiyle aynı hizada durması için içerikle aynı genişlik.
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: height,
              child: ResponsiveCenter(
                maxWidth: maxContentWidth,
                child: Row(
                  children: [
                    if (onBack == null)
                      const AppLogo(size: 34, showWordmark: false)
                    else
                      IconButton(
                        onPressed: onBack,
                        tooltip: 'Geri',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
