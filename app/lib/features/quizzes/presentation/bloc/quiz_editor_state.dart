part of 'quiz_editor_bloc.dart';

enum EditorStatus { loading, loadFailure, ready, saving, publishing, published }

final class QuizEditorState extends Equatable {
  const QuizEditorState({
    this.status = EditorStatus.loading,
    this.draft = const QuizDraft(courseId: ''),
    this.courseName = '',
    this.currentIndex = 0,
    this.dirty = false,
    this.showErrors = false,
    this.message,
  });

  final EditorStatus status;
  final QuizDraft draft;
  final String courseName;

  /// Question affichée dans l'éditeur.
  final int currentIndex;

  /// Modifications non enregistrées.
  final bool dirty;

  /// Après une tentative d'envoi invalide : on souligne les champs vides.
  final bool showErrors;

  /// Message ponctuel (SnackBar).
  final String? message;

  QuestionDraft get current => draft.questions[currentIndex];
  bool get isBusy => status == EditorStatus.saving || status == EditorStatus.publishing;

  QuizEditorState copyWith({
    EditorStatus? status,
    QuizDraft? draft,
    String? courseName,
    int? currentIndex,
    bool? dirty,
    bool? showErrors,
    String? message,
  }) => QuizEditorState(
    status: status ?? this.status,
    draft: draft ?? this.draft,
    courseName: courseName ?? this.courseName,
    currentIndex: currentIndex ?? this.currentIndex,
    dirty: dirty ?? this.dirty,
    showErrors: showErrors ?? this.showErrors,
    message: message,
  );

  @override
  List<Object?> get props => [status, draft, courseName, currentIndex, dirty, showErrors, message];
}
