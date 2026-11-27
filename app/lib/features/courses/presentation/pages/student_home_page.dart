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
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../../core/widgets/tag.dart';
import '../../../attempts/domain/entities/attempt_result.dart';
import '../../../attempts/presentation/bloc/latest_result_cubit.dart';
import '../../../attempts/presentation/widgets/start_quiz.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../quizzes/presentation/bloc/quiz_list_cubit.dart';
import '../../../quizzes/presentation/widgets/featured_quiz_card.dart';
import '../bloc/courses_bloc.dart';
import '../widgets/course_widgets.dart';

/// Écran 02 · Mes cours (étudiant).
class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CoursesBloc>()..add(const CoursesRequested())),
        BlocProvider(create: (_) => getIt<QuizListCubit>()..loadTodo()),
        BlocProvider(create: (_) => getIt<LatestResultCubit>()..load()),
      ],
      child: const StudentHomeView(),
    );
  }
}

class StudentHomeView extends StatefulWidget {
  const StudentHomeView({super.key});

  @override
  State<StudentHomeView> createState() => _StudentHomeViewState();
}

class _StudentHomeViewState extends State<StudentHomeView> {
  bool _showAllCourses = false;
  static const _collapsedCount = 3;

  Future<void> _refresh() async {
    // Les cours se mettent à jour en arrière-plan ; on n'attend pas leur état
    // (aucun nouvel état n'est émis si la liste est inchangée).
    context.read<CoursesBloc>().add(const CoursesRequested(refresh: true));
    await Future.wait([context.read<QuizListCubit>().loadTodo(), context.read<LatestResultCubit>().load()]);
  }

  void _reloadAfterQuiz() {
    context.read<QuizListCubit>().loadTodo();
    context.read<LatestResultCubit>().load();
    context.read<CoursesBloc>().add(const CoursesRequested(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user)!;

    return BlocListener<CoursesBloc, CoursesState>(
      listenWhen: (p, c) => c.action == ActionStatus.success || c.action == ActionStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message ?? '')));
        if (state.action == ActionStatus.success) context.read<QuizListCubit>().loadTodo();
        context.read<CoursesBloc>().add(const CourseActionAcknowledged());
      },
      child: Scaffold(
        body: ScreenBody(
          onRefresh: _refresh,
          children: [
            // En-tête
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ESPACE ÉTUDIANT', style: AppText.bold(10, color: AppColors.primary)),
                      const SizedBox(height: 2),
                      Text('Bonjour ${Fmt.firstName(user.name)} !', style: AppText.bold(25)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Tag('Niveau ${user.level}', padding: 9, radius: 10),
              ],
            ),

            // Rejoindre un cours
            BlocSelector<CoursesBloc, CoursesState, bool>(
              selector: (s) => s.action == ActionStatus.inProgress,
              builder: (context, joining) => JoinCourseCard(
                loading: joining,
                onJoin: (code) => context.read<CoursesBloc>().add(CourseJoinRequested(code)),
              ),
            ),

            // Quiz à la une
            BlocBuilder<QuizListCubit, QuizListState>(
              builder: (context, state) => switch (state.status) {
                QuizListStatus.initial || QuizListStatus.loading => const SizedBox(height: 120, child: LoadingView()),
                QuizListStatus.failure => ErrorView(
                  message: state.message ?? 'Erreur',
                  onRetry: context.read<QuizListCubit>().retry,
                ),
                QuizListStatus.success when state.quizzes.isEmpty => const NoQuizCard(),
                QuizListStatus.success => FeaturedQuizCard(
                  quiz: state.quizzes.first,
                  onStart: () => startQuiz(context, state.quizzes.first, onFinished: _reloadAfterQuiz),
                ),
              },
            ),

            // Mes cours
            BlocBuilder<CoursesBloc, CoursesState>(
              builder: (context, state) {
                final courses = state.courses;
                final visible = _showAllCourses ? courses : courses.take(_collapsedCount).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle(
                      'Mes cours',
                      action: courses.length > _collapsedCount ? (_showAllCourses ? 'Réduire' : 'Tout voir') : null,
                      onAction: () => setState(() => _showAllCourses = !_showAllCourses),
                    ),
                    const SizedBox(height: 18),
                    if (state.fromCache && state.message != null) ...[
                      InfoLine(icon: AppIcons.clock, text: 'Hors ligne : dernière liste enregistrée.'),
                      const SizedBox(height: 12),
                    ],
                    switch (state.status) {
                      CoursesStatus.initial || CoursesStatus.loading => const LoadingView(),
                      CoursesStatus.failure => ErrorView(
                        message: state.message ?? 'Erreur',
                        onRetry: () => context.read<CoursesBloc>().add(const CoursesRequested()),
                      ),
                      CoursesStatus.success when courses.isEmpty => const EmptyView(
                        title: 'Aucun cours pour l’instant',
                        message: 'Demande le code à ton enseignant et saisis-le ci-dessus.',
                      ),
                      CoursesStatus.success => Column(
                        children: [
                          for (final (i, course) in visible.indexed) ...[
                            if (i > 0) const SizedBox(height: 18),
                            CourseTile(
                              course: course,
                              position: i + 1,
                              onTap: () => context.push(Routes.course(course.id), extra: course),
                            ),
                          ],
                        ],
                      ),
                    },
                  ],
                );
              },
            ),

            // Dernier résultat
            BlocBuilder<LatestResultCubit, AttemptResult?>(
              builder: (context, result) => result == null
                  ? const SizedBox.shrink()
                  : InfoLine(
                      icon: AppIcons.check,
                      iconColor: AppColors.success,
                      text:
                          'Dernier quiz : ${result.score}/${result.total}. '
                          '${result.ratio >= 0.5 ? 'Continue sur ta lancée !' : 'Relis la correction pour progresser.'}',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
