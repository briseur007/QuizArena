import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../bloc/quiz_list_cubit.dart';
import '../widgets/teacher_quiz_cards.dart';

/// Onglet « Résultats » de l'enseignant : ses quiz publiés, vers leur rapport.
class TeacherResultsPage extends StatelessWidget {
  const TeacherResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QuizListCubit>()..loadPublished(),
      child: Scaffold(
        body: BlocBuilder<QuizListCubit, QuizListState>(
          builder: (context, state) => ScreenBody(
            gap: 17,
            onRefresh: context.read<QuizListCubit>().loadPublished,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ESPACE ENSEIGNANT', style: AppText.bold(10, color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text('Résultats', style: AppText.bold(22)),
                ],
              ),
              switch (state.status) {
                QuizListStatus.initial || QuizListStatus.loading => const LoadingView(),
                QuizListStatus.failure => ErrorView(
                  message: state.message ?? 'Erreur',
                  onRetry: context.read<QuizListCubit>().retry,
                ),
                QuizListStatus.success when state.quizzes.isEmpty => const EmptyView(
                  title: 'Aucun quiz publié',
                  message: 'Publie un quiz depuis « Mes cours » pour suivre ses résultats ici.',
                ),
                QuizListStatus.success => Column(
                  children: [
                    for (final (i, quiz) in state.quizzes.indexed) ...[
                      if (i > 0) const SizedBox(height: 17),
                      PublishedQuizCard(
                        quiz: quiz,
                        showCourse: true,
                        onTap: () => context.push(Routes.report(quiz.id)),
                      ),
                    ],
                  ],
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
