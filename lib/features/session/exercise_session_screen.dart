import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/data/activity.dart';
import '../../core/data/exercise_catalog.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/text_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/tip_banner.dart';

enum _Phase { info, countdown, active, done }

/// Egzersiz seansı: bilgi → 3-2-1 hazırlık → süreli egzersiz. Birden çok
/// egzersiz verilirse (bölge serisi) sırayla ilerler, sonunda özet gösterir.
class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({
    super.key,
    required this.exercises,
    this.title = 'Egzersiz',
  }) : assert(exercises.length > 0);

  final List<Exercise> exercises;

  /// Başlıkta görünen seans adı ("Mola Egzersizi", "Boyun Serisi").
  final String title;

  /// Alt menünün üstünde, tam ekran açılır.
  static Future<void> open(
    BuildContext context,
    List<Exercise> exercises, {
    String title = 'Egzersiz',
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            ExerciseSessionScreen(exercises: exercises, title: title),
      ),
    );
  }

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  static const _countdownFrom = 3;

  var _index = 0;
  var _phase = _Phase.info;
  var _countdown = _countdownFrom;
  var _remaining = 0;
  var _paused = false;
  var _completed = 0;
  var _completedSeconds = 0;
  Timer? _ticker;

  Exercise get _exercise => widget.exercises[_index];
  bool get _isRoutine => widget.exercises.length > 1;
  bool get _isLast => _index == widget.exercises.length - 1;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker(void Function() onTick) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
  }

  void _startCountdown() {
    setState(() {
      _phase = _Phase.countdown;
      _countdown = _countdownFrom;
    });
    _startTicker(() {
      if (_countdown <= 1) {
        _startActive();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _startActive() {
    setState(() {
      _phase = _Phase.active;
      _remaining = _exercise.durationSeconds;
      _paused = false;
    });
    _startTicker(() {
      if (_paused) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _remaining = 0;
          _ticker?.cancel();
        }
      });
    });
  }

  void _cancelCountdown() {
    _ticker?.cancel();
    setState(() => _phase = _Phase.info);
  }

  void _togglePause() => setState(() => _paused = !_paused);

  void _complete() {
    ActivityScope.read(context).record(_exercise);
    _completed++;
    _completedSeconds += _exercise.durationSeconds;
    _next();
  }

  /// Sıradaki egzersizin bilgisine geçer; son egzersizse seansı bitirir.
  void _next() {
    _ticker?.cancel();
    if (_isLast) {
      // Tek egzersiz atlanırsa özet göstermeye gerek yok.
      if (_completed == 0 && !_isRoutine) {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _phase = _Phase.done);
      return;
    }
    setState(() {
      _index++;
      _phase = _Phase.info;
    });
  }

  String get _phaseTitle => switch (_phase) {
    _Phase.info => 'Egzersiz Bilgisi',
    _Phase.countdown => 'Hazırlan',
    _Phase.active => 'Sıra Sende',
    _Phase.done => 'Seans Tamamlandı',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            ResponsiveCenter(
              child: _SessionHeader(
                label: TextUtils.upper(widget.title),
                title: _phaseTitle,
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey((_phase, _index)),
                  child: _buildPhase(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase() {
    final step = _isRoutine
        ? 'Adım ${_index + 1} / ${widget.exercises.length}'
        : null;
    return switch (_phase) {
      _Phase.info => _InfoPhase(
        exercise: _exercise,
        step: step,
        onStart: _startCountdown,
        onSkip: _isRoutine ? _next : null,
      ),
      _Phase.countdown => _CountdownPhase(
        exercise: _exercise,
        count: _countdown,
        onCancel: _cancelCountdown,
        onStartNow: _startActive,
      ),
      _Phase.active => _ActivePhase(
        exercise: _exercise,
        step: step,
        remaining: _remaining,
        paused: _paused,
        onTogglePause: _togglePause,
        onComplete: _complete,
        onSkip: _next,
      ),
      _Phase.done => _DonePhase(
        completed: _completed,
        total: widget.exercises.length,
        seconds: _completedSeconds,
        onClose: () => Navigator.of(context).pop(),
      ),
    };
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.label,
    required this.title,
    required this.onClose,
  });

  final String label;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onClose,
            tooltip: 'Kapat',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              foregroundColor: AppColors.onSurface,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kaydırılan içerik ve ekranın altına sabitlenmiş butonlar.
class _PhaseLayout extends StatelessWidget {
  const _PhaseLayout({required this.content, required this.actions});

  final List<Widget> content;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = Responsive.horizontalInset(constraints.maxWidth);
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(inset, 8, inset, 16),
                children: content,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(inset, 8, inset, 16),
              child: actions,
            ),
          ],
        );
      },
    );
  }
}

class _InfoPhase extends StatelessWidget {
  const _InfoPhase({
    required this.exercise,
    required this.step,
    required this.onStart,
    required this.onSkip,
  });

  final Exercise exercise;
  final String? step;
  final VoidCallback onStart;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _PhaseLayout(
      content: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (step != null)
              _Chip(
                label: step!,
                color: AppColors.surfaceContainerHigh,
                dot: true,
              ),
            _Chip(
              icon: exercise.area.icon,
              label: exercise.area.name,
              color: AppColors.primaryFixed,
            ),
            _Chip(
              icon: Icons.schedule_rounded,
              label: TextUtils.duration(exercise.durationSeconds),
              color: AppColors.secondaryContainer,
            ),
            _Chip(
              icon: Icons.chair_alt_outlined,
              label: exercise.posture.label,
              color: AppColors.surfaceContainerHigh,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(exercise.name, style: textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          exercise.summary,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.format_list_numbered_rounded,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Nasıl Uygulanır?',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < exercise.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          '${i + 1}',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            exercise.steps[i],
                            style: textTheme.bodyMedium?.copyWith(height: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TipBanner(
          title: 'Fizyoterapist Notu',
          body: exercise.area.tip,
          icon: Icons.health_and_safety_outlined,
        ),
      ],
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Başla'),
          ),
          if (onSkip != null) ...[
            const SizedBox(height: 4),
            TextButton(onPressed: onSkip, child: const Text('Atla')),
          ],
        ],
      ),
    );
  }
}

class _CountdownPhase extends StatelessWidget {
  const _CountdownPhase({
    required this.exercise,
    required this.count,
    required this.onCancel,
    required this.onStartNow,
  });

  final Exercise exercise;
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onStartNow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _PhaseLayout(
      content: [
        Text(
          exercise.name,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          exercise.steps.first,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Container(
            width: 240,
            height: 240,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerLowest,
              border: Border.all(
                color: AppColors.primaryFixed.withValues(alpha: 0.6),
                width: 24,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HAZIR MISIN?',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text(
                    '$count',
                    key: ValueKey(count),
                    style: textTheme.displayLarge?.copyWith(
                      fontSize: 88,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final n in const [3, 2, 1])
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: n == count
                      ? AppColors.primary
                      : AppColors.secondaryContainer,
                  borderRadius: const BorderRadius.all(Radius.circular(99)),
                ),
                child: Text(
                  '$n',
                  style: textTheme.labelLarge?.copyWith(
                    color: n == count
                        ? AppColors.onPrimary
                        : AppColors.onSecondaryFixed,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const TipBanner(
          title: 'Egzersizin başlamak üzere',
          body: 'Derin bir nefes al, omuzlarını düşür ve omurganı dikleştir.',
          icon: Icons.air_rounded,
        ),
      ],
      actions: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: onCancel,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                foregroundColor: AppColors.onSurface,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Vazgeç'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onStartNow,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Şimdi Başla'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePhase extends StatelessWidget {
  const _ActivePhase({
    required this.exercise,
    required this.step,
    required this.remaining,
    required this.paused,
    required this.onTogglePause,
    required this.onComplete,
    required this.onSkip,
  });

  final Exercise exercise;
  final String? step;
  final int remaining;
  final bool paused;
  final VoidCallback onTogglePause;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  bool get _finished => remaining <= 0;

  String get _formatted {
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _PhaseLayout(
      content: [
        Center(
          child: _Chip(
            icon: exercise.area.icon,
            label: step == null
                ? exercise.area.name
                : '${exercise.area.name} · $step',
            color: AppColors.primaryFixed,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          exercise.name,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          exercise.summary,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox.square(
            dimension: 230,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: remaining / exercise.durationSeconds),
              duration: const Duration(milliseconds: 900),
              builder: (context, value, child) => CustomPaint(
                painter: _ProgressRingPainter(progress: value),
                child: child,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _finished
                        ? Icons.task_alt_rounded
                        : Icons.hourglass_top_rounded,
                    color: AppColors.secondary,
                  ),
                  Text(
                    _formatted,
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    _finished
                        ? 'Süre doldu'
                        : paused
                        ? 'Duraklatıldı'
                        : 'Kalan süre',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in exercise.steps)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s, style: textTheme.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            // Süre bitmeden tamamlanmış sayılmaz; erken çıkmak için Atla.
            onPressed: _finished ? onComplete : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Tamamladım'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _finished ? null : onTogglePause,
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                  label: Text(paused ? 'Devam Et' : 'Durdur'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onSkip,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Atla'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonePhase extends StatelessWidget {
  const _DonePhase({
    required this.completed,
    required this.total,
    required this.seconds,
    required this.onClose,
  });

  final int completed;
  final int total;
  final int seconds;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _PhaseLayout(
      content: [
        const SizedBox(height: 32),
        const Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.secondaryContainer,
            child: Icon(
              Icons.celebration_rounded,
              size: 44,
              color: AppColors.onSecondaryFixed,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          completed == 0 ? 'Bu sefer olmadı' : 'Harika iş!',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          completed == 0
              ? 'Tüm egzersizleri atladın. Bir sonraki molada görüşürüz.'
              : '$total egzersizden $completed tanesini tamamladın '
                    '(${TextUtils.duration(seconds)}).',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
      actions: FilledButton(
        onPressed: onClose,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
        ),
        child: const Text('Kapat'),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    this.icon,
    this.dot = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(99)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kalan süreyi gösteren halka; 1 = tam süre, 0 = süre bitti.
class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  static const _stroke = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceContainerHigh
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
