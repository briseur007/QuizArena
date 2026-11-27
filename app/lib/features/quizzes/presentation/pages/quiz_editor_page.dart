import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/entities/quiz_draft.dart';
import '../bloc/quiz_editor_bloc.dart';
import '../widgets/quiz_preview_sheet.dart';

/// Écran 07 · Créer un quiz (ou modifier un brouillon).
class QuizEditorPage extends StatelessWidget {
  const QuizEditorPage({super.key, required this.courseId, required this.courseName, this.quizId});

  final String courseId;
  final String courseName;
  final String? quizId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<QuizEditorBloc>()..add(EditorStarted(courseId: courseId, courseName: courseName, quizId: quizId)),
      child: const QuizEditorView(),
    );
  }
}

class QuizEditorView extends StatelessWidget {
  const QuizEditorView({super.key});

  static const _durations = [5, 10, 15, 20, 30, 45, 60];
  static const _attempts = [1, 2, 3, 5];

  Future<void> _leave(BuildContext context) async {
    if (!context.read<QuizEditorBloc>().state.dirty) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Quitter sans enregistrer ?', style: AppText.bold(17)),
        content: Text(
          'Tes dernières modifications seront perdues.',
          style: AppText.regular(13, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Rester', style: AppText.semibold(13, color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Quitter', style: AppText.semibold(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) context.pop();
  }

  Future<void> _pick<T>(
    BuildContext context,
    String title,
    List<T> values,
    String Function(T) label,
    ValueChanged<T> onPicked,
  ) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppText.bold(15)),
            for (final v in values)
              ListTile(
                title: Text(label(v), style: AppText.semibold(14)),
                onTap: () => Navigator.pop(context, v),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizEditorBloc, QuizEditorState>(
      listenWhen: (p, c) => c.message != null || (c.status == EditorStatus.published && p.status != c.status),
      listener: (context, state) {
        if (state.message != null && state.status != EditorStatus.loadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        }
        if (state.status == EditorStatus.published) context.pop();
      },
      builder: (context, state) {
        final bloc = context.read<QuizEditorBloc>();
        return PopScope(
          canPop: !state.dirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave(context);
          },
          child: Scaffold(
            body: SafeArea(
              child: switch (state.status) {
                EditorStatus.loading => const LoadingView(),
                EditorStatus.loadFailure => ErrorView(message: state.message ?? 'Erreur', onRetry: () => context.pop()),
                _ => Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        children: [
                          // En-tête
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Retour',
                                onPressed: () => _leave(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(width: 32, height: 34),
                                icon: const AppIcon(AppIcons.back, size: 22),
                              ),
                              Expanded(
                                child: Text(
                                  state.draft.isNew ? 'Créer un quiz' : 'Modifier le quiz',
                                  style: AppText.bold(22),
                                ),
                              ),
                              Tag(state.dirty ? 'Non enregistré' : 'Brouillon'),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Paramètres
                          Text(state.courseName.toUpperCase(), style: AppText.bold(10, color: AppColors.primary)),
                          const SizedBox(height: 9),
                          SurfaceCard(
                            radius: 12,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Titre du quiz', style: AppText.medium(10, color: AppColors.muted)),
                                const SizedBox(height: 4),
                                _BareField(
                                  key: const ValueKey('title'),
                                  initialValue: state.draft.title,
                                  hint: 'Ex. Flutter & BLoC',
                                  style: AppText.semibold(16),
                                  error: state.showErrors && state.draft.title.trim().length < 3,
                                  onChanged: (v) => bloc.add(EditorTitleChanged(v)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                child: _SettingBox(
                                  leading: const AppIcon(AppIcons.clock, color: AppColors.primary),
                                  label: '${state.draft.durationMinutes} min',
                                  onTap: () => _pick<int>(
                                    context,
                                    'Durée du quiz',
                                    _durations,
                                    (m) => '$m min',
                                    (m) => bloc.add(EditorDurationChanged(m)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SettingBox(
                                  label: Fmt.plural(state.draft.maxAttempts, 'tentative'),
                                  trailing: const AppIcon(AppIcons.chevron, size: 16, color: AppColors.muted),
                                  onTap: () => _pick<int>(
                                    context,
                                    'Tentatives autorisées',
                                    _attempts,
                                    (n) => Fmt.plural(n, 'tentative'),
                                    (n) => bloc.add(EditorMaxAttemptsChanged(n)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Navigation entre questions
                          Row(
                            children: [
                              Expanded(child: Text('Questions', style: AppText.bold(17))),
                              if (state.currentIndex > 0)
                                _LinkText('← Préc.', () => bloc.add(EditorQuestionSelected(state.currentIndex - 1))),
                              const SizedBox(width: 8),
                              Tag(
                                '${Fmt.twoDigits(state.currentIndex + 1)} / '
                                '${Fmt.twoDigits(state.draft.questions.length)}',
                              ),
                              const SizedBox(width: 8),
                              if (state.currentIndex < state.draft.questions.length - 1)
                                _LinkText('Suivante →', () => bloc.add(EditorQuestionSelected(state.currentIndex + 1))),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Éditeur de la question courante. La clé recrée les
                          // champs quand on change de question.
                          _QuestionEditor(
                            key: ValueKey('${state.draft.id}-${state.currentIndex}-${state.draft.questions.length}'),
                            question: state.current,
                            showErrors: state.showErrors,
                            canRemove: state.draft.questions.length > 1,
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () => bloc.add(const EditorQuestionAdded()),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const AppIcon(AppIcons.plus, color: AppColors.primary),
                                  const SizedBox(width: 7),
                                  Text('Ajouter une question', style: AppText.semibold(12, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Les bonnes réponses restent masquées aux étudiants avant la remise.',
                            style: AppText.regular(11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 15),
                      child: PrimaryButton(
                        label: 'Prévisualiser le quiz',
                        leadingIcon: AppIcons.arrow,
                        trailingIcon: null,
                        verticalPadding: 14,
                        fontSize: 14,
                        loading: state.isBusy,
                        onPressed: () => showQuizPreview(context, bloc),
                      ),
                    ),
                  ],
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({super.key, required this.question, required this.showErrors, required this.canRemove});

  final QuestionDraft question;
  final bool showErrors;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizEditorBloc>();
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('CHOIX UNIQUE', style: AppText.bold(10, color: AppColors.primary)),
              ),
              if (canRemove)
                _LinkText('Supprimer', () => bloc.add(const EditorQuestionRemoved()), color: AppColors.danger),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: _BareField(
              initialValue: question.text,
              hint: 'Énoncé de la question',
              style: AppText.semibold(16),
              maxLines: null,
              error: showErrors && question.text.trim().isEmpty,
              onChanged: (v) => bloc.add(EditorQuestionTextChanged(v)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.correctIndex == null && showErrors
                ? 'Touche le rond de la bonne réponse.'
                : 'Sélectionnez la bonne réponse.',
            style: AppText.regular(
              11,
              color: question.correctIndex == null && showErrors ? AppColors.danger : AppColors.muted,
            ),
          ),
          for (var i = 0; i < QuestionDraft.optionCount; i++) ...[
            const SizedBox(height: 10),
            _OptionRow(
              index: i,
              value: question.options[i],
              correct: question.correctIndex == i,
              error: showErrors && question.options[i].trim().isEmpty,
            ),
          ],
          const SizedBox(height: 10),
          _BareField(
            initialValue: question.explanation,
            hint: 'Explication affichée après la remise (facultatif)',
            style: AppText.regular(12),
            maxLines: null,
            onChanged: (v) => bloc.add(EditorExplanationChanged(v)),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.index, required this.value, required this.correct, required this.error});

  final int index;
  final String value;
  final bool correct;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QuizEditorBloc>();
    final fg = correct ? AppColors.success : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: correct ? AppColors.successSoft : AppColors.background,
        borderRadius: BorderRadius.circular(9),
        border: error ? Border.all(color: AppColors.danger) : null,
      ),
      child: Row(
        children: [
          Text(
            String.fromCharCode(65 + index),
            style: AppText.bold(11, color: correct ? AppColors.success : AppColors.muted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BareField(
              initialValue: value,
              hint: 'Réponse ${String.fromCharCode(65 + index)}',
              style: AppText.medium(13, color: fg),
              onChanged: (v) => bloc.add(EditorOptionChanged(index, v)),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: correct ? 'Bonne réponse' : 'Choisir comme bonne réponse',
            button: true,
            child: InkResponse(
              onTap: () => bloc.add(EditorCorrectOptionSelected(index)),
              radius: 18,
              child: correct
                  ? const AppIcon(AppIcons.check, size: 17, color: AppColors.success)
                  : const AppIcon(AppIcons.radio, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ texte sans bordure, posé dans un bloc coloré de la maquette.
class _BareField extends StatelessWidget {
  const _BareField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.style,
    this.hint,
    this.maxLines = 1,
    this.error = false,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextStyle style;
  final String? hint;
  final int? maxLines;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: style,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: style.copyWith(color: error ? AppColors.danger : AppColors.muted),
        filled: false,
        isCollapsed: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

class _SettingBox extends StatelessWidget {
  const _SettingBox({required this.label, required this.onTap, this.leading, this.trailing});

  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 10,
      padding: const EdgeInsets.all(11),
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(child: Text(label, style: AppText.semibold(13))),
          ?trailing,
        ],
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText(this.text, this.onTap, {this.color = AppColors.primary});

  final String text;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(text, style: AppText.semibold(11, color: color)),
      ),
    );
  }
}
