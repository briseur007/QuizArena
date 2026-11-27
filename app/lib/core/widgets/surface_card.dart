import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Carte blanche arrondie de la maquette, cliquable si [onTap] est fourni.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
    this.color = AppColors.surface,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return Material(
      color: color,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: border == null ? null : BoxDecoration(border: border, borderRadius: shape),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Corps d'écran standard : marges 24/16, défilement, tirer pour rafraîchir.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children, this.onRefresh, this.gap = 18});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: (_, i) => children[i],
    );
    return SafeArea(
      bottom: false,
      child: onRefresh == null ? list : RefreshIndicator(color: AppColors.primary, onRefresh: onRefresh!, child: list),
    );
  }
}
