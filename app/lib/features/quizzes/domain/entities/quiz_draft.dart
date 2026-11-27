import 'package:equatable/equatable.dart';

import 'quiz.dart';

/// Question en cours d'édition par l'enseignant (QCM à 4 choix, une bonne réponse).
class QuestionDraft extends Equatable {
  const QuestionDraft({
    this.text = '',
    this.options = const ['', '', '', ''],
    this.correctIndex,
    this.explanation = '',
  });

  static const optionCount = 4;

  final String text;
  final List<String> options;
  final int? correctIndex;

  /// Explication affichée à l'étudiant après la remise.
  final String explanation;

  bool get isComplete => text.trim().isNotEmpty && options.every((o) => o.trim().isNotEmpty) && correctIndex != null;

  QuestionDraft copyWith({String? text, List<String>? options, int? correctIndex, String? explanation}) =>
      QuestionDraft(
        text: text ?? this.text,
        options: options ?? this.options,
        correctIndex: correctIndex ?? this.correctIndex,
        explanation: explanation ?? this.explanation,
      );

  QuestionDraft withOption(int index, String value) =>
      copyWith(options: [for (var i = 0; i < options.length; i++) i == index ? value : options[i]]);

  @override
  List<Object?> get props => [text, options, correctIndex, explanation];
}

/// Quiz complet côté enseignant (avec les bonnes réponses).
class QuizDraft extends Equatable {
  const QuizDraft({
    required this.courseId,
    this.id,
    this.title = '',
    this.durationMinutes = 10,
    this.maxAttempts = 1,
    this.questions = const [QuestionDraft()],
    this.status = QuizStatus.draft,
  });

  final String? id;
  final String courseId;
  final String title;
  final int durationMinutes;
  final int maxAttempts;
  final List<QuestionDraft> questions;
  final QuizStatus status;

  bool get isNew => id == null;

  QuizDraft copyWith({
    String? id,
    String? title,
    int? durationMinutes,
    int? maxAttempts,
    List<QuestionDraft>? questions,
    QuizStatus? status,
  }) => QuizDraft(
    id: id ?? this.id,
    courseId: courseId,
    title: title ?? this.title,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    maxAttempts: maxAttempts ?? this.maxAttempts,
    questions: questions ?? this.questions,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [id, courseId, title, durationMinutes, maxAttempts, questions, status];
}
