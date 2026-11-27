import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiz_arena/core/error/failure.dart';
import 'package:quiz_arena/core/error/result.dart';
import 'package:quiz_arena/features/attempts/domain/entities/leaderboard.dart';
import 'package:quiz_arena/features/attempts/domain/repositories/attempt_repository.dart';
import 'package:quiz_arena/features/attempts/presentation/bloc/leaderboard_cubit.dart';
import 'package:quiz_arena/features/attempts/presentation/bloc/result_cubit.dart';

import '../../helpers/fixtures.dart';

class MockAttemptRepository extends Mock implements AttemptRepository {}

void main() {
  late MockAttemptRepository repo;

  setUpAll(() => registerFallbackValue(LeaderboardScope.quiz));
  setUp(() => repo = MockAttemptRepository());

  group('LeaderboardCubit', () {
    blocTest<LeaderboardCubit, LeaderboardState>(
      'depuis les résultats : classement du quiz',
      setUp: () =>
          when(() => repo.leaderboard(LeaderboardScope.quiz, 'q1')).thenAnswer((_) async => const Ok(Fx.leaderboard)),
      build: () => LeaderboardCubit(repo),
      act: (c) => c.load(quizId: 'q1', courseId: 'c1'),
      skip: 2,
      expect: () => [
        const LeaderboardState(
          status: LeaderboardStatus.success,
          quizId: 'q1',
          courseId: 'c1',
          leaderboard: Fx.leaderboard,
        ),
      ],
    );

    blocTest<LeaderboardCubit, LeaderboardState>(
      'onglet sans quiz et aucun résultat : état vide',
      setUp: () => when(() => repo.latestResult()).thenAnswer((_) async => const Ok(null)),
      build: () => LeaderboardCubit(repo),
      act: (c) => c.load(),
      expect: () => [const LeaderboardState(), const LeaderboardState(status: LeaderboardStatus.empty)],
    );

    blocTest<LeaderboardCubit, LeaderboardState>(
      'onglet sans quiz : prend le dernier quiz remis',
      setUp: () {
        when(() => repo.latestResult()).thenAnswer((_) async => const Ok(Fx.result));
        when(() => repo.leaderboard(any(), any())).thenAnswer((_) async => const Ok(Fx.leaderboard));
      },
      build: () => LeaderboardCubit(repo),
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, LeaderboardStatus.success);
        verify(() => repo.leaderboard(LeaderboardScope.quiz, 'q1')).called(1);
      },
    );

    blocTest<LeaderboardCubit, LeaderboardState>(
      'bascule « Mon cours » : recharge avec l’identifiant du cours',
      setUp: () =>
          when(() => repo.leaderboard(LeaderboardScope.course, 'c1')).thenAnswer((_) async => const Ok(Fx.leaderboard)),
      build: () => LeaderboardCubit(repo),
      seed: () => const LeaderboardState(status: LeaderboardStatus.success, quizId: 'q1', courseId: 'c1'),
      act: (c) => c.scopeChanged(LeaderboardScope.course),
      verify: (c) {
        expect(c.state.scope, LeaderboardScope.course);
        expect(c.state.status, LeaderboardStatus.success);
      },
    );

    blocTest<LeaderboardCubit, LeaderboardState>(
      'erreur réseau : état d’erreur',
      setUp: () =>
          when(() => repo.leaderboard(any(), any())).thenAnswer((_) async => const Err(NetworkFailure('Hors ligne'))),
      build: () => LeaderboardCubit(repo),
      act: (c) => c.load(quizId: 'q1', courseId: 'c1'),
      verify: (c) => expect(c.state.status, LeaderboardStatus.failure),
    );
  });

  group('ResultCubit', () {
    blocTest<ResultCubit, ResultState>(
      'charge le résultat corrigé',
      setUp: () => when(() => repo.result('a1')).thenAnswer((_) async => const Ok(Fx.result)),
      build: () => ResultCubit(repo),
      act: (c) => c.load('a1'),
      expect: () => [const ResultState(), const ResultState(status: ResultStatus.success, result: Fx.result)],
    );

    blocTest<ResultCubit, ResultState>(
      'résultat d’un autre étudiant (403) : erreur',
      setUp: () => when(() => repo.result('a1')).thenAnswer((_) async => const Err(ForbiddenFailure())),
      build: () => ResultCubit(repo),
      act: (c) => c.load('a1'),
      expect: () => [
        const ResultState(),
        ResultState(status: ResultStatus.failure, message: const ForbiddenFailure().message),
      ],
    );

    test('appréciation selon le taux de réussite', () {
      expect(ResultCubit.appreciation(0.8, 'Amina').title, 'Bien joué, Amina !');
      expect(ResultCubit.appreciation(0.6, 'Amina').title, 'Pas mal, Amina !');
      expect(ResultCubit.appreciation(0.2, 'Amina').title, 'Courage, Amina !');
    });
  });
}
