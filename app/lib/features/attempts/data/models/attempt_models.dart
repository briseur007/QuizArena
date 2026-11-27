import '../../domain/entities/attempt.dart';
import '../../domain/entities/attempt_result.dart';
import '../../domain/entities/leaderboard.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

abstract final class AttemptModel {
  /// [receivedAt] = heure du téléphone à la réception, pour calculer l'écart
  /// avec `serverTime` et afficher un minuteur fidèle au serveur.
  static Attempt fromJson(Map<String, dynamic> json, {DateTime? receivedAt}) {
    final serverTime = DateTime.tryParse(json['serverTime'] as String? ?? '');
    final now = receivedAt ?? DateTime.now();
    final answers = (json['answers'] as Map<String, dynamic>?) ?? const {};

    return Attempt(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      clockOffset: serverTime == null ? Duration.zero : serverTime.difference(now),
      savedAnswers: answers.map((k, v) => MapEntry(k, _int(v))),
      questions: (json['questions'] as List)
          .cast<Map<String, dynamic>>()
          .map(
            (q) => AttemptQuestion(
              id: q['id'] as String,
              text: q['text'] as String,
              options: (q['options'] as List).cast<String>(),
            ),
          )
          .toList(),
    );
  }
}

abstract final class AttemptResultModel {
  static AttemptResult fromJson(Map<String, dynamic> json) => AttemptResult(
    id: json['id'] as String,
    quizId: json['quizId'] as String,
    courseId: json['courseId'] as String? ?? '',
    quizTitle: json['quizTitle'] as String? ?? '',
    courseName: json['courseName'] as String? ?? '',
    studentName: json['studentName'] as String? ?? '',
    score: _int(json['score']),
    total: _int(json['total']),
    durationSeconds: _int(json['durationSeconds']),
    attemptNumber: _int(json['attemptNumber']),
    maxAttempts: _int(json['maxAttempts']),
    corrections: (json['corrections'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (c) => Correction(
            index: _int(c['index']),
            question: c['question'] as String,
            chosenAnswer: c['chosenAnswer'] as String?,
            isCorrect: c['isCorrect'] as bool? ?? false,
            correctAnswer: c['correctAnswer'] as String? ?? '',
            explanation: c['explanation'] as String?,
          ),
        )
        .toList(),
  );
}

abstract final class LeaderboardModel {
  static Leaderboard fromJson(Map<String, dynamic> json) => Leaderboard(
    title: json['title'] as String? ?? '',
    participants: _int(json['participants']),
    entries: (json['entries'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (e) => LeaderboardEntry(
            rank: _int(e['rank']),
            name: e['name'] as String,
            score: _int(e['score']),
            total: _int(e['total']),
            durationSeconds: _int(e['durationSeconds']),
            isMe: e['isMe'] as bool? ?? false,
          ),
        )
        .toList(),
  );
}
