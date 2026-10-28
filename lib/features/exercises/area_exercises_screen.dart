import 'package:flutter/material.dart';

import '../../core/data/exercise_catalog.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/text_utils.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/tip_banner.dart';
import 'exercise_actions.dart';
import 'widgets/exercise_tile.dart';
import 'widgets/section_header.dart';

/// Bir vücut bölgesinin egzersizleri ("Boyun Egzersizleri").
class AreaExercisesScreen extends StatelessWidget {
  const AreaExercisesScreen({super.key, required this.area});

  final BodyArea area;

  static Route<void> route(BodyArea area) =>
      MaterialPageRoute(builder: (_) => AreaExercisesScreen(area: area));

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final exercises = ExerciseCatalog.byArea(area);
    final totalSeconds = exercises.fold(0, (sum, e) => sum + e.durationSeconds);

    return Material(
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final wide = Responsive.sizeOf(width) == ScreenSize.expanded;
          final maxWidth = wide
              ? Responsive.maxWideWidth
              : Responsive.maxSingleColumnWidth;
          final inset = Responsive.horizontalInset(width, maxWidth: maxWidth);
          final gap = Responsive.sectionSpacing(width);

          final hero = _AreaHero(
            area: area,
            exerciseCount: exercises.length,
            totalSeconds: totalSeconds,
            onStartRoutine: exercises.isEmpty
                ? null
                : () => startRoutine(context, area),
          );
          final routine = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Önerilen Rutin',
                trailing: 'Toplam ${TextUtils.duration(totalSeconds)}',
              ),
              ExerciseTileList(
                exercises: exercises,
                showSummary: true,
                onStart: (exercise) => startExercise(context, exercise),
              ),
            ],
          );
          final tip = TipBanner(
            title: 'Fizyoterapist Notu',
            body: area.tip,
            icon: Icons.health_and_safety_outlined,
          );

          final List<Widget> children = wide
              ? [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            hero,
                            SizedBox(height: gap),
                            tip,
                          ],
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(flex: 6, child: routine),
                    ],
                  ),
                ]
              : [
                  hero,
                  SizedBox(height: gap),
                  routine,
                  SizedBox(height: gap),
                  tip,
                ];

          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  padding.top + AppHeader.height + 12,
                  inset,
                  // Alt menü yüksekliği padding.bottom içinde zaten var.
                  padding.bottom + 16,
                ),
                children: children,
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppHeader(
                  title: '${area.name} Egzersizleri',
                  subtitle: 'Egzersizler',
                  onBack: () => Navigator.of(context).maybePop(),
                  maxContentWidth: maxWidth,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AreaHero extends StatelessWidget {
  const _AreaHero({
    required this.area,
    required this.exerciseCount,
    required this.totalSeconds,
    required this.onStartRoutine,
  });

  final BodyArea area;
  final int exerciseCount;
  final int totalSeconds;
  final VoidCallback? onStartRoutine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.secondaryFixed,
                child: Icon(
                  area.icon,
                  size: 22,
                  color: AppColors.onSecondaryFixed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ODAK: ${TextUtils.upper(area.name)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.secondaryFixed,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            area.description,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.onPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.spa_outlined,
                label: '$exerciseCount egzersiz',
              ),
              _HeroPill(
                icon: Icons.schedule_rounded,
                label: TextUtils.duration(totalSeconds),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStartRoutine,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryFixed,
                foregroundColor: AppColors.onSecondaryFixed,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Seriyi Başlat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(99)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.onPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}
