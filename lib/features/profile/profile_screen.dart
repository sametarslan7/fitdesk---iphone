import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/activity.dart';
import '../../core/data/exercise_catalog.dart';
import '../../core/data/settings.dart';
import '../../core/layout/responsive.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../auth/auth_flow.dart';
import 'setting_detail_screen.dart';
import 'widgets/settings_group.dart';

/// Profil ve Ayarlar sekmesi. Buradaki ayarlar dokunulunca hemen kaydolur;
/// mola aralığı ve günlük hedef Kaydet butonlu kendi sayfalarında değişir.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const appVersion = '1.0.0';

  /// Bildirimler açılırken izin istenir; verilmezse ayar kapalı kalır.
  static Future<void> _setNotifications(
    BuildContext context,
    bool enabled,
  ) async {
    final controller = SettingsScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (enabled && !await NotificationService.instance.requestPermission()) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Bildirim izni verilmedi. İzni telefonun ayarlarından açabilirsin.',
            ),
          ),
        );
      return;
    }
    controller.update((s) => s.copyWith(notificationsEnabled: enabled));
  }

  static Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text(
          'Egzersizlerin ve istatistiklerin hesabında kalır; tekrar giriş '
          'yapınca geri gelir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthService.instance.signOut();
    if (context.mounted) showLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final controller = SettingsScope.of(context);
    final settings = controller.value;
    final activity = ActivityScope.of(context);
    final now = DateTime.now();

    void open(EditableSetting setting) =>
        Navigator.of(context).push(SettingDetailScreen.route(setting));

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

          final profile = _ProfileCard(
            name: AuthScope.userOf(context)?.displayName,
            email: AuthScope.userOf(context)?.email,
            streakDays: activity.currentStreak(now),
            completedToday: activity.today(now).length,
            dailyGoal: settings.dailyGoal,
            focusMode: settings.focusModeEnabled,
          );

          final work = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsSectionTitle('ÇALIŞMA & MOLA TERCİHLERİ'),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: Icons.timer_outlined,
                    title: 'Mola Hatırlatıcı Aralığı',
                    subtitle: 'Her çalışma seansından sonra',
                    trailing: SettingsValue(
                      '${settings.breakIntervalMinutes} dk',
                    ),
                    onTap: () => open(EditableSetting.breakInterval),
                  ),
                  SettingsTile(
                    icon: Icons.self_improvement_rounded,
                    title: 'Mola Süresi',
                    subtitle: 'Mikro esneme & nefes',
                    below: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final minutes in AppSettings.breakDurationOptions)
                          SettingsPill(
                            label: '$minutes dk',
                            selected: minutes == settings.breakDurationMinutes,
                            onTap: () => controller.update(
                              (s) => s.copyWith(breakDurationMinutes: minutes),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.schedule_rounded,
                    title: 'Çalışma Günleri & Saatleri',
                    subtitle: _workDaysSummary(settings.workDays),
                    below: _WorkSchedule(
                      settings: settings,
                      controller: controller,
                    ),
                  ),
                ],
              ),
            ],
          );

          final goals = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsSectionTitle('ERGONOMİ & HEDEFLER'),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: Icons.track_changes_rounded,
                    title: 'Günlük Egzersiz Hedefi',
                    subtitle:
                        'Önerilen: ${AppSettings.recommendedDailyGoal} '
                        'egzersiz / gün',
                    trailing: SettingsValue('${settings.dailyGoal} egzersiz'),
                    onTap: () => open(EditableSetting.dailyGoal),
                  ),
                  SettingsTile(
                    icon: Icons.accessibility_new_rounded,
                    title: 'Odak Bölgesi Önceliği',
                    subtitle: 'Masa başı gerginlik noktaların',
                    below: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final area in BodyAreas.all)
                          SettingsPill(
                            label: area.name,
                            icon: settings.focusAreaIds.contains(area.id)
                                ? Icons.check_rounded
                                : null,
                            selected: settings.focusAreaIds.contains(area.id),
                            onTap: () => controller.update((s) {
                              final ids = {...s.focusAreaIds};
                              if (!ids.remove(area.id)) ids.add(area.id);
                              return s.copyWith(focusAreaIds: ids);
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );

          final notifications = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsSectionTitle('BİLDİRİM & SES TERCİHLERİ'),
              SettingsGroup(
                children: [
                  _SwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Masa Başı Bildirimleri',
                    subtitle: 'Ekranda nazik esneme anımsatıcısı',
                    value: settings.notificationsEnabled,
                    onChanged: (v) => _setNotifications(context, v),
                  ),
                  _SwitchTile(
                    icon: Icons.music_note_outlined,
                    title: 'Sakin Ding Sesi & Titreşim',
                    subtitle: 'Dikkat dağıtmayan yumuşak ton',
                    value: settings.soundEnabled,
                    onChanged: (v) =>
                        controller.update((s) => s.copyWith(soundEnabled: v)),
                  ),
                  _SwitchTile(
                    icon: Icons.do_not_disturb_on_outlined,
                    title: 'Toplantı & Odak Modu',
                    subtitle: 'Açıkken hatırlatmalar susar',
                    value: settings.focusModeEnabled,
                    onChanged: (v) => controller.update(
                      (s) => s.copyWith(focusModeEnabled: v),
                    ),
                  ),
                ],
              ),
            ],
          );

          final account = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsSectionTitle('HESAP'),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'Çıkış Yap',
                    subtitle: AuthScope.userOf(context)?.email,
                    onTap: () => _confirmSignOut(context),
                  ),
                ],
              ),
            ],
          );

          final footer = _Footer(
            version: appVersion,
            intervalMinutes: settings.breakIntervalMinutes,
          );

          final List<Widget> children = wide
              ? [
                  profile,
                  SizedBox(height: gap),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: work),
                      SizedBox(width: gap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            goals,
                            SizedBox(height: gap),
                            notifications,
                            SizedBox(height: gap),
                            account,
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  footer,
                ]
              : [
                  profile,
                  SizedBox(height: gap),
                  work,
                  SizedBox(height: gap),
                  goals,
                  SizedBox(height: gap),
                  notifications,
                  SizedBox(height: gap),
                  account,
                  SizedBox(height: gap),
                  footer,
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
                  subtitle: 'Profil ve Ayarlar',
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

/// "Pazartesi – Cuma · 5 gün", "Salı, Perşembe · 2 gün", "Her gün".
String _workDaysSummary(Set<int> days) {
  final sorted = days.toList()..sort();
  if (sorted.length == 7) return 'Her gün';
  final consecutive = sorted.last - sorted.first == sorted.length - 1;
  final names = switch (sorted.length) {
    1 => weekdayNames[sorted.first - 1],
    2 => sorted.map((d) => weekdayNames[d - 1]).join(', '),
    _ when consecutive =>
      '${weekdayNames[sorted.first - 1]} – ${weekdayNames[sorted.last - 1]}',
    _ => sorted.map((d) => weekdayShortNames[d - 1]).join(', '),
  };
  return '$names · ${sorted.length} gün';
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.streakDays,
    required this.completedToday,
    required this.dailyGoal,
    required this.focusMode,
  });

  final String? name;
  final String? email;
  final int streakDays;
  final int completedToday;
  final int dailyGoal;
  final bool focusMode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.secondaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null ? 'Merhaba!' : 'Merhaba $name!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      email ?? 'Masa başı çalışan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoPill(
                          icon: Icons.local_fire_department_outlined,
                          label: '$streakDays Gün Seri',
                        ),
                        if (focusMode)
                          const _InfoPill(
                            icon: Icons.do_not_disturb_on_outlined,
                            label: 'Odak Modu',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.accessibility_new_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Günlük Tamamlama',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completedToday / $dailyGoal egzersiz',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              value: (completedToday / dailyGoal).clamp(0.0, 1.0),
              minHeight: 8,
              color: AppColors.primaryContainer,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(Radius.circular(99)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SettingsTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.secondary,
        ),
      ),
    );
  }
}

/// Çalışma günleri (dokununca seçilir/kaldırılır) ile mesai başlangıç ve
/// bitişi (dokununca saat seçici açılır).
class _WorkSchedule extends StatelessWidget {
  const _WorkSchedule({required this.settings, required this.controller});

  final AppSettings settings;
  final SettingsController controller;

  Future<void> _pick(BuildContext context, {required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: start ? settings.workStart : settings.workEnd,
      helpText: start ? 'Mesai başlangıcı' : 'Mesai bitişi',
    );
    if (picked == null || !context.mounted) return;

    final newStart = start ? picked : settings.workStart;
    final newEnd = start ? settings.workEnd : picked;
    if (_minutes(newEnd) <= _minutes(newStart)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Bitiş saati başlangıçtan sonra olmalı.'),
          ),
        );
      return;
    }
    controller.update((s) => s.copyWith(workStart: newStart, workEnd: newEnd));
  }

  static int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  void _toggleDay(BuildContext context, int day) {
    // Art arda dokunuşlar ekran yenilenmeden gelebilir; güncel değeri oku.
    final days = {...controller.value.workDays};
    if (days.contains(day) && days.length == 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('En az bir çalışma günü seçili olmalı.'),
          ),
        );
      return;
    }
    if (!days.remove(day)) days.add(day);
    controller.update((s) => s.copyWith(workDays: days));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var day = 1; day <= 7; day++) ...[
              if (day > 1) const SizedBox(width: 4),
              Expanded(
                child: _DayToggle(
                  label: weekdayShortNames[day - 1],
                  tooltip: weekdayNames[day - 1],
                  selected: settings.workDays.contains(day),
                  onTap: () => _toggleDay(context, day),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _buildHours(context),
      ],
    );
  }

  Widget _buildHours(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        SettingsPill(
          label: _format(settings.workStart),
          icon: Icons.login_rounded,
          selected: false,
          onTap: () => _pick(context, start: true),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '–',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        SettingsPill(
          label: _format(settings.workEnd),
          icon: Icons.logout_rounded,
          selected: false,
          onTap: () => _pick(context, start: false),
        ),
      ],
    );
  }

  static String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Haftanın bir günü için eşit genişlikte seçim düğmesi.
class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : AppColors.onSurfaceVariant;

    return Semantics(
      label: tooltip,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerLow,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.version, required this.intervalMinutes});

  final String version;
  final int intervalMinutes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          'FitDesk v$version • Masa Başı Sağlık Asistanı',
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.outline,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '"Bedenine kulak ver, her $intervalMinutes dakikada bir nefes al."',
          textAlign: TextAlign.center,
          style: textTheme.labelMedium?.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
