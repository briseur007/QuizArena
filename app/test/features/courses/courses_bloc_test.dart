import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiz_arena/core/error/failure.dart';
import 'package:quiz_arena/core/error/result.dart';
import 'package:quiz_arena/features/courses/domain/repositories/course_repository.dart';
import 'package:quiz_arena/features/courses/presentation/bloc/courses_bloc.dart';

import '../../helpers/fixtures.dart';

class MockCourseRepository extends Mock implements CourseRepository {}

void main() {
  late MockCourseRepository repo;

  setUp(() => repo = MockCourseRepository());

  group('CoursesRequested — cache puis réseau (F9)', () {
    blocTest<CoursesBloc, CoursesState>(
      'affiche le cache, puis la liste du serveur',
      setUp: () {
        when(() => repo.cachedCourses()).thenAnswer((_) async => [Fx.mobile]);
        when(() => repo.fetchCourses()).thenAnswer((_) async => const Ok([Fx.mobile, Fx.databases]));
      },
      build: () => CoursesBloc(repo),
      act: (b) => b.add(const CoursesRequested()),
      expect: () => [
        const CoursesState(status: CoursesStatus.loading),
        const CoursesState(status: CoursesStatus.success, courses: [Fx.mobile], fromCache: true),
        const CoursesState(status: CoursesStatus.success, courses: [Fx.mobile, Fx.databases]),
      ],
    );

    blocTest<CoursesBloc, CoursesState>(
      'hors ligne avec cache : garde les données et signale le problème',
      setUp: () {
        when(() => repo.cachedCourses()).thenAnswer((_) async => [Fx.mobile]);
        when(() => repo.fetchCourses()).thenAnswer((_) async => const Err(NetworkFailure('Hors ligne')));
      },
      build: () => CoursesBloc(repo),
      act: (b) => b.add(const CoursesRequested()),
      expect: () => [
        const CoursesState(status: CoursesStatus.loading),
        const CoursesState(status: CoursesStatus.success, courses: [Fx.mobile], fromCache: true),
        const CoursesState(status: CoursesStatus.success, courses: [Fx.mobile], fromCache: true, message: 'Hors ligne'),
      ],
    );

    blocTest<CoursesBloc, CoursesState>(
      'hors ligne sans cache : état d’erreur (avec réessai dans l’UI)',
      setUp: () {
        when(() => repo.cachedCourses()).thenAnswer((_) async => null);
        when(() => repo.fetchCourses()).thenAnswer((_) async => const Err(NetworkFailure('Hors ligne')));
      },
      build: () => CoursesBloc(repo),
      act: (b) => b.add(const CoursesRequested()),
      expect: () => [
        const CoursesState(status: CoursesStatus.loading),
        const CoursesState(status: CoursesStatus.failure, message: 'Hors ligne'),
      ],
    );
  });

  group('CourseJoinRequested', () {
    blocTest<CoursesBloc, CoursesState>(
      'code mal formé : refusé sans appel réseau',
      build: () => CoursesBloc(repo),
      act: (b) => b.add(const CourseJoinRequested('ab')),
      expect: () => [
        const CoursesState(action: ActionStatus.failure, message: 'Code invalide : 4 à 10 lettres ou chiffres.'),
      ],
      verify: (_) => verifyNever(() => repo.joinCourse(any())),
    );

    blocTest<CoursesBloc, CoursesState>(
      'code valide (mis en majuscules) : le cours est ajouté en tête',
      setUp: () => when(() => repo.joinCourse('MOBL3A')).thenAnswer((_) async => const Ok(Fx.mobile)),
      build: () => CoursesBloc(repo),
      seed: () => const CoursesState(status: CoursesStatus.success, courses: [Fx.databases]),
      act: (b) => b.add(const CourseJoinRequested(' mobl3a ')),
      expect: () => [
        const CoursesState(status: CoursesStatus.success, courses: [Fx.databases], action: ActionStatus.inProgress),
        const CoursesState(
          status: CoursesStatus.success,
          courses: [Fx.mobile, Fx.databases],
          action: ActionStatus.success,
          message: 'Tu as rejoint « Développement mobile ».',
        ),
      ],
    );

    blocTest<CoursesBloc, CoursesState>(
      'code inconnu (404) : message d’erreur, liste inchangée',
      setUp: () =>
          when(() => repo.joinCourse(any())).thenAnswer((_) async => const Err(NotFoundFailure('Code inconnu'))),
      build: () => CoursesBloc(repo),
      act: (b) => b.add(const CourseJoinRequested('ZZZZ99')),
      expect: () => [
        const CoursesState(action: ActionStatus.inProgress),
        const CoursesState(action: ActionStatus.failure, message: 'Code inconnu'),
      ],
    );
  });
}
