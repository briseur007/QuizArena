import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_icon.dart';

/// Logo « Q QuizArena » de l'écran de connexion.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
          child: Text(
            'Q',
            style: AppText.bold(22, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 10),
        Text('QuizArena', style: AppText.bold(21)),
      ],
    );
  }
}

/// Bandeau violet clair « Un compte, tous tes cours et tes résultats. »
class InfoBanner extends StatelessWidget {
  const InfoBanner(this.text, {super.key, this.icon = AppIcons.book});

  final String text;
  final AppIcons icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppText.medium(11, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

/// Message d'erreur générale d'un formulaire.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message, style: AppText.medium(12, color: AppColors.danger)),
      ),
    );
  }
}

/// Icône œil pour afficher / masquer le mot de passe.
class PasswordVisibilityButton extends StatelessWidget {
  const PasswordVisibilityButton({super.key, required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: obscured ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
      icon: AppIcon(AppIcons.eye, size: 20, color: obscured ? AppColors.muted : AppColors.primary),
    );
  }
}
