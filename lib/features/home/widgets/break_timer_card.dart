import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/config/dev_flags.dart';
import '../../../core/data/activity.dart';
import '../../../core/data/exercise_catalog.dart';
import '../../../core/notifications/break_reminders.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/text_utils.dart';
import '../../../core/widgets/app_card.dart';

/// Sayacın şu an çalışıp çalışamayacağı.
enum _Availability { available, offDay, beforeHours, afterHours }

/// Sonraki molaya geri sayan merkezi kart. Süre bitince rastgele bir bölgeden
/// egzersiz önerir; butona basılınca [onBreakDue] ile o egzersiz başlar.
/// Sadece [workDays] içindeki günlerde, [workStart]–[workEnd] arasında çalışır.
class BreakTimerCard extends StatefulWidget {
  const BreakTimerCard({
    super.key,
    required this.intervalMinutes,
    required this.workDays,
    required this.workStart,
    required this.workEnd,
    required this.onBreakDue,
    this.onSessionChanged,
  });

  /// Şimdiki zaman; testler sabit bir gün/saat verebilsin diye değiştirilebilir.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// Ayarlardaki aralık. Sayaç çalışırken değişirse yeni aralık mevcut seans
  /// bittiğinde devreye girer.
  final int intervalMinutes;

  /// Ayarlardaki çalışma günleri ([DateTime.weekday]) ve mesai saatleri. Süren
  /// seans, ayar değişince ya da zaman mesai dışına çıkınca durur.
  final Set<int> workDays;
  final TimeOfDay workStart;
  final TimeOfDay workEnd;
  final ValueChanged<Exercise> onBreakDue;

  /// Sayaç durumu her değiştiğinde çağrılır (hatırlatma bildirimleri için).
  final BreakSessionCallback? onSessionChanged;

  @override
  State<BreakTimerCard> createState() => _BreakTimerCardState();
}

class _BreakTimerCardState extends State<BreakTimerCard>
    with WidgetsBindingObserver {
  late int _intervalMinutes = widget.intervalMinutes;
  late int _remaining = _total;
  BreakTimerStatus _state = BreakTimerStatus.idle;
  Timer? _ticker;

  /// Sayaç beklerken mesai başlayınca/bitince kartı yeniler.
  Timer? _clockTicker;

  /// Süre bitince seçilen mola egzersizi.
  Exercise? _suggestion;

  /// Süren seansın bitiş anı. Arka planda sayaç durabildiği için uygulamaya
  /// dönünce kalan süre buradan yeniden hesaplanır.
  DateTime? _endsAt;

  int get _total => _intervalMinutes * DevFlags.secondsPerIntervalUnit;

  _Availability get _availability {
    final now = BreakTimerCard.clock();
    if (!widget.workDays.contains(now.weekday)) return _Availability.offDay;
    final minutes = now.hour * 60 + now.minute;
    if (minutes < _minutesOf(widget.workStart)) {
      return _Availability.beforeHours;
    }
    if (minutes >= _minutesOf(widget.workEnd)) return _Availability.afterHours;
    return _Availability.available;
  }

  static int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  static String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Yarından başlayarak ilk çalışma gününün adı.
  String get _nextWorkDayName {
    final today = BreakTimerCard.clock().weekday;
    for (var i = 1; i <= 7; i++) {
      final day = (today - 1 + i) % 7 + 1;
      if (widget.workDays.contains(day)) return weekdayNames[day - 1];
    }
    return weekdayNames[today - 1];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_state == BreakTimerStatus.idle) setState(() {});
    });
  }

  @override
  void didUpdateWidget(BreakTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_availability != _Availability.available &&
        _state != BreakTimerStatus.idle) {
      _reset(widget.intervalMinutes);
      return;
    }
    final idle =
        _state == BreakTimerStatus.idle || _state == BreakTimerStatus.finished;
    if (widget.intervalMinutes != _intervalMinutes && idle) {
      _reset(widget.intervalMinutes);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _clockTicker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final endsAt = _endsAt;
    if (_state != BreakTimerStatus.running || endsAt == null) {
      setState(() {});
      return;
    }
    // Arka planda kaçırılan saniyeleri yakala; bir sonraki tik mesai dışına
    // çıkıldıysa seansı durdurur.
    final left = endsAt.difference(BreakTimerCard.clock()).inSeconds;
    _remaining = math.max(left, 1);
    _tick();
  }

  /// Durumu değiştirir ve hatırlatmalara bildirir. Bitiş anı bitince de
  /// tutulur; Android'de arka planda tik sürerken bildirim gelmeden iptal
  /// edilmesin.
  void _setStatus(BreakTimerStatus status, {DateTime? endsAt}) {
    _state = status;
    _endsAt = endsAt;
    widget.onSessionChanged?.call(status, endsAt);
  }

  void _reset(int minutes) {
    _ticker?.cancel();
    setState(() {
      _intervalMinutes = minutes;
      _remaining = _total;
      _setStatus(BreakTimerStatus.idle);
      _suggestion = null;
    });
  }

  void _onMainButton() {
    switch (_state) {
      case BreakTimerStatus.idle:
      case BreakTimerStatus.paused:
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
        final endsAt = BreakTimerCard.clock().add(
          Duration(seconds: _remaining),
        );
        setState(() => _setStatus(BreakTimerStatus.running, endsAt: endsAt));
      case BreakTimerStatus.running:
        _ticker?.cancel();
        setState(() => _setStatus(BreakTimerStatus.paused));
      case BreakTimerStatus.finished:
        widget.onBreakDue(_suggestion ?? ExerciseCatalog.suggestForBreak());
        _reset(widget.intervalMinutes);
    }
  }

  void _tick() {
    if (_availability != _Availability.available) {
      _reset(widget.intervalMinutes);
      return;
    }
    setState(() {
      _remaining--;
      if (_remaining <= 0) {
        _remaining = 0;
        _ticker?.cancel();
        _setStatus(BreakTimerStatus.finished, endsAt: _endsAt);
        _suggestion = ExerciseCatalog.suggestForBreak();
      }
    });
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Sayaç çalışamıyorken başlık, devre dışı düğme ve alttaki not.
  ({String title, IconData icon, String button, String note})?
  get _unavailable => switch (_availability) {
    _Availability.available => null,
    _Availability.offDay => (
      title: 'BUGÜN ÇALIŞMA GÜNÜN DEĞİL',
      icon: Icons.weekend_outlined,
      button: 'Bugün Dinlenme Günü',
      note:
          'Sonraki çalışma günün $_nextWorkDayName. '
          'Günleri Profil’den değiştirebilirsin.',
    ),
    _Availability.beforeHours => (
      title: 'MESAİN HENÜZ BAŞLAMADI',
      icon: Icons.schedule_rounded,
      button: 'Mesai ${_format(widget.workStart)} ile başlar',
      note:
          'Sayaç mesai saatlerinde çalışır. '
          'Saatleri Profil’den değiştirebilirsin.',
    ),
    _Availability.afterHours => (
      title: 'BUGÜNKÜ MESAİN BİTTİ',
      icon: Icons.nights_stay_outlined,
      button: 'Mesai Bitti',
      note:
          'Sonraki çalışma günün $_nextWorkDayName, '
          'mesai ${_format(widget.workStart)} ile başlar.',
    ),
  };

  (IconData, String) get _buttonContent => switch (_state) {
    BreakTimerStatus.idle => (Icons.play_arrow_rounded, 'Çalışmaya Başla'),
    BreakTimerStatus.running => (Icons.pause_rounded, 'Duraklat'),
    BreakTimerStatus.paused => (Icons.play_arrow_rounded, 'Devam Et'),
    BreakTimerStatus.finished => (
      Icons.celebration_rounded,
      'Egzersize Başla!',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (buttonIcon, buttonLabel) = _buttonContent;

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildContent(
            textTheme,
            buttonIcon,
            buttonLabel,
            constraints.maxWidth,
          );
        },
      ),
    );
  }

  Widget _buildContent(
    TextTheme textTheme,
    IconData buttonIcon,
    String buttonLabel,
    double cardWidth,
  ) {
    // Kart içindeki her şey kart genişliğiyle orantılı büyür/küçülür.
    // Ölçek 1 = normal telefon (≈380px kart).
    final ringSize = (cardWidth * 0.5).clamp(150.0, 300.0);
    final scale = ringSize / 190;
    // Yazılar halka kadar büyümesin, okunur aralıkta kalsın.
    final textScale = scale.clamp(0.85, 1.35);
    final buttonWidth = (cardWidth * 0.7).clamp(220.0, 440.0);
    final unavailable = _unavailable;

    return Stack(
      children: [
        // Köşelerdeki yumuşak renk lekeleri.
        const Positioned(
          top: -40,
          right: -40,
          child: _Glow(color: AppColors.secondaryContainer),
        ),
        const Positioned(
          bottom: -32,
          left: -32,
          child: _Glow(color: AppColors.primaryFixed),
        ),
        // Stack içeriği kendi genişliğine büzüşmesin diye tam genişlik.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            children: [
              _StatusPill(active: _state == BreakTimerStatus.running),
              const SizedBox(height: 8),
              Text(
                unavailable?.title ??
                    (_state == BreakTimerStatus.finished
                        ? 'MOLA ZAMANI'
                        : 'SONRAKİ MOLAYA KALAN SÜRE'),
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 11 * textScale,
                  color: AppColors.outline,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ),
              SizedBox(height: 8 * scale),
              SizedBox.square(
                dimension: ringSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _remaining / _total),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => CustomPaint(
                    painter: _RingPainter(progress: value),
                    child: child,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 26 * scale),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatted,
                            style: textTheme.headlineLarge?.copyWith(
                              fontSize: 34 * scale,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.timer_outlined,
                            size: 16 * textScale,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              SizedBox(
                width: buttonWidth,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4D003621),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: unavailable == null ? _onMainButton : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: Size.fromHeight(50 * textScale),
                      textStyle: textTheme.labelLarge?.copyWith(
                        fontSize: 16 * textScale,
                      ),
                    ),
                    icon: Icon(
                      unavailable?.icon ?? buttonIcon,
                      size: 22 * textScale,
                    ),
                    label: Text(unavailable?.button ?? buttonLabel),
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              if (unavailable != null)
                Text(
                  unavailable.note,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11 * textScale,
                    color: AppColors.outline,
                    fontWeight: FontWeight.w400,
                  ),
                )
              else if (_suggestion case final suggestion?)
                Text(
                  'Önerilen: ${suggestion.name} '
                  '(${suggestion.area.name}, '
                  '${TextUtils.duration(suggestion.durationSeconds)})',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 12 * textScale,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  'Çalışma süresi bitince mola egzersizi otomatik önerilir',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11 * textScale,
                    color: AppColors.outline,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 144,
        height: 144,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Sayacın çalışıp çalışmadığını gösteren küçük nokta.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(Radius.circular(99)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppColors.secondaryFixedDim
              : AppColors.outlineVariant,
        ),
      ),
    );
  }
}

/// Kesikli arka plan halkası ve kalan süreyi gösteren yay.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  /// 1 = süre dolu, 0 = süre bitti.
  final double progress;

  static const _stroke = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _stroke * 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = AppColors.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    const dashes = 52;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.4, false, track);
    }

    if (progress <= 0) return;
    final arcSweep = 2 * math.pi * progress;
    final glow = Paint()
      ..color = AppColors.secondaryFixedDim.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final arc = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, arcSweep, false, glow);
    canvas.drawArc(rect, -math.pi / 2, arcSweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
