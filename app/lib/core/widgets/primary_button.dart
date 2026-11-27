import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_icon.dart';

/// Gros bouton de la maquette (« Se connecter », « Question suivante »…).
///
/// [inverted] = bouton blanc à texte violet, posé sur une carte violette.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = AppIcons.arrow,
    this.leadingIcon,
    this.inverted = false,
    this.loading = false,
    this.verticalPadding = 15,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppIcons? trailingIcon;
  final AppIcons? leadingIcon;
  final bool inverted;
  final bool loading;
  final double verticalPadding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final background = inverted ? Colors.white : AppColors.primary;
    final foreground = inverted ? AppColors.primary : Colors.white;
    final enabled = onPressed != null && !loading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled || loading ? 1 : 0.5,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: verticalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: loading
                    ? [
                        SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: foreground),
                        ),
                      ]
                    : [
                        if (leadingIcon != null) ...[
                          AppIcon(leadingIcon!, color: foreground),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: AppText.semibold(fontSize, color: foreground),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 10),
                          AppIcon(trailingIcon!, color: foreground),
                        ],
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
