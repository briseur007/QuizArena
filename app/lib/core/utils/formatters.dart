/// Formats d'affichage partagés (en français).
abstract final class Fmt {
  /// 7 → « 07 ».
  static String twoDigits(int n) => n.toString().padLeft(2, '0');

  /// 438 s → « 07:18 ».
  static String duration(Duration d) {
    final total = d.isNegative ? 0 : d.inSeconds;
    return '${twoDigits(total ~/ 60)}:${twoDigits(total % 60)}';
  }

  static String seconds(int s) => duration(Duration(seconds: s));

  /// 0.4 → « 40 % » (espace insécable avant %, usage français).
  static String percent(double ratio) => '${(ratio * 100).round()} %';

  /// 7.25 → « 7,3 ».
  static String decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');

  /// « 1 quiz disponible » / « 3 quiz disponibles ».
  static String plural(int n, String singular, [String? plural]) =>
      '$n ${n > 1 ? (plural ?? '${singular}s') : singular}';

  /// « Amina Ouédraogo » → « Amina ».
  static String firstName(String fullName) => fullName.trim().split(RegExp(r'\s+')).first;
}
