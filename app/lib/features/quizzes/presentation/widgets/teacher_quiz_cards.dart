import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/entities/quiz.dart';

/// Carte « OUVERT · Flutter & BLoC · 24 / 32 remises · Voir les résultats → ».
class PublishedQuizCard extends StatelessWidget {
  const PublishedQuizCard({super.key, required this.quiz, required this.onTap, this.showCourse = false});

  final Quiz quiz;
  final VoidCallback onTap;
  final bool showCourse;

  @override
  Widget build(BuildContext context) {
    final isOpen = quiz.status == QuizStatus.open;
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              isOpen
                  ? Tag.success(quiz.status.label)
                  : Tag(quiz.status.label, background: AppColors.segment, foreground: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${Fmt.plural(quiz.questionCount, 'question')} · ${quiz.durationMinutes} min',
                  style: AppText.medium(10, color: AppColors.muted),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (showCourse) ...[
            Text(quiz.courseName.toUpperCase(), style: AppText.bold(10, color: AppColors.primary)),
            const SizedBox(height: 2),
          ],
          Text(quiz.title, style: AppText.bold(19)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('${quiz.submissionCount} / ${quiz.studentCount} remises', style: AppText.semibold(12)),
              ),
              Text('Voir les résultats →', style: AppText.semibold(11, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte « BROUILLON · 8 questions · API & sécurité › ».
class DraftQuizCard extends StatelessWidget {
  const DraftQuizCard({super.key, required this.quiz, required this.onTap});

  final Quiz quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag.warning(QuizStatus.draft.label),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Fmt.plural(quiz.questionCount, 'question'),
                  style: AppText.medium(10, color: AppColors.muted),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(child: Text(quiz.title, style: AppText.semibold(17))),
              const SizedBox(width: 8),
              const AppIcon(AppIcons.chevron, color: AppColors.muted),
            ],
          ),
        ],
      ),
    );
  }
}
