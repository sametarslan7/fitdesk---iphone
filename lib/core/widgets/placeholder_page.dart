import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_colors.dart';

/// Henüz tasarımı kodlanmamış sekmeler için geçici sayfa.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(title, style: textTheme.headlineLarge),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 48, color: AppColors.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Bu ekran yakında burada olacak.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
