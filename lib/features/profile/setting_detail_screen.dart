import 'package:flutter/material.dart';

import '../../core/data/settings.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import 'widgets/settings_group.dart';

/// Profil'den açılan, tek bir ayarı düzenleyen sayfalar.
enum EditableSetting {
  breakInterval('Mola Aralığı', 'ÇALIŞMA & MOLA AYARLARI'),
  dailyGoal('Günlük Egzersiz Hedefi', 'ERGONOMİ & HEDEFLER');

  const EditableSetting(this.title, this.section);

  final String title;
  final String section;

  int read(AppSettings s) => switch (this) {
    breakInterval => s.breakIntervalMinutes,
    dailyGoal => s.dailyGoal,
  };

  AppSettings write(AppSettings s, int value) => switch (this) {
    breakInterval => s.copyWith(breakIntervalMinutes: value),
    dailyGoal => s.copyWith(dailyGoal: value),
  };

  String describe(int value) => switch (this) {
    breakInterval => '$title: $value dk',
    dailyGoal => '$title: $value egzersiz',
  };
}

/// Tek bir ayarın sayfası. Değişiklik Kaydet'e basınca uygulanır; kaydetmeden
/// çıkılırsa onay istenir.
class SettingDetailScreen extends StatefulWidget {
  const SettingDetailScreen({super.key, required this.setting});

  final EditableSetting setting;

  static Route<void> route(EditableSetting setting) =>
      MaterialPageRoute(builder: (_) => SettingDetailScreen(setting: setting));

  @override
  State<SettingDetailScreen> createState() => _SettingDetailScreenState();
}

class _SettingDetailScreenState extends State<SettingDetailScreen> {
  int? _draft;

  int get _saved => widget.setting.read(SettingsScope.of(context).value);
  int get _value => _draft ?? _saved;
  bool get _dirty => _value != _saved;

  void _save() {
    final value = _value;
    SettingsScope.of(context).update((s) => widget.setting.write(s, value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Ayar kaydedildi.')));
    Navigator.of(context).pop();
  }

  Future<void> _confirmLeave() async {
    final discard = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _UnsavedChangesSheet(summary: widget.setting.describe(_value)),
    );
    // Navigator.pop, PopScope'u atlar; onay verildiği için doğrudan çık.
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final dirty = _dirty;
    void select(int v) => setState(() => _draft = v);

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Material(
        color: AppColors.surface,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final inset = Responsive.horizontalInset(width);
            final gap = Responsive.sectionSpacing(width);

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
                  children: [
                    SettingsSectionTitle(widget.setting.section),
                    switch (widget.setting) {
                      EditableSetting.breakInterval => _IntervalCard(
                        selected: _value,
                        onSelected: select,
                      ),
                      EditableSetting.dailyGoal => _GoalCard(
                        selected: _value,
                        onSelected: select,
                      ),
                    },
                    SizedBox(height: gap),
                    if (dirty) ...[
                      const _ChangesBanner(),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      onPressed: dirty ? _save : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Kaydet'),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AppHeader(
                    title: widget.setting.title,
                    subtitle: 'Profil ve Ayarlar',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _IntervalCard extends StatelessWidget {
  const _IntervalCard({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const _labels = {15: 'Hızlı', 30: 'Dengeli', 45: 'Derin'};

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.hourglass_bottom_rounded,
      title: 'Mola Aralığı',
      description: 'Molalar arasındaki çalışma süresini belirle.',
      children: [
        _OptionGrid(
          children: [
            for (final minutes in AppSettings.breakIntervalOptions)
              _OptionBox(
                value: '$minutes dk',
                label: _labels[minutes] ?? '',
                selected: minutes == selected,
                onTap: () => onSelected(minutes),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const _Note(
          icon: Icons.lightbulb_outline_rounded,
          text:
              'Öneri: Odaklanmanı bozmadan duruş farkındalığı kazanmak için '
              '30 dakikada bir kısa mola idealdir.',
        ),
        const SizedBox(height: 8),
        const _Note(
          icon: Icons.info_outline_rounded,
          highlighted: true,
          text:
              'Çalışan bir geri sayım varsa yeni aralık, mevcut seans '
              'bittiğinde devreye girer.',
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.track_changes_rounded,
      title: 'Günlük Egzersiz Hedefi',
      description: 'Gün içinde tamamlamak istediğin egzersiz sayısını seç.',
      children: [
        _OptionGrid(
          children: [
            for (final goal in AppSettings.dailyGoalOptions)
              _OptionBox(
                value: '$goal',
                label: 'egzersiz',
                selected: goal == selected,
                recommended: goal == AppSettings.recommendedDailyGoal,
                onTap: () => onSelected(goal),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _Note(
          icon: Icons.verified_outlined,
          text:
              'Günde $selected kısa egzersiz, gün boyu düzenli hareket '
              'etmeni sağlar.',
        ),
      ],
    );
  }
}

/// Seçenek kutuları; 3 sütun.
class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      // Büyük yazı ayarında kutu da uzar.
      childAspectRatio: 1.45 / MediaQuery.textScalerOf(context).scale(1),
      children: children,
    );
  }
}

class _OptionBox extends StatelessWidget {
  const _OptionBox({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
    this.recommended = false,
  });

  final String value;
  final String label;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = selected ? AppColors.onPrimary : AppColors.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      label: '$value $label${recommended ? ', önerilen' : ''}',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // Dar kutuda içerik taşmak yerine biraz küçülür.
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (recommended)
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryFixed,
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                        ),
                        child: Text(
                          'ÖNERİLEN',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 8,
                            color: AppColors.onSecondaryFixed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 15,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          value,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        color: selected
                            ? AppColors.onPrimary.withValues(alpha: 0.8)
                            : AppColors.onSurfaceVariant,
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

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.text,
    this.highlighted = false,
  });

  final IconData icon;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.secondaryContainer.withValues(alpha: 0.3)
            : AppColors.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: highlighted
                ? AppColors.onSecondaryContainer
                : AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: highlighted
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangesBanner extends StatelessWidget {
  const _ChangesBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 5, backgroundColor: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Değişiklik yapıldı • henüz kaydedilmedi',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kaydetmeden çıkarken alttan açılan onay. true: değişiklikleri at.
class _UnsavedChangesSheet extends StatelessWidget {
  const _UnsavedChangesSheet({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.secondaryFixed,
                    child: Icon(
                      Icons.edit_note_rounded,
                      size: 30,
                      color: AppColors.onSecondaryFixed,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Kaydedilmemiş Değişiklikler',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Yaptığın değişiklikler kaydedilmedi. Çıkarsan kaybolacak.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                  child: Text(
                    summary,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorContainer,
                    foregroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Değişiklikleri At'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Düzenlemeye Devam Et'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
