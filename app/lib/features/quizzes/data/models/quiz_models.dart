import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_report.dart';

QuizStatus _status(Object? value) => switch (value) {
  'open' => QuizStatus.open,
  'closed' => QuizStatus.closed,
  _ => QuizStatus.draft,
};

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

abstract final class QuizModel {
  static Quiz fromJson(Map<String, dynamic> json) => Quiz(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    courseName: json['courseName'] as String? ?? '',
    courseLevel: json['courseLevel'] as String? ?? '',
    title: json['title'] as String,
    durationMinutes: _int(json['durationMinutes']),
    maxAttempts: _int(json['maxAttempts']),
    questionCount: _int(json['questionCount']),
    status: _status(json['status']),
    attemptsUsed: _int(json['attemptsUsed']),
    submissionCount: _int(json['submissionCount']),
    studentCount: _int(json['studentCount']),
  );

  static String statusToJson(QuizStatus s) => s.name;
}

abstract final class QuizDraftModel {
  static QuizDraft fromJson(Map<String, dynamic> json) => QuizDraft(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    title: json['title'] as String? ?? '',
    durationMinutes: _int(json['durationMinutes']),
    maxAttempts: _int(json['maxAttempts']),
    status: _status(json['status']),
    questions: (json['questions'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (q) => QuestionDraft(
            text: q['text'] as String? ?? '',
            options: (q['options'] as List).cast<String>(),
            correctIndex: (q['correctIndex'] as num?)?.toInt(),
            explanation: q['explanation'] as String? ?? '',
          ),
        )
        .toList(),
  );

  /// Corps de POST /courses/:id/quizzes et PATCH /quizzes/:id.
  static Map<String, dynamic> toJson(QuizDraft d) => {
    'title': d.title.trim(),
    'durationMinutes': d.durationMinutes,
    'maxAttempts': d.maxAttempts,
    'questions': [
      for (final q in d.questions)
        {
          'text': q.text.trim(),
          'options': q.options.map((o) => o.trim()).toList(),
          'correctIndex': q.correctIndex,
          if (q.explanation.trim().isNotEmpty) 'explanation': q.explanation.trim(),
        },
    ],
  };
}

abstract final class QuizReportModel {
  static QuizReport fromJson(Map<String, dynamic> json) => QuizReport(
    quizId: json['quizId'] as String,
    title: json['title'] as String,
    courseName: json['courseName'] as String? ?? '',
    status: _status(json['status']),
    questionCount: _int(json['questionCount']),
    studentCount: _int(json['studentCount']),
    average: (json['average'] as num?)?.toDouble() ?? 0,
    questions: (json['questions'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (q) => QuestionStat(
            index: _int(q['index']),
            text: q['text'] as String,
            correctCount: _int(q['correctCount']),
            answeredCount: _int(q['answeredCount']),
          ),
        )
        .toList(),
    submissions: (json['submissions'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (s) => Submission(
            attemptId: s['attemptId'] as String,
            studentName: s['studentName'] as String,
            score: _int(s['score']),
            total: _int(s['total']),
            durationSeconds: _int(s['durationSeconds']),
          ),
        )
        .toList(),
  );
}
