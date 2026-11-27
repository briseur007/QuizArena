import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Icônes exportées de la maquette Figma (assets/icons/*.svg).
enum AppIcons {
  arrow,
  back,
  book,
  chart,
  check,
  chevron,
  clock,
  close,
  copy,
  eye,
  plus,
  radio,
  user;

  String get asset => 'assets/icons/$name.svg';
}

/// Affiche une icône de la maquette, recolorée selon le contexte.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 18, this.color});

  final AppIcons icon;
  final double size;

  /// Couleur du trait. `null` garde la couleur d'origine du fichier SVG.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
