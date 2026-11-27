import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Petite étiquette arrondie (« À FAIRE », « OUVERT », « BROUILLON », « 01 »…).
class Tag extends StatelessWidget {
  const Tag(
    this.label, {
    super.key,
    this.background = AppColors.primarySoft,
    this.foreground = AppColors.primary,
    this.padding = 6,
    this.radius = 8,
  });

  const Tag.success(this.label, {super.key})
    : background = AppColors.successSoft,
      foreground = AppColors.success,
      padding = 6,
      radius = 8;

  const Tag.warning(this.label, {super.key})
    : background = AppColors.warningSoft,
      foreground = AppColors.warning,
      padding = 6,
      radius = 8;

  const Tag.onPrimary(this.label, {super.key})
    : background = Colors.white,
      foreground = AppColors.primary,
      padding = 6,
      radius = 8;

  final String label;
  final Color background;
  final Color foreground;
  final double padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Text(label, style: AppText.semibold(11, color: foreground)),
      ),
    );
  }
}
