import 'package:material_ui/material_ui.dart';

import '../theme/app_text.dart';
import '../theme/app_colors.dart';
import 'app_icon.dart';

/// En-tête « ← Titre / sous-titre » des écrans Résultats, Classement, Rapport.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.onBack, this.trailing});

  final String title;
  final String? subtitle;

  /// `null` masque la flèche retour.
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            onPressed: onBack,
            tooltip: 'Retour',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 40),
            icon: const AppIcon(AppIcons.back, size: 22),
          ),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bold(22)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: AppText.regular(11, color: AppColors.muted)),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Titre de section « Mes cours ……… Tout voir ».
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction, this.size = 19});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.bold(size))),
        if (action != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(action!, style: AppText.semibold(12, color: AppColors.primary)),
            ),
          ),
      ],
    );
  }
}
