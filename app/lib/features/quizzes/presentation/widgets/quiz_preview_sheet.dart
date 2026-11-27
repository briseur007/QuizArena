import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/tag.dart';
import '../bloc/quiz_editor_bloc.dart';

/// « Prévisualiser le quiz » : récapitulatif, puis enregistrer ou publier.
Future<void> showQuizPreview(BuildContext context, QuizEditorBloc bloc) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(value: bloc, child: const _QuizPreview()),
  );
}

class _QuizPreview extends StatelessWidget {
  const _QuizPreview();

  @override
  Widget build(BuildContext context) {
    // La feuille se ferme AVANT l'envoi : la page affiche ensuite le
    // chargement et le message (succès ou erreur de validation).
    void send(QuizEditorEvent event) {
      final bloc = context.read<QuizEditorBloc>();
      Navigator.pop(context);
      bloc.add(event);
    }

    return BlocBuilder<QuizEditorBloc, QuizEditorState>(
      builder: (context, state) {
        final draft = state.draft;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (context, scroll) => Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Text(draft.title.isEmpty ? 'Sans titre' : draft.title, style: AppText.bold(22)),
                    const SizedBox(height: 4),
                    Text(
                      '${Fmt.plural(draft.questions.length, 'question')} · ${draft.durationMinutes} min · '
                      '${Fmt.plural(draft.maxAttempts, 'tentative')}',
                      style: AppText.regular(12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    for (final (i, q) in draft.questions.indexed) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Tag(Fmt.twoDigits(i + 1)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    q.text.isEmpty ? '(énoncé manquant)' : q.text,
                                    style: AppText.semibold(13),
                                  ),
                                ),
                                if (!q.isComplete) const Tag.warning('INCOMPLÈTE'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final (j, option) in q.options.indexed)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      child: q.correctIndex == j
                                          ? const AppIcon(AppIcons.check, size: 15, color: AppColors.success)
                                          : null,
                                    ),
                                    Text(
                                      '${String.fromCharCode(65 + j)}. ',
                                      style: AppText.bold(12, color: AppColors.muted),
                                    ),
                                    Expanded(
                                      child: Text(
                                        option.isEmpty ? '—' : option,
                                        style: AppText.medium(
                                          12,
                                          color: q.correctIndex == j ? AppColors.success : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isBusy ? null : () => send(const EditorSaveRequested()),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Enregistrer', style: AppText.semibold(14, color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Publier',
                          trailingIcon: null,
                          fontSize: 14,
                          loading: state.isBusy,
                          onPressed: () => send(const EditorPublishRequested()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
