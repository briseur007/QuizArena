import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/entities/attempt_result.dart';
import '../bloc/result_cubit.dart';

/// Écran 04 · Résultats. [teacherView] : l'enseignant consulte la remise
/// d'un étudiant depuis le rapport du quiz.
class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.attemptId, this.teacherView = false});

  final String attemptId;
  final bool teacherView;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ResultCubit>()..load(attemptId),
      child: Scaffold(
        body: BlocBuilder<ResultCubit, ResultState>(
          builder: (context, state) {
            void back() => context.canPop() ? context.pop() : context.go(Routes.home);
            return switch (state.status) {
              ResultStatus.loading => const LoadingView(),
              ResultStatus.failure => SafeArea(
                child: ErrorView(
                  message: state.message ?? 'Erreur',
                  onRetry: () => context.read<ResultCubit>().load(attemptId),
                ),
              ),
              ResultStatus.success => _ResultContent(result: state.result!, teacherView: teacherView, onBack: back),
            };
          },
        ),
      ),
    );
  }
}

class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.result, required this.teacherView, required this.onBack});

  final AttemptResult result;
  final bool teacherView;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final firstName = Fmt.firstName(result.studentName);
    final appreciation = ResultCubit.appreciation(result.ratio, firstName);

    return ScreenBody(
      gap: 16,
      children: [
        PageHeader(
          title: teacherView ? result.studentName : 'Tes résultats',
          subtitle: '${result.quizTitle} · ${result.courseName}',
          onBack: onBack,
        ),

        // Bilan
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Tag.onPrimary('QUIZ TERMINÉ'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tentative ${result.attemptNumber} sur ${result.maxAttempts}',
                      style: AppText.medium(10, color: Colors.white),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${result.score}/${result.total}', style: AppText.bold(56, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appreciation.title, style: AppText.bold(15, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(appreciation.subtitle, style: AppText.regular(11, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${Fmt.percent(result.ratio)} de réussite',
                      style: AppText.semibold(12, color: Colors.white),
                    ),
                  ),
                  Text(
                    'Temps : ${Fmt.seconds(result.durationSeconds)}',
                    style: AppText.medium(12, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Correction
        Row(
          children: [
            Expanded(child: Text('Comprendre mes réponses', style: AppText.bold(17))),
            Text(
              '${result.corrections.where((c) => c.isCorrect).length} / ${result.corrections.length}',
              style: AppText.medium(11, color: AppColors.muted),
            ),
          ],
        ),
        for (final correction in result.corrections) _CorrectionCard(correction: correction),

        if (!teacherView)
          PrimaryButton(
            label: 'Voir le classement',
            onPressed: () => context.go(Routes.leaderboard(quizId: result.quizId, courseId: result.courseId)),
          ),
      ],
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.correction});

  final Correction correction;

  @override
  Widget build(BuildContext context) {
    final ok = correction.isCorrect;
    final color = ok ? AppColors.success : AppColors.danger;
    final explanation = [
      if (!ok) 'Bonne réponse : ${correction.correctAnswer}.',
      if (correction.explanation != null && correction.explanation!.isNotEmpty) correction.explanation!,
    ].join('\n');

    return SurfaceCard(
      radius: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(Fmt.twoDigits(correction.index + 1)),
              const SizedBox(width: 8),
              Expanded(child: Text(correction.question, style: AppText.semibold(13))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppIcon(ok ? AppIcons.check : AppIcons.close, size: 17, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  correction.chosenAnswer == null ? 'Pas de réponse' : 'Ta réponse : ${correction.chosenAnswer}',
                  style: AppText.medium(12, color: color),
                ),
              ),
            ],
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(explanation, style: AppText.regular(11, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}
