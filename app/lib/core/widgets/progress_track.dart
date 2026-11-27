import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Barre de progression fine (progression du quiz, taux de réussite).
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({super.key, required this.value, this.color = AppColors.primary, this.height = 6});

  /// Entre 0 et 1.
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.border)),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
