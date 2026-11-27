import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/progress_track.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/tag.dart';
import '../bloc/quiz_play_bloc.dart';

/// Écran 03 · Quiz en cours. Se ferme avec l'identifiant du résultat.
class QuizPlayPage extends StatelessWidget {
  const QuizPlayPage({super.key, required this.quizId});

  final String quizId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QuizPlayBloc>()..add(PlayStarted(quizId)),
      child: QuizPlayView(quizId: quizId),
    );
  }
}

class QuizPlayView extends StatelessWidget {
  const QuizPlayView({super.key, required this.quizId});

  final String quizId;

  Future<void> _confirmQuit(BuildContext context) async {
    final status = context.read<QuizPlayBloc>().state.status;
    if (status != PlayStatus.inProgress) {
      context.pop();
      return;
    }
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Quitter le quiz ?', style: AppText.bold(17)),
        content: Text(
          'Tes réponses sont enregistrées, mais le chronomètre continue. '
          'Reviens avant la fin du temps pour envoyer ton quiz.',
          style: AppText.regular(13, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Continuer', style: AppText.semibold(13, color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Quitter', style: AppText.semibold(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (quit == true && context.mounted) context.pop();
  }

  Future<void> _submit(BuildContext context, QuizPlayState state) async {
    final missing = state.questionCount - state.answers.length;
    if (missing > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Envoyer le quiz ?', style: AppText.bold(17)),
          content: Text(
            '${Fmt.plural(missing, 'question reste', 'questions restent')} sans réponse. '
            'Après l’envoi, tu ne pourras plus modifier tes réponses.',
            style: AppText.regular(13, color: AppColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Revenir', style: AppText.semibold(13, color: AppColors.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Envoyer', style: AppText.semibold(13, color: AppColors.primary)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (context.mounted) context.read<QuizPlayBloc>().add(const PlaySubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizPlayBloc, QuizPlayState>(
      listenWhen: (p, c) => c.message != null || (c.status == PlayStatus.submitted && p.status != c.status),
      listener: (context, state) {
        if (state.status == PlayStatus.submitted) {
          context.pop(state.resultId);
          return;
        }
        if (state.status != PlayStatus.loadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: state.status != PlayStatus.inProgress && state.status != PlayStatus.submitting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && state.status == PlayStatus.inProgress) _confirmQuit(context);
          },
          child: Scaffold(
            body: SafeArea(
              child: switch (state.status) {
                PlayStatus.loading => const LoadingView(),
                PlayStatus.loadFailure => Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Fermer',
                        onPressed: () => context.pop(),
                        icon: const AppIcon(AppIcons.close, size: 22),
                      ),
                    ),
                    Expanded(
                      child: ErrorView(
                        message: state.message ?? 'Impossible de démarrer le quiz.',
                        onRetry: () => context.read<QuizPlayBloc>().add(PlayStarted(quizId)),
                      ),
                    ),
                  ],
                ),
                _ => _QuizContent(
                  state: state,
                  onClose: () => _confirmQuit(context),
                  onSubmit: () => _submit(context, state),
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _QuizContent extends StatelessWidget {
  const _QuizContent({required this.state, required this.onClose, required this.onSubmit});

  final QuizPlayState state;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizPlayBloc>();
    final question = state.currentQuestion!;
    final progress = (state.currentIndex + 1) / state.questionCount;
    final timeUp = state.remaining == Duration.zero;
    final selected = state.selectedOption != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Contrôles : fermer · titre · temps restant
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Quitter le quiz',
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 32, height: 34),
                      icon: const AppIcon(AppIcons.close, size: 22),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        state.attempt!.quizTitle,
                        style: AppText.semibold(15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _TimerChip(remaining: state.remaining, alert: state.isRunningOut),
                  ],
                ),
                const SizedBox(height: 17),

                // Progression
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Question ${state.currentIndex + 1} sur ${state.questionCount}',
                        style: AppText.medium(12, color: AppColors.muted),
                      ),
                    ),
                    Text(Fmt.percent(progress), style: AppText.bold(12, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 9),
                ProgressTrack(value: progress),
                const SizedBox(height: 17),

                // Énoncé
                const Align(alignment: Alignment.centerLeft, child: Tag('UNE SEULE RÉPONSE')),
                const SizedBox(height: 10),
                Text(question.text, style: AppText.bold(25)),
                const SizedBox(height: 17),

                // Réponses
                for (final (i, option) in question.options.indexed) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _AnswerOption(
                    letter: String.fromCharCode(65 + i),
                    text: option,
                    selected: state.selectedOption == i,
                    enabled: state.status == PlayStatus.inProgress && !timeUp,
                    onTap: () => bloc.add(PlayAnswerSelected(i)),
                  ),
                ],
                const SizedBox(height: 17),
                Text(
                  timeUp
                      ? 'Temps écoulé : seules les réponses enregistrées seront corrigées.'
                      : 'La correction sera disponible après l’envoi du quiz.',
                  style: AppText.regular(11, color: timeUp ? AppColors.danger : AppColors.muted),
                ),
                const SizedBox(height: 17),
                PrimaryButton(
                  label: state.isLastQuestion || timeUp ? 'Envoyer le quiz' : 'Question suivante',
                  loading: state.status == PlayStatus.submitting,
                  onPressed: state.isLastQuestion || timeUp
                      ? onSubmit
                      : () => bloc.add(PlayQuestionChanged(state.currentIndex + 1)),
                ),
                if (state.currentIndex > 0 && !timeUp) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => bloc.add(PlayQuestionChanged(state.currentIndex - 1)),
                      child: Text('← Question précédente', style: AppText.semibold(12, color: AppColors.primary)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(
          height: 72,
          child: Center(
            child: Text(
              '${Fmt.plural(state.saved.length, 'réponse enregistrée', 'réponses enregistrées')} · '
              '${selected ? '1 réponse sélectionnée' : 'aucune réponse sélectionnée'}',
              style: AppText.medium(12, color: AppColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.remaining, required this.alert});

  final Duration remaining;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final fg = alert ? AppColors.danger : AppColors.warning;
    final bg = alert ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warningSoft;
    return Semantics(
      label: 'Temps restant ${Fmt.duration(remaining)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.clock, size: 16, color: fg),
            const SizedBox(width: 5),
            Text(
              Fmt.duration(remaining),
              style: AppText.bold(13, color: fg).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.letter,
    required this.text,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: 'Réponse $letter : $text',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    letter,
                    textAlign: TextAlign.center,
                    style: AppText.bold(12, color: selected ? Colors.white : AppColors.muted),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: selected ? AppText.semibold(13, color: AppColors.primary) : AppText.medium(13),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 12),
                  const AppIcon(AppIcons.check, size: 17, color: AppColors.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
