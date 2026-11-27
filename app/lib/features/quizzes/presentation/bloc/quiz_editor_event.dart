part of 'quiz_editor_bloc.dart';

sealed class QuizEditorEvent extends Equatable {
  const QuizEditorEvent();

  @override
  List<Object?> get props => [];
}

/// Nouveau quiz ([quizId] null) ou modification d'un brouillon existant.
final class EditorStarted extends QuizEditorEvent {
  const EditorStarted({required this.courseId, required this.courseName, this.quizId});
  final String courseId;
  final String courseName;
  final String? quizId;

  @override
  List<Object?> get props => [courseId, courseName, quizId];
}

final class EditorTitleChanged extends QuizEditorEvent {
  const EditorTitleChanged(this.title);
  final String title;

  @override
  List<Object?> get props => [title];
}

final class EditorDurationChanged extends QuizEditorEvent {
  const EditorDurationChanged(this.minutes);
  final int minutes;

  @override
  List<Object?> get props => [minutes];
}

final class EditorMaxAttemptsChanged extends QuizEditorEvent {
  const EditorMaxAttemptsChanged(this.attempts);
  final int attempts;

  @override
  List<Object?> get props => [attempts];
}

final class EditorQuestionTextChanged extends QuizEditorEvent {
  const EditorQuestionTextChanged(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}

final class EditorOptionChanged extends QuizEditorEvent {
  const EditorOptionChanged(this.index, this.text);
  final int index;
  final String text;

  @override
  List<Object?> get props => [index, text];
}

final class EditorCorrectOptionSelected extends QuizEditorEvent {
  const EditorCorrectOptionSelected(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

final class EditorExplanationChanged extends QuizEditorEvent {
  const EditorExplanationChanged(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}

final class EditorQuestionAdded extends QuizEditorEvent {
  const EditorQuestionAdded();
}

final class EditorQuestionRemoved extends QuizEditorEvent {
  const EditorQuestionRemoved();
}

final class EditorQuestionSelected extends QuizEditorEvent {
  const EditorQuestionSelected(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

final class EditorSaveRequested extends QuizEditorEvent {
  const EditorSaveRequested();
}

final class EditorPublishRequested extends QuizEditorEvent {
  const EditorPublishRequested();
}
