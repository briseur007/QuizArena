import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../../core/widgets/tag.dart';
import '../../../attempts/presentation/widgets/start_quiz.dart';
import '../../../quizzes/domain/entities/quiz.dart';
import '../../../quizzes/presentation/bloc/quiz_list_cubit.dart';
import '../../domain/entities/course.dart';

/// Quiz d'un cours, côté étudiant (ouvert depuis « Mes cours »).
class StudentCoursePage extends StatelessWidget {
  const StudentCoursePage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final course = GoRouterState.of(context).extra as Course?;
    return BlocProvider(
      create: (_) => getIt<QuizListCubit>()..loadCourse(courseId),
      child: Scaffold(
        body: Builder(
          builder: (context) => BlocBuilder<QuizListCubit, QuizListState>(
            builder: (context, state) => ScreenBody(
              onRefresh: () => context.read<QuizListCubit>().loadCourse(courseId),
              children: [
                PageHeader(
                  title: course?.name ?? 'Cours',
                  subtitle: course == null ? null : '${course.teacherName} · ${course.level}',
                  onBack: () => context.pop(),
                ),
                switch (state.status) {
                  QuizListStatus.initial || QuizListStatus.loading => const LoadingView(),
                  QuizListStatus.failure => ErrorView(
                    message: state.message ?? 'Erreur',
                    onRetry: context.read<QuizListCubit>().retry,
                  ),
                  QuizListStatus.success when state.quizzes.isEmpty => const EmptyView(
                    title: 'Aucun quiz publié',
                    message: 'Ton enseignant n’a pas encore publié de quiz dans ce cours.',
                  ),
                  QuizListStatus.success => Column(
                    children: [
                      for (final (i, quiz) in state.quizzes.indexed) ...[
                        if (i > 0) const SizedBox(height: 14),
                        _StudentQuizTile(
                          quiz: quiz,
                          onStart: () => startQuiz(
                            context,
                            quiz,
                            onFinished: () => context.read<QuizListCubit>().loadCourse(courseId),
                          ),
                          onLeaderboard: () => context.go(Routes.leaderboard(quizId: quiz.id, courseId: courseId)),
                        ),
                      ],
                    ],
                  ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentQuizTile extends StatelessWidget {
  const _StudentQuizTile({required this.quiz, required this.onStart, required this.onLeaderboard});

  final Quiz quiz;
  final VoidCallback onStart;
  final VoidCallback onLeaderboard;

  @override
  Widget build(BuildContext context) {
    final done = quiz.attemptsUsed > 0;
    return SurfaceCard(
      onTap: quiz.canAttempt ? onStart : (done ? onLeaderboard : null),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (quiz.canAttempt)
                const Tag('À FAIRE')
              else if (done)
                const Tag.success('TERMINÉ')
              else
                Tag(quiz.status.label, background: AppColors.segment, foreground: AppColors.muted),
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
          const SizedBox(height: 10),
          Text(quiz.title, style: AppText.bold(17)),
          const SizedBox(height: 6),
          Text(
            quiz.canAttempt
                ? 'Tentatives : ${quiz.attemptsUsed}/${quiz.maxAttempts} · Touche pour commencer'
                : done
                ? 'Touche pour voir le classement'
                : 'Quiz fermé',
            style: AppText.regular(11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
