import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Sélecteur à deux options de la maquette (« Étudiant | Enseignant »,
/// « Ce quiz | Mon cours »).
class SegmentedSwitch<T> extends StatelessWidget {
  const SegmentedSwitch({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.fontSize = 13,
    this.itemPadding = 10,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final double fontSize;
  final double itemPadding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.segment, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final (index, entry) in options.entries.indexed) ...[
              if (index > 0) const SizedBox(width: 4),
              Expanded(child: _segment(entry.key, entry.value)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _segment(T value, String label) {
    final isSelected = value == selected;
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => onChanged(value),
          child: Padding(
            padding: EdgeInsets.all(itemPadding),
            child: Center(
              child: Text(
                label,
                style: AppText.semibold(fontSize, color: isSelected ? AppColors.primary : AppColors.muted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
