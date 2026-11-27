import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/repositories/quiz_repository.dart';

part 'quiz_editor_event.dart';
part 'quiz_editor_state.dart';

/// Écran 07 · Créer un quiz.
///
/// Les modifications de champs sont traitées dans l'ordre (transformer par
/// défaut, concurrent mais synchrone ici) ; « Enregistrer » et « Publier »
/// utilisent `droppable` pour ignorer un double appui pendant l'envoi.
class QuizEditorBloc extends Bloc<QuizEditorEvent, QuizEditorState> {
  QuizEditorBloc(this._repository) : super(const QuizEditorState()) {
    on<EditorStarted>(_onStarted);
    on<EditorTitleChanged>((e, emit) => _update(emit, state.draft.copyWith(title: e.title)));
    on<EditorDurationChanged>((e, emit) => _update(emit, state.draft.copyWith(durationMinutes: e.minutes)));
    on<EditorMaxAttemptsChanged>((e, emit) => _update(emit, state.draft.copyWith(maxAttempts: e.attempts)));
    on<EditorQuestionTextChanged>((e, emit) => _updateQuestion(emit, state.current.copyWith(text: e.text)));
    on<EditorOptionChanged>((e, emit) => _updateQuestion(emit, state.current.withOption(e.index, e.text)));
    on<EditorCorrectOptionSelected>((e, emit) => _updateQuestion(emit, state.current.copyWith(correctIndex: e.index)));
    on<EditorExplanationChanged>((e, emit) => _updateQuestion(emit, state.current.copyWith(explanation: e.text)));
    on<EditorQuestionAdded>(_onQuestionAdded);
    on<EditorQuestionRemoved>(_onQuestionRemoved);
    on<EditorQuestionSelected>(_onQuestionSelected);
    on<EditorSaveRequested>(_onSave, transformer: droppable());
    on<EditorPublishRequested>(_onPublish, transformer: droppable());
  }

  final QuizRepository _repository;

  static const maxQuestions = 50;

  Future<void> _onStarted(EditorStarted e, Emitter<QuizEditorState> emit) async {
    if (e.quizId == null) {
      emit(
        QuizEditorState(
          status: EditorStatus.ready,
          courseName: e.courseName,
          draft: QuizDraft(courseId: e.courseId),
        ),
      );
      return;
    }

    emit(state.copyWith(status: EditorStatus.loading, courseName: e.courseName));
    final result = await _repository.getDraft(e.quizId!);
    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(
            status: EditorStatus.ready,
            draft: value.questions.isEmpty ? value.copyWith(questions: const [QuestionDraft()]) : value,
            currentIndex: 0,
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(status: EditorStatus.loadFailure, message: failure.message));
    }
  }

  void _update(Emitter<QuizEditorState> emit, QuizDraft draft) => emit(state.copyWith(draft: draft, dirty: true));

  void _updateQuestion(Emitter<QuizEditorState> emit, QuestionDraft question) {
    final questions = [...state.draft.questions]..[state.currentIndex] = question;
    _update(emit, state.draft.copyWith(questions: questions));
  }

  void _onQuestionAdded(EditorQuestionAdded e, Emitter<QuizEditorState> emit) {
    if (state.draft.questions.length >= maxQuestions) {
      emit(state.copyWith(message: 'Maximum $maxQuestions questions par quiz.'));
      return;
    }
    final questions = [...state.draft.questions, const QuestionDraft()];
    emit(
      state.copyWith(
        draft: state.draft.copyWith(questions: questions),
        currentIndex: questions.length - 1,
        dirty: true,
      ),
    );
  }

  void _onQuestionRemoved(EditorQuestionRemoved e, Emitter<QuizEditorState> emit) {
    if (state.draft.questions.length <= 1) return;
    final questions = [...state.draft.questions]..removeAt(state.currentIndex);
    emit(
      state.copyWith(
        draft: state.draft.copyWith(questions: questions),
        currentIndex: state.currentIndex.clamp(0, questions.length - 1),
        dirty: true,
      ),
    );
  }

  void _onQuestionSelected(EditorQuestionSelected e, Emitter<QuizEditorState> emit) {
    if (e.index < 0 || e.index >= state.draft.questions.length) return;
    emit(state.copyWith(currentIndex: e.index));
  }

  Future<void> _onSave(EditorSaveRequested e, Emitter<QuizEditorState> emit) async {
    await _save(emit, forPublish: false);
  }

  Future<void> _onPublish(EditorPublishRequested e, Emitter<QuizEditorState> emit) async {
    final saved = await _save(emit, forPublish: true);
    if (saved == null) return;

    emit(state.copyWith(status: EditorStatus.publishing));
    final result = await _repository.publish(saved.id!);
    switch (result) {
      case Ok():
        emit(
          state.copyWith(
            status: EditorStatus.published,
            draft: saved.copyWith(status: QuizStatus.open),
            message: 'Quiz publié : les étudiants du cours peuvent le passer.',
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(status: EditorStatus.ready, message: failure.message));
    }
  }

  /// Valide puis enregistre ; renvoie le brouillon enregistré ou `null`.
  Future<QuizDraft?> _save(Emitter<QuizEditorState> emit, {required bool forPublish}) async {
    final error = validate(state.draft, forPublish: forPublish);
    if (error != null) {
      emit(state.copyWith(message: error.message, currentIndex: error.questionIndex, showErrors: true));
      return null;
    }

    emit(state.copyWith(status: EditorStatus.saving));
    final result = await _repository.saveDraft(state.draft);
    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(
            status: EditorStatus.ready,
            draft: value,
            dirty: false,
            message: forPublish ? null : 'Brouillon enregistré.',
          ),
        );
        return value;
      case Err(failure: ValidationFailure(:final message)):
        emit(state.copyWith(status: EditorStatus.ready, message: message, showErrors: true));
      case Err(:final failure):
        emit(state.copyWith(status: EditorStatus.ready, message: failure.message));
    }
    return null;
  }

  /// Règles locales (le serveur revalide tout). Un brouillon peut être
  /// incomplet ; un quiz publié doit avoir toutes ses questions complètes.
  static EditorValidationError? validate(QuizDraft draft, {required bool forPublish}) {
    if (draft.title.trim().length < 3) {
      return const EditorValidationError('Donne un titre au quiz (3 caractères minimum).');
    }
    if (!forPublish) return null;
    for (final (i, q) in draft.questions.indexed) {
      if (!q.isComplete) {
        return EditorValidationError(
          'Question ${i + 1} incomplète : énoncé, 4 réponses et la bonne réponse.',
          questionIndex: i,
        );
      }
    }
    return null;
  }
}

class EditorValidationError {
  const EditorValidationError(this.message, {this.questionIndex});
  final String message;
  final int? questionIndex;
}
