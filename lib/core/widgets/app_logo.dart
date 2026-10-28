import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uygulamanın tek logo kaynağı. Logo değişirse yalnızca [markAsset]
/// dosyasını (veya bu yolu) güncellemek yeterli.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.showWordmark = true});

  static const markAsset = 'assets/brand/logo_mark.svg';
  static const appName = 'FitDesk';
  static const wordmarkColor = Color(0xFF2C3A40);

  /// Logo işaretinin genişliği; yazı boyutu buna göre ölçeklenir.
  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture.asset(
      markAsset,
      width: size,
      height: size * 100 / 120,
      semanticsLabel: showWordmark ? null : appName,
    );
    if (!showWordmark) return mark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.12),
        Text(
          appName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.46,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: wordmarkColor,
          ),
        ),
      ],
    );
  }
}
