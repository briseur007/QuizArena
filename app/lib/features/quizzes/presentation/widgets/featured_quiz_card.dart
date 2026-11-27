import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/entities/quiz.dart';

/// Carte violette « À FAIRE · Flutter & BLoC · Commencer le quiz » (écran 02).
class FeaturedQuizCard extends StatelessWidget {
  const FeaturedQuizCard({super.key, required this.quiz, required this.onStart});

  final Quiz quiz;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final course = [quiz.courseName, if (quiz.courseLevel.isNotEmpty) quiz.courseLevel].join(' · ').toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Tag.onPrimary('À FAIRE'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course,
                  style: AppText.semibold(10, color: Colors.white),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(quiz.title, style: AppText.bold(25, color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            [
              Fmt.plural(quiz.questionCount, 'question'),
              '${quiz.durationMinutes} min',
              Fmt.plural(quiz.maxAttempts - quiz.attemptsUsed, 'tentative'),
            ].join('  ·  '),
            style: AppText.regular(12, color: Colors.white),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(label: 'Commencer le quiz', inverted: true, onPressed: onStart),
          ),
        ],
      ),
    );
  }
}

/// Carte affichée quand aucun quiz n'est à faire.
class NoQuizCard extends StatelessWidget {
  const NoQuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rien à faire pour l’instant', style: AppText.bold(17)),
          const SizedBox(height: 6),
          Text(
            'Les nouveaux quiz de tes cours apparaîtront ici dès leur publication.',
            style: AppText.regular(12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
