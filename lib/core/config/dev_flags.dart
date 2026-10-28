/// Geliştirme sırasında test kolaylığı için geçici anahtarlar.
/// Yayından önce hepsi kapatılmalı.
abstract final class DevFlags {
  /// Açıkken mola aralığı dakika yerine saniye sayılır (15 dk → 15 sn).
  static const breakIntervalInSeconds = true;

  /// Bir aralık biriminin saniye karşılığı.
  static const secondsPerIntervalUnit = breakIntervalInSeconds ? 1 : 60;
}
