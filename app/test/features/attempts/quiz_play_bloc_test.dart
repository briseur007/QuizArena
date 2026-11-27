import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiz_arena/core/error/failure.dart';
import 'package:quiz_arena/core/error/result.dart';
import 'package:quiz_arena/features/attempts/domain/repositories/attempt_repository.dart';
import 'package:quiz_arena/features/attempts/presentation/bloc/quiz_play_bloc.dart';

import '../../helpers/fixtures.dart';

class MockAttemptRepository extends Mock implements AttemptRepository {}

void main() {
  late MockAttemptRepository repo;
  late DateTime clock;
  late StreamController<void> ticker;

  setUp(() {
    repo = MockAttemptRepository();
    clock = Fx.now;
    // broadcast : close() se termine même si personne n'écoute le minuteur.
    ticker = StreamController<void>.broadcast();
  });

  tearDown(() => ticker.close());

  QuizPlayBloc build() => QuizPlayBloc(repo, now: () => clock, ticker: () => ticker.stream);

  void stubSave(Result<void> result) => when(
    () => repo.saveAnswer(
      attemptId: any(named: 'attemptId'),
      questionId: any(named: 'questionId'),
      optionIndex: any(named: 'optionIndex'),
    ),
  ).thenAnswer((_) async => result);

  QuizPlayState inProgress({Map<String, int> answers = const {}, Set<String> saved = const {}}) => QuizPlayState(
    status: PlayStatus.inProgress,
    attempt: Fx.attempt(),
    answers: answers,
    saved: saved,
    remaining: const Duration(minutes: 10),
  );

  group('PlayStarted', () {
    blocTest<QuizPlayBloc, QuizPlayState>(
      'tentative démarrée : minuteur calculé depuis l’heure de fin du serveur',
      setUp: () =>
          when(() => repo.start('q1')).thenAnswer((_) async => Ok(Fx.attempt(left: const Duration(minutes: 6)))),
      build: build,
      act: (b) => b.add(const PlayStarted('q1')),
      expect: () => [
        const QuizPlayState(),
        isA<QuizPlayState>()
            .having((s) => s.status, 'status', PlayStatus.inProgress)
            .having((s) => s.remaining, 'remaining', const Duration(minutes: 6)),
      ],
    );

    blocTest<QuizPlayBloc, QuizPlayState>(
      'reprise : les réponses déjà enregistrées sont restaurées',
      setUp: () => when(() => repo.start('q1')).thenAnswer((_) async => Ok(Fx.attempt(saved: {'qq1': 2}))),
      build: build,
      act: (b) => b.add(const PlayStarted('q1')),
      skip: 1,
      expect: () => [
        isA<QuizPlayState>().having((s) => s.answers, 'answers', {'qq1': 2}).having((s) => s.saved, 'saved', {'qq1'}),
      ],
    );

    blocTest<QuizPlayBloc, QuizPlayState>(
      'plus de tentative (409) : erreur de chargement',
      setUp: () =>
          when(() => repo.start('q1'))
              .thenAnswer((_) async => const Err(ConflictFailure('Tentatives épuisées.', code: 'NO_ATTEMPT_LEFT'))),
      build: build,
      act: (b) => b.add(const PlayStarted('q1')),
      expect: () => [
        const QuizPlayState(),
        const QuizPlayState(status: PlayStatus.loadFailure, message: 'Tentatives épuisées.'),
      ],
    );
  });

  group('PlayAnswerSelected — mise à jour optimiste (F8)', () {
    blocTest<QuizPlayBloc, QuizPlayState>(
      'succès : affichée tout de suite, puis confirmée',
      setUp: () => stubSave(const Ok(null)),
      build: build,
      seed: inProgress,
      act: (b) => b.add(const PlayAnswerSelected(1)),
      expect: () => [
        inProgress(answers: {'qq1': 1}),
        inProgress(answers: {'qq1': 1}, saved: {'qq1'}),
      ],
    );

    blocTest<QuizPlayBloc, QuizPlayState>(
      'échec : rollback vers la réponse précédente',
      setUp: () => stubSave(const Err(NetworkFailure('Hors ligne'))),
      build: build,
      seed: () => inProgress(answers: {'qq1': 0}, saved: {'qq1'}),
      act: (b) => b.add(const PlayAnswerSelected(3)),
      expect: () => [
        inProgress(answers: {'qq1': 3}),
        inProgress(answers: {'qq1': 0}, saved: {'qq1'}).copyWith(message: 'Réponse non enregistrée : Hors ligne'),
      ],
    );

    blocTest<QuizPlayBloc, QuizPlayState>(
      'échec sans réponse précédente : la question redevient vide',
      setUp: () => stubSave(const Err(NetworkFailure('Hors ligne'))),
      build: build,
      seed: inProgress,
      act: (b) => b.add(const PlayAnswerSelected(2)),
      expect: () => [
        inProgress(answers: {'qq1': 2}),
        inProgress().copyWith(message: 'Réponse non enregistrée : Hors ligne'),
      ],
    );
  });

  group('PlaySubmitted', () {
    blocTest<QuizPlayBloc, QuizPlayState>(
      'remise : envoie les réponses et expose l’identifiant du résultat',
      setUp: () =>
          when(() => repo.submit(attemptId: 'a1', answers: {'qq1': 0})).thenAnswer((_) async => const Ok(Fx.result)),
      build: build,
      seed: () => inProgress(answers: {'qq1': 0}, saved: {'qq1'}),
      act: (b) => b.add(const PlaySubmitted()),
      expect: () => [
        inProgress(answers: {'qq1': 0}, saved: {'qq1'}).copyWith(status: PlayStatus.submitting),
        inProgress(answers: {'qq1': 0}, saved: {'qq1'}).copyWith(status: PlayStatus.submitted, resultId: 'a1'),
      ],
    );

    blocTest<QuizPlayBloc, QuizPlayState>(
      'double appui : un seul envoi (transformer droppable)',
      setUp: () => when(
        () => repo.submit(
          attemptId: any(named: 'attemptId'),
          answers: any(named: 'answers'),
        ),
      ).thenAnswer((_) async => const Ok(Fx.result)),
      build: build,
      seed: inProgress,
      act: (b) => b
        ..add(const PlaySubmitted())
        ..add(const PlaySubmitted()),
      verify: (_) => verify(
        () => repo.submit(
          attemptId: any(named: 'attemptId'),
          answers: any(named: 'answers'),
        ),
      ).called(1),
    );

    blocTest<QuizPlayBloc, QuizPlayState>(
      'échec réseau : on reste dans le quiz avec un message',
      setUp: () => when(
        () => repo.submit(
          attemptId: any(named: 'attemptId'),
          answers: any(named: 'answers'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure('Hors ligne.'))),
      build: build,
      seed: inProgress,
      act: (b) => b.add(const PlaySubmitted()),
      expect: () => [
        inProgress().copyWith(status: PlayStatus.submitting),
        isA<QuizPlayState>()
            .having((s) => s.status, 'status', PlayStatus.inProgress)
            .having((s) => s.message, 'message', startsWith('Envoi impossible')),
      ],
    );
  });

  blocTest<QuizPlayBloc, QuizPlayState>(
    'minuteur à zéro : envoi automatique',
    setUp: () {
      when(() => repo.start('q1')).thenAnswer((_) async => Ok(Fx.attempt(left: const Duration(seconds: 1))));
      when(
        () => repo.submit(
          attemptId: any(named: 'attemptId'),
          answers: any(named: 'answers'),
        ),
      ).thenAnswer((_) async => const Ok(Fx.result));
    },
    build: build,
    act: (b) async {
      b.add(const PlayStarted('q1'));
      await Future<void>.delayed(Duration.zero);
      clock = clock.add(const Duration(seconds: 2)); // le temps passe…
      ticker.add(null);
      await Future<void>.delayed(Duration.zero);
    },
    verify: (b) {
      expect(b.state.status, PlayStatus.submitted);
      expect(b.state.autoSubmitted, isTrue);
    },
  );
}
