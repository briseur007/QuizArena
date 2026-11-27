import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiz_arena/core/error/failure.dart';
import 'package:quiz_arena/core/error/result.dart';
import 'package:quiz_arena/features/quizzes/domain/entities/quiz_draft.dart';
import 'package:quiz_arena/features/quizzes/domain/repositories/quiz_repository.dart';
import 'package:quiz_arena/features/quizzes/presentation/bloc/quiz_editor_bloc.dart';

import '../../helpers/fixtures.dart';

class MockQuizRepository extends Mock implements QuizRepository {}

void main() {
  late MockQuizRepository repo;

  setUpAll(() => registerFallbackValue(const QuizDraft(courseId: 'c1')));
  setUp(() => repo = MockQuizRepository());

  const ready = QuizEditorState(
    status: EditorStatus.ready,
    courseName: 'Développement mobile',
    draft: QuizDraft(courseId: 'c1'),
  );

  blocTest<QuizEditorBloc, QuizEditorState>(
    'nouveau quiz : brouillon vide avec une question',
    build: () => QuizEditorBloc(repo),
    act: (b) => b.add(const EditorStarted(courseId: 'c1', courseName: 'Développement mobile')),
    expect: () => [ready],
  );

  blocTest<QuizEditorBloc, QuizEditorState>(
    'édition de la question : texte, options et bonne réponse',
    build: () => QuizEditorBloc(repo),
    seed: () => ready,
    act: (b) => b
      ..add(const EditorQuestionTextChanged('Quel langage utilise Flutter ?'))
      ..add(const EditorOptionChanged(0, 'Dart'))
      ..add(const EditorCorrectOptionSelected(0)),
    skip: 2,
    expect: () => [
      isA<QuizEditorState>()
          .having((s) => s.current.text, 'text', 'Quel langage utilise Flutter ?')
          .having((s) => s.current.options.first, 'option A', 'Dart')
          .having((s) => s.current.correctIndex, 'correct', 0)
          .having((s) => s.dirty, 'dirty', isTrue),
    ],
  );

  blocTest<QuizEditorBloc, QuizEditorState>(
    'ajout puis suppression de question : l’index courant suit',
    build: () => QuizEditorBloc(repo),
    seed: () => ready,
    act: (b) => b
      ..add(const EditorQuestionAdded())
      ..add(const EditorQuestionRemoved()),
    expect: () => [
      isA<QuizEditorState>().having((s) => s.draft.questions.length, 'n', 2).having((s) => s.currentIndex, 'i', 1),
      isA<QuizEditorState>().having((s) => s.draft.questions.length, 'n', 1).having((s) => s.currentIndex, 'i', 0),
    ],
  );

  blocTest<QuizEditorBloc, QuizEditorState>(
    'publier un quiz incomplet : refusé localement, aucun appel réseau',
    build: () => QuizEditorBloc(repo),
    seed: () => ready.copyWith(
      draft: const QuizDraft(courseId: 'c1', title: 'Flutter & BLoC'),
    ),
    act: (b) => b.add(const EditorPublishRequested()),
    expect: () => [
      isA<QuizEditorState>()
          .having((s) => s.showErrors, 'showErrors', isTrue)
          .having((s) => s.message, 'message', startsWith('Question 1 incomplète')),
    ],
    verify: (_) => verifyNever(() => repo.saveDraft(any())),
  );

  blocTest<QuizEditorBloc, QuizEditorState>(
    'publier un quiz complet : enregistre puis publie',
    setUp: () {
      when(() => repo.saveDraft(any()))
          .thenAnswer((inv) async => Ok((inv.positionalArguments.first as QuizDraft).copyWith(id: 'q1')));
      when(() => repo.publish('q1')).thenAnswer((_) async => const Ok(Fx.quiz));
    },
    build: () => QuizEditorBloc(repo),
    seed: () => ready.copyWith(
      draft: const QuizDraft(courseId: 'c1', title: 'Flutter & BLoC', questions: [Fx.completeQuestion]),
      dirty: true,
    ),
    act: (b) => b.add(const EditorPublishRequested()),
    expect: () => [
      isA<QuizEditorState>().having((s) => s.status, 'status', EditorStatus.saving),
      isA<QuizEditorState>()
          .having((s) => s.status, 'status', EditorStatus.ready)
          .having((s) => s.dirty, 'dirty', false),
      isA<QuizEditorState>().having((s) => s.status, 'status', EditorStatus.publishing),
      isA<QuizEditorState>().having((s) => s.status, 'status', EditorStatus.published),
    ],
  );

  blocTest<QuizEditorBloc, QuizEditorState>(
    'erreur serveur à l’enregistrement : message, modifications conservées',
    setUp: () => when(() => repo.saveDraft(any())).thenAnswer((_) async => const Err(ServerFailure('Oups'))),
    build: () => QuizEditorBloc(repo),
    seed: () => ready.copyWith(
      draft: const QuizDraft(courseId: 'c1', title: 'Flutter & BLoC'),
      dirty: true,
    ),
    act: (b) => b.add(const EditorSaveRequested()),
    expect: () => [
      isA<QuizEditorState>().having((s) => s.status, 'status', EditorStatus.saving),
      isA<QuizEditorState>()
          .having((s) => s.status, 'status', EditorStatus.ready)
          .having((s) => s.dirty, 'dirty', isTrue)
          .having((s) => s.message, 'message', 'Oups'),
    ],
  );
}
