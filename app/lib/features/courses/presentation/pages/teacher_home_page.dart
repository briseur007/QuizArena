import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

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
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../quizzes/domain/entities/quiz.dart';
import '../../../quizzes/presentation/bloc/quiz_list_cubit.dart';
import '../../../quizzes/presentation/widgets/teacher_quiz_cards.dart';
import '../../domain/entities/course.dart';
import '../bloc/courses_bloc.dart';
import '../widgets/course_widgets.dart';
import '../widgets/create_course_sheet.dart';

/// Écran 06 · Espace enseignant.
class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CoursesBloc>()..add(const CoursesRequested())),
        BlocProvider(create: (_) => getIt<QuizListCubit>()),
      ],
      child: const TeacherHomeView(),
    );
  }
}

class TeacherHomeView extends StatefulWidget {
  const TeacherHomeView({super.key});

  @override
  State<TeacherHomeView> createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends State<TeacherHomeView> {
  /// Cours affiché (simple état d'interface : quel cours est sélectionné).
  String? _selectedCourseId;

  Course? _selected(List<Course> courses) {
    if (courses.isEmpty) return null;
    return courses.firstWhere((c) => c.id == _selectedCourseId, orElse: () => courses.first);
  }

  void _select(Course course) {
    setState(() => _selectedCourseId = course.id);
    context.read<QuizListCubit>().loadCourse(course.id);
  }

  Future<void> _openEditor(String url) async {
    await context.push(url);
    if (!mounted) return;
    // Retour de l'éditeur : un quiz a pu être créé ou publié.
    context.read<CoursesBloc>().add(const CoursesRequested(refresh: true));
    final course = _selected(context.read<CoursesBloc>().state.courses);
    if (course != null) await context.read<QuizListCubit>().loadCourse(course.id);
  }

  Future<void> _pickCourse(List<Course> courses) async {
    final picked = await showModalBottomSheet<Course>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in courses)
              ListTile(
                title: Text(c.name, style: AppText.semibold(14)),
                subtitle: Text(
                  '${c.level} · ${Fmt.plural(c.studentCount, 'étudiant')}',
                  style: AppText.regular(11, color: AppColors.muted),
                ),
                trailing: c.id == _selectedCourseId ? const AppIcon(AppIcons.check, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) _select(picked);
  }

  Future<void> _createCourse() async {
    final input = await showCreateCourseSheet(context);
    if (input != null && mounted) {
      context.read<CoursesBloc>().add(CourseCreateRequested(name: input.name, level: input.level));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user)!;

    return MultiBlocListener(
      listeners: [
        // Premier chargement des cours → charger les quiz du cours affiché.
        BlocListener<CoursesBloc, CoursesState>(
          listenWhen: (p, c) => p.courses.isEmpty && c.courses.isNotEmpty,
          listener: (context, state) => _select(_selected(state.courses)!),
        ),
        BlocListener<CoursesBloc, CoursesState>(
          listenWhen: (p, c) => c.action == ActionStatus.success || c.action == ActionStatus.failure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message ?? '')));
            if (state.action == ActionStatus.success && state.courses.isNotEmpty) _select(state.courses.first);
            context.read<CoursesBloc>().add(const CourseActionAcknowledged());
          },
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<CoursesBloc, CoursesState>(
          builder: (context, coursesState) {
            final courses = coursesState.courses;
            final course = _selected(courses);
            final students = courses.fold(0, (sum, c) => sum + c.studentCount);
            final quizzes = courses.fold(0, (sum, c) => sum + c.quizCount);

            return ScreenBody(
              gap: 17,
              onRefresh: () async {
                context.read<CoursesBloc>().add(const CoursesRequested(refresh: true));
                if (course != null) await context.read<QuizListCubit>().loadCourse(course.id);
              },
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ESPACE ENSEIGNANT', style: AppText.bold(10, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text('Bonjour ${user.name}', style: AppText.bold(22)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(value: courses.length, label: 'Cours actifs'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(value: students, label: 'Étudiants'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(value: quizzes, label: 'Quiz créés'),
                    ),
                  ],
                ),
                ...switch (coursesState.status) {
                  CoursesStatus.initial || CoursesStatus.loading => [const LoadingView()],
                  CoursesStatus.failure => [
                    ErrorView(
                      message: coursesState.message ?? 'Erreur',
                      onRetry: () => context.read<CoursesBloc>().add(const CoursesRequested()),
                    ),
                  ],
                  CoursesStatus.success when course == null => [
                    const EmptyView(
                      title: 'Crée ton premier cours',
                      message: 'Tes étudiants le rejoindront avec son code d’invitation.',
                    ),
                    PrimaryButton(
                      label: 'Nouveau cours',
                      leadingIcon: AppIcons.plus,
                      trailingIcon: null,
                      onPressed: _createCourse,
                    ),
                  ],
                  CoursesStatus.success => [
                    _SelectedCourseCard(
                      course: course!,
                      onPick: courses.length > 1 ? () => _pickCourse(courses) : null,
                    ),
                    SectionTitle('Quiz du cours', size: 18, action: '+ Nouveau cours', onAction: _createCourse),
                    _CourseQuizzes(
                      onOpenQuiz: (quiz) => quiz.status == QuizStatus.draft
                          ? _openEditor(Routes.editQuiz(quiz.id, courseId: course.id, courseName: course.name))
                          : context.go(Routes.report(quiz.id)),
                    ),
                    PrimaryButton(
                      label: 'Créer un quiz',
                      leadingIcon: AppIcons.plus,
                      trailingIcon: null,
                      verticalPadding: 14,
                      fontSize: 14,
                      onPressed: () => _openEditor(Routes.newQuiz(courseId: course.id, courseName: course.name)),
                    ),
                    InkWell(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Le mode live arrive avec la fonctionnalité avancée (M4).')),
                      ),
                      child: const InfoLine(
                        icon: AppIcons.clock,
                        text: 'Mode live · animer un quiz en temps réel',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                },
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 14,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Fmt.twoDigits(value), style: AppText.bold(25)),
          const SizedBox(height: 4),
          Text(label, style: AppText.regular(10, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _SelectedCourseCard extends StatelessWidget {
  const _SelectedCourseCard({required this.course, this.onPick});

  final Course course;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: AppColors.primarySoft,
      radius: 18,
      padding: const EdgeInsets.all(16),
      onTap: onPick,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(course.name, style: AppText.bold(17))),
              if (onPick != null) ...[
                const SizedBox(width: 8),
                const AppIcon(AppIcons.chevron, color: AppColors.primary),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  [if (course.level.isNotEmpty) course.level, Fmt.plural(course.studentCount, 'étudiant')].join(' · '),
                  style: AppText.regular(11, color: AppColors.muted),
                ),
              ),
              if (course.code != null) ...[
                Tag.onPrimary(course.code!),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Copier le code',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: course.code!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code ${course.code} copié.')));
                    }
                  },
                  icon: const AppIcon(AppIcons.copy, size: 17, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseQuizzes extends StatelessWidget {
  const _CourseQuizzes({required this.onOpenQuiz});

  final ValueChanged<Quiz> onOpenQuiz;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizListCubit, QuizListState>(
      builder: (context, state) => switch (state.status) {
        QuizListStatus.initial || QuizListStatus.loading => const LoadingView(),
        QuizListStatus.failure => ErrorView(
          message: state.message ?? 'Erreur',
          onRetry: context.read<QuizListCubit>().retry,
        ),
        QuizListStatus.success when state.quizzes.isEmpty => const EmptyView(
          title: 'Aucun quiz dans ce cours',
          message: 'Crée ton premier quiz avec le bouton ci-dessous.',
        ),
        QuizListStatus.success => Column(
          children: [
            for (final (i, quiz) in state.quizzes.indexed) ...[
              if (i > 0) const SizedBox(height: 17),
              quiz.status == QuizStatus.draft
                  ? DraftQuizCard(quiz: quiz, onTap: () => onOpenQuiz(quiz))
                  : PublishedQuizCard(quiz: quiz, onTap: () => onOpenQuiz(quiz)),
            ],
          ],
        ),
      },
    );
  }
}
