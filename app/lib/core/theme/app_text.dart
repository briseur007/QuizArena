import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Styles de texte de la maquette (Inter, interligne 1.35).
///
/// Usage : `AppText.bold(25)`, `AppText.medium(12, color: AppColors.muted)`.
abstract final class AppText {
  static const family = 'Inter';

  static TextStyle _style(double size, FontWeight weight, Color color) =>
      TextStyle(fontFamily: family, fontSize: size, fontWeight: weight, height: 1.35, color: color);

  static TextStyle regular(double size, {Color color = AppColors.ink}) => _style(size, FontWeight.w400, color);

  static TextStyle medium(double size, {Color color = AppColors.ink}) => _style(size, FontWeight.w500, color);

  static TextStyle semibold(double size, {Color color = AppColors.ink}) => _style(size, FontWeight.w600, color);

  static TextStyle bold(double size, {Color color = AppColors.ink}) => _style(size, FontWeight.w700, color);
}
