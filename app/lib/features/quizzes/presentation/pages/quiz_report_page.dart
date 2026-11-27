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
import '../../../../core/widgets/progress_track.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_report.dart';
import '../bloc/quiz_report_cubit.dart';

/// Écran 08 · Rapport du quiz (enseignant).
class QuizReportPage extends StatelessWidget {
  const QuizReportPage({super.key, required this.quizId});

  final String quizId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QuizReportCubit>()..load(quizId),
      child: Scaffold(
        body: BlocBuilder<QuizReportCubit, QuizReportState>(
          builder: (context, state) => switch (state.status) {
            ReportStatus.loading => const LoadingView(),
            ReportStatus.failure => SafeArea(
              child: ErrorView(
                message: state.message ?? 'Erreur',
                onRetry: () => context.read<QuizReportCubit>().load(quizId),
              ),
            ),
            ReportStatus.success => _ReportContent(report: state.report!),
          },
        ),
      ),
    );
  }
}

class _ReportContent extends StatefulWidget {
  const _ReportContent({required this.report});

  final QuizReport report;

  @override
  State<_ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<_ReportContent> {
  bool _allQuestions = false;
  bool _allSubmissions = false;
  static const _preview = 3;

  /// Vert au-dessus de 70 %, orange en dessous (couleurs de la maquette).
  Color _rateColor(double rate) => rate >= 0.7 ? AppColors.success : AppColors.warning;

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final questions = _allQuestions ? r.questions : r.questions.take(_preview).toList();
    final submissions = _allSubmissions ? r.submissions : r.submissions.take(_preview).toList();

    return ScreenBody(
      gap: 16,
      onRefresh: () => context.read<QuizReportCubit>().load(r.quizId),
      children: [
        PageHeader(
          title: 'Rapport du quiz',
          subtitle: '${r.title} · ${r.courseName}',
          onBack: () => context.canPop() ? context.pop() : context.go(Routes.ranking),
        ),

        // Synthèse
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tag.onPrimary(r.status == QuizStatus.closed ? 'RÉSULTATS DÉFINITIFS' : 'RÉSULTATS PROVISOIRES'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _KeyFigure(value: '${r.submittedCount}/${r.studentCount}', label: 'étudiants ont terminé'),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _KeyFigure(
                      value: '${Fmt.decimal(r.average)}/${r.questionCount}',
                      label: 'moyenne de la classe',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                r.missingCount == 0
                    ? 'Tous les étudiants ont remis leur quiz.'
                    : '${Fmt.plural(r.missingCount, 'étudiant n’a', 'étudiants n’ont')} pas encore remis leur quiz.',
                style: AppText.regular(10, color: Colors.white),
              ),
            ],
          ),
        ),

        // Par question
        SectionTitle(
          'Par question',
          size: 18,
          action: r.questions.length > _preview ? (_allQuestions ? 'Réduire' : 'Tout voir →') : null,
          onAction: () => setState(() => _allQuestions = !_allQuestions),
        ),
        if (r.questions.isEmpty)
          const EmptyView(title: 'Aucune question')
        else
          SurfaceCard(
            child: Column(
              children: [
                for (final (i, q) in questions.indexed) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _QuestionRate(stat: q, color: _rateColor(q.successRate)),
                ],
              ],
            ),
          ),

        // Par étudiant
        SectionTitle(
          'Par étudiant',
          size: 18,
          action: r.submissions.length > _preview
              ? (_allSubmissions ? 'Réduire' : '${Fmt.plural(r.submittedCount, 'remise')} →')
              : null,
          onAction: () => setState(() => _allSubmissions = !_allSubmissions),
        ),
        if (r.submissions.isEmpty)
          const EmptyView(title: 'Aucune remise pour l’instant', message: 'Les résultats apparaîtront ici.')
        else
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final s in submissions)
                  InkWell(
                    onTap: () => context.push(Routes.submission(r.quizId, s.attemptId)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.studentName, style: AppText.semibold(12)),
                                const SizedBox(height: 2),
                                Text(
                                  'Remis · ${Fmt.seconds(s.durationSeconds)}',
                                  style: AppText.regular(10, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Tag('${s.score}/${s.total}'),
                          const SizedBox(width: 12),
                          const AppIcon(AppIcons.chevron, size: 16, color: AppColors.muted),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Text('Notes calculées automatiquement après la remise.', style: AppText.regular(10, color: AppColors.muted)),
      ],
    );
  }
}

class _KeyFigure extends StatelessWidget {
  const _KeyFigure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppText.bold(32, color: Colors.white)),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppText.regular(10, color: Colors.white)),
      ],
    );
  }
}

class _QuestionRate extends StatelessWidget {
  const _QuestionRate({required this.stat, required this.color});

  final QuestionStat stat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(Fmt.twoDigits(stat.index + 1), style: AppText.bold(11, color: AppColors.muted)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(stat.text, style: AppText.semibold(12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text(Fmt.percent(stat.successRate), style: AppText.bold(12, color: color)),
          ],
        ),
        const SizedBox(height: 7),
        ProgressTrack(value: stat.successRate, color: color, height: 5),
        const SizedBox(height: 7),
        Text(
          '${Fmt.plural(stat.correctCount, 'bonne réponse', 'bonnes réponses')} sur ${stat.answeredCount}',
          style: AppText.regular(10, color: AppColors.muted),
        ),
      ],
    );
  }
}
