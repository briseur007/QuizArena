import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../quizzes/domain/entities/quiz.dart';

/// Confirme puis lance un quiz ; à la remise, ouvre l'écran Résultats.
///
/// [onFinished] permet à l'écran appelant de recharger ses listes.
Future<void> startQuiz(BuildContext context, Quiz quiz, {VoidCallback? onFinished}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text(quiz.title, style: AppText.bold(19)),
      content: Text(
        '${Fmt.plural(quiz.questionCount, 'question')} · ${quiz.durationMinutes} min · '
        '${Fmt.plural(quiz.maxAttempts - quiz.attemptsUsed, 'tentative restante', 'tentatives restantes')}.\n\n'
        'Le chronomètre démarre dès maintenant et continue même si tu quittes l’application.',
        style: AppText.regular(13, color: AppColors.muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Plus tard', style: AppText.semibold(13, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Commencer', style: AppText.semibold(13, color: AppColors.primary)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final resultId = await context.push<String>(Routes.play(quiz.id));
  onFinished?.call();
  if (resultId != null && context.mounted) {
    await context.push(Routes.result(resultId));
  }
}
