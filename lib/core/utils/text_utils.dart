/// Türkçe metin yardımcıları.
abstract final class TextUtils {
  /// Aramada karşılaştırma için: Türkçe kurallarıyla küçük harfe çevirir ve
  /// aksanları kaldırır ("Döndürme" ile "dondurme" eşleşsin).
  static String fold(String text) {
    const plain = {'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u'};
    final lower = text.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
    return lower.split('').map((c) => plain[c] ?? c).join();
  }

  /// Türkçe kurallarıyla büyük harf ("i" → "İ").
  static String upper(String text) =>
      text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  /// Saniyeyi okunur süreye çevirir: "30 sn", "1 dk 20 sn", "2 dk".
  static String duration(int seconds) {
    if (seconds < 60) return '$seconds sn';
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return rest == 0 ? '$minutes dk' : '$minutes dk $rest sn';
  }
}
