import 'package:flutter/material.dart';

import '../../core/data/exercise_catalog.dart';
import '../../core/data/favorites.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/text_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/tip_banner.dart';
import 'area_exercises_screen.dart';
import 'exercise_actions.dart';
import 'widgets/area_grid.dart';
import 'widgets/exercise_tile.dart';
import 'widgets/section_header.dart';

enum ExerciseFilter {
  all('Tümü', Icons.apps_rounded),
  favorites('Favorilerim', Icons.favorite_rounded),
  short('Kısa (≤30 sn)', Icons.bolt_rounded),
  seated('Oturarak', Icons.chair_outlined),
  standing('Ayakta', Icons.accessibility_new_rounded);

  const ExerciseFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  bool matches(Exercise exercise, FavoritesController store) => switch (this) {
    all => true,
    favorites => store.contains(exercise),
    short => exercise.durationSeconds <= 30,
    seated => exercise.posture == Posture.seated,
    standing => exercise.posture == Posture.standing,
  };
}

/// Egzersiz kütüphanesi: arama, filtreler, vücut bölgeleri ve favoriler.
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  /// Popüler ve favori listelerinde gösterilen en fazla egzersiz.
  static const _previewCount = 3;

  final _searchController = TextEditingController();
  var _filter = ExerciseFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim();

  /// Arama ya da filtre yoksa bölgeler ve öneriler gösterilir.
  bool get _browsing => _query.isEmpty && _filter == ExerciseFilter.all;

  List<Exercise> _results(FavoritesController favorites) {
    final query = TextUtils.fold(_query);
    return [
      for (final exercise in ExerciseCatalog.all)
        if (_filter.matches(exercise, favorites) &&
            (query.isEmpty ||
                TextUtils.fold(
                  '${exercise.name} ${exercise.area.name} '
                  '${exercise.area.subtitle}',
                ).contains(query)))
          exercise,
    ];
  }

  void _openArea(BodyArea area) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(AreaExercisesScreen.route(area));
  }

  void _start(Exercise exercise) => startExercise(context, exercise);

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final favorites = FavoritesScope.of(context);

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

          final top = [
            const _Intro(),
            const SizedBox(height: 16),
            _SearchField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _FilterChips(
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            SizedBox(height: gap),
          ];

          final List<Widget> body;
          if (!_browsing) {
            body = [
              _ResultsSection(
                results: _results(favorites),
                filter: _filter,
                onStart: _start,
              ),
            ];
          } else {
            final areas = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'Vücut Bölgeleri',
                  trailing: '${BodyAreas.all.length} bölge',
                ),
                AreaGrid(areas: BodyAreas.all, onAreaTap: _openArea),
              ],
            );
            final favoriteList = favorites.exercises;
            final suggestions = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Favori varsa popülerlerin üstünde ayrı bir bölüm olarak çıkar.
                if (favoriteList.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Favori Egzersizler',
                    trailing: 'Tümünü Gör (${favoriteList.length})',
                    onTrailingTap: () =>
                        setState(() => _filter = ExerciseFilter.favorites),
                  ),
                  ExerciseTileList(
                    exercises: favoriteList.take(_previewCount).toList(),
                    onStart: _start,
                  ),
                  SizedBox(height: gap),
                ],
                const SectionHeader(title: 'Popüler Egzersizler'),
                ExerciseTileList(
                  exercises: ExerciseCatalog.popular
                      .take(_previewCount)
                      .toList(),
                  onStart: _start,
                ),
              ],
            );
            const tip = TipBanner(
              title: 'Günün Ergonomi Notu',
              body:
                  'Her 45 dakikada bir 30 saniye omuzlarını geriye '
                  'yuvarlamak kamburlaşmayı önlemeye yardımcı olur.',
            );

            body = wide
                ? [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: areas),
                        SizedBox(width: gap),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              suggestions,
                              SizedBox(height: gap),
                              tip,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]
                : [
                    areas,
                    SizedBox(height: gap),
                    suggestions,
                    SizedBox(height: gap),
                    tip,
                  ];
          }

          return Stack(
            children: [
              GestureDetector(
                // Klavyeyi boş alana dokunulunca kapat.
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    inset,
                    padding.top + AppHeader.height + 8,
                    inset,
                    // Alt menü yüksekliği padding.bottom içinde zaten var.
                    padding.bottom + 16,
                  ),
                  children: [...top, ...body],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppHeader(
                  subtitle: 'Egzersizler',
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

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.all(Radius.circular(99)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.eco_outlined,
                size: 14,
                color: AppColors.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'EGZERSİZ KÜTÜPHANESİ',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Egzersizler',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Masa başında dikkatin dağılmadan yapabileceğin sessiz esneme ve '
          'rahatlama hareketleri.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
    borderSide: BorderSide.none,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppCard.radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Egzersiz veya bölge ara...',
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.onSurfaceVariant,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Aramayı temizle',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          border: _border,
          enabledBorder: _border,
          focusedBorder: _border.copyWith(
            borderSide: const BorderSide(color: AppColors.secondary),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final ExerciseFilter selected;
  final ValueChanged<ExerciseFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final filter in ExerciseFilter.values) ...[
            ChoiceChip(
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
              showCheckmark: false,
              avatar: Icon(
                filter.icon,
                size: 16,
                color: filter == selected
                    ? AppColors.onPrimary
                    : filter == ExerciseFilter.favorites
                    ? AppColors.error
                    : AppColors.onSurfaceVariant,
              ),
              label: Text(filter.label),
              labelStyle: textTheme.labelMedium?.copyWith(
                color: filter == selected
                    ? AppColors.onPrimary
                    : AppColors.onSurface,
              ),
              selectedColor: AppColors.primaryContainer,
              backgroundColor: AppColors.surfaceContainerLowest,
              side: BorderSide.none,
              shape: const StadiumBorder(),
            ),
            if (filter != ExerciseFilter.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({
    required this.results,
    required this.filter,
    required this.onStart,
  });

  final List<Exercise> results;
  final ExerciseFilter filter;
  final ValueChanged<Exercise> onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: filter == ExerciseFilter.all ? 'Sonuçlar' : filter.label,
          trailing: '${results.length} egzersiz',
        ),
        if (results.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  filter == ExerciseFilter.favorites
                      ? Icons.favorite_border_rounded
                      : Icons.search_off_rounded,
                  size: 32,
                  color: AppColors.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  filter == ExerciseFilter.favorites
                      ? 'Henüz favori egzersizin yok. Kalp simgesine '
                            'dokunarak ekleyebilirsin.'
                      : 'Aramana uygun egzersiz bulunamadı.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ExerciseTileList(exercises: results, onStart: onStart),
      ],
    );
  }
}
