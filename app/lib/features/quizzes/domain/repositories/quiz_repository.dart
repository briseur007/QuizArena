import '../../../../core/error/result.dart';
import '../entities/quiz.dart';
import '../entities/quiz_draft.dart';
import '../entities/quiz_report.dart';

abstract interface class QuizRepository {
  /// Quiz d'un cours (étudiant : publiés seulement ; enseignant : tous).
  Future<Result<List<Quiz>>> courseQuizzes(String courseId);

  /// Étudiant ([todo]) : quiz ouverts qu'il peut encore passer.
  /// Enseignant ([status]) : ses quiz filtrés par statut.
  Future<Result<List<Quiz>>> myQuizzes({bool todo = false, QuizStatus? status});

  /// Enseignant : quiz complet, bonnes réponses incluses.
  Future<Result<QuizDraft>> getDraft(String quizId);

  /// Crée ou met à jour le brouillon (selon [QuizDraft.isNew]).
  Future<Result<QuizDraft>> saveDraft(QuizDraft draft);

  Future<Result<Quiz>> publish(String quizId);

  Future<Result<QuizReport>> report(String quizId);
}
