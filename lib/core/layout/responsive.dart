import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Ekran genişliği sınıfları (Material 3 pencere sınıflarına göre).
enum ScreenSize {
  /// Telefon (dikey). < 600
  compact,

  /// Küçük tablet / tablet dikey / telefon yatay. 600–839
  medium,

  /// Tablet yatay ve daha geniş. >= 840
  expanded,
}

/// Tüm sayfaların ortak yerleşim ölçüleri. Yeni sayfalar kenar boşluğunu ve
/// içerik genişliğini buradan almalı; sabit piksel yazmamalı.
abstract final class Responsive {
  static const mediumBreakpoint = 600.0;
  static const expandedBreakpoint = 840.0;

  /// Tek sütunlu içeriğin azami genişliği (tabletlerde ortalanır).
  static const maxSingleColumnWidth = 640.0;

  /// İki sütunlu yerleşimin azami genişliği.
  static const maxWideWidth = 1200.0;

  static ScreenSize sizeOf(double width) {
    if (width >= expandedBreakpoint) return ScreenSize.expanded;
    if (width >= mediumBreakpoint) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  /// Ekran kenarı ile içerik arasındaki en az boşluk.
  static double gutter(double width) {
    if (width < 360) return 12; // dar telefonlar
    if (width < mediumBreakpoint) return 16;
    if (width < expandedBreakpoint) return 24;
    return 32;
  }

  /// Bölümler arası dikey boşluk.
  static double sectionSpacing(double width) =>
      width < mediumBreakpoint ? 20 : 28;

  /// İçeriği [maxWidth] ile sınırlayıp ortalayan yatay iç boşluk. Kaydırma
  /// alanı tam genişlikte kalır (kaydırma her yerden çalışır), içerik ortalanır.
  static double horizontalInset(double width, {double? maxWidth}) {
    final max = maxWidth ?? maxSingleColumnWidth;
    return math.max(gutter(width), (width - max) / 2);
  }
}

/// Çocuğunu ekran genişliğine göre ortalayan ve kenar boşluğu veren sarmalayıcı.
/// Kaydırılmayan içerikler (başlık, alt menü, diyaloglar) için.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxSingleColumnWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = Responsive.horizontalInset(
          constraints.maxWidth,
          maxWidth: maxWidth,
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: child,
        );
      },
    );
  }
}
