import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiz_arena/core/error/failure.dart';
import 'package:quiz_arena/core/error/result.dart';
import 'package:quiz_arena/features/auth/domain/repositories/auth_repository.dart';
import 'package:quiz_arena/features/auth/presentation/bloc/auth_bloc.dart';

import '../../helpers/fixtures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late StreamController<void> expired;

  setUp(() {
    repo = MockAuthRepository();
    expired = StreamController<void>.broadcast();
    when(() => repo.sessionExpired).thenAnswer((_) => expired.stream);
  });

  tearDown(() => expired.close());

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'session valide → authenticated',
      setUp: () => when(() => repo.currentUser()).thenAnswer((_) async => const Ok(Fx.student)),
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthState.authenticated(Fx.student)],
    );

    blocTest<AuthBloc, AuthState>(
      'pas de session → unauthenticated',
      setUp: () => when(() => repo.currentUser()).thenAnswer((_) async => const Err(UnauthorizedFailure())),
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthState.unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'hors ligne sans profil en cache → unauthenticated(offline)',
      setUp: () => when(() => repo.currentUser()).thenAnswer((_) async => const Err(NetworkFailure())),
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthState.unauthenticated(offline: true)],
    );
  });

  blocTest<AuthBloc, AuthState>(
    'déconnexion : révoque la session puis unauthenticated',
    setUp: () => when(() => repo.logout()).thenAnswer((_) async {}),
    build: () => AuthBloc(repo),
    seed: () => const AuthState.authenticated(Fx.student),
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => [const AuthState.unauthenticated()],
    verify: (_) => verify(() => repo.logout()).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'refresh refusé par le serveur → session expirée',
    build: () => AuthBloc(repo),
    seed: () => const AuthState.authenticated(Fx.student),
    act: (_) => expired.add(null),
    expect: () => [const AuthState.unauthenticated(sessionExpired: true)],
  );
}
