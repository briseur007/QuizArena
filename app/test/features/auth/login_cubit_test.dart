import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiz_arena/core/error/failure.dart';
import 'package:quiz_arena/core/error/result.dart';
import 'package:quiz_arena/features/auth/domain/entities/user.dart';
import 'package:quiz_arena/features/auth/domain/repositories/auth_repository.dart';
import 'package:quiz_arena/features/auth/presentation/bloc/auth_form_state.dart';
import 'package:quiz_arena/features/auth/presentation/bloc/login_cubit.dart';
import 'package:quiz_arena/features/auth/presentation/bloc/register_cubit.dart';

import '../../helpers/fixtures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUpAll(() => registerFallbackValue(UserRole.student));
  setUp(() => repo = MockAuthRepository());

  void stubLogin(Result<User> result) => when(
    () => repo.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) async => result);

  group('LoginCubit', () {
    blocTest<LoginCubit, AuthFormState>(
      'champs invalides : erreurs locales, aucun appel réseau',
      build: () => LoginCubit(repo),
      act: (c) => c.submit(email: 'pas-un-email', password: ''),
      expect: () => [
        const AuthFormState(
          status: FormStatus.failure,
          fieldErrors: {'email': 'Adresse e-mail invalide.', 'password': 'Le mot de passe est obligatoire.'},
        ),
      ],
      verify: (_) => verifyNever(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ),
    );

    blocTest<LoginCubit, AuthFormState>(
      'succès : submitting puis success avec l’utilisateur',
      setUp: () => stubLogin(const Ok(Fx.student)),
      build: () => LoginCubit(repo),
      act: (c) => c.submit(email: ' amina@universite.bf ', password: 'secret123'),
      expect: () => [
        const AuthFormState(status: FormStatus.submitting),
        const AuthFormState(status: FormStatus.success, user: Fx.student),
      ],
      verify: (_) => verify(() => repo.login(email: 'amina@universite.bf', password: 'secret123')).called(1),
    );

    blocTest<LoginCubit, AuthFormState>(
      '401 : message « identifiants incorrects »',
      setUp: () => stubLogin(const Err(UnauthorizedFailure())),
      build: () => LoginCubit(repo),
      act: (c) => c.submit(email: 'amina@universite.bf', password: 'faux'),
      expect: () => [
        const AuthFormState(status: FormStatus.submitting),
        const AuthFormState(status: FormStatus.failure, message: 'E-mail ou mot de passe incorrect.'),
      ],
    );

    blocTest<LoginCubit, AuthFormState>(
      '422 : erreurs du serveur affichées sous les champs (F10)',
      setUp: () => stubLogin(const Err(ValidationFailure('Données invalides', fieldErrors: {'email': 'Trop long'}))),
      build: () => LoginCubit(repo),
      act: (c) => c.submit(email: 'amina@universite.bf', password: 'x'),
      expect: () => [
        const AuthFormState(status: FormStatus.submitting),
        const AuthFormState(
          status: FormStatus.failure,
          fieldErrors: {'email': 'Trop long'},
          message: 'Données invalides',
        ),
      ],
    );

    blocTest<LoginCubit, AuthFormState>(
      'rôle choisi différent du compte : déconnexion et message',
      setUp: () {
        stubLogin(const Ok(Fx.teacher));
        when(() => repo.logout()).thenAnswer((_) async {});
      },
      build: () => LoginCubit(repo),
      act: (c) => c.submit(email: 'nikiema@universite.bf', password: 'secret123'),
      expect: () => [
        const AuthFormState(status: FormStatus.submitting),
        isA<AuthFormState>()
            .having((s) => s.status, 'status', FormStatus.failure)
            .having((s) => s.message, 'message', contains('enseignant')),
      ],
      verify: (_) => verify(() => repo.logout()).called(1),
    );
  });

  group('RegisterCubit', () {
    blocTest<RegisterCubit, AuthFormState>(
      'mot de passe trop court : refusé localement',
      build: () => RegisterCubit(repo),
      act: (c) => c.submit(name: 'Amina', email: 'amina@universite.bf', password: '1234'),
      expect: () => [
        const AuthFormState(status: FormStatus.failure, fieldErrors: {'password': 'Au moins 8 caractères.'}),
      ],
    );

    blocTest<RegisterCubit, AuthFormState>(
      '409 : e-mail déjà utilisé affiché sous le champ',
      setUp: () => when(
        () => repo.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async => const Err(ConflictFailure('Existe déjà'))),
      build: () => RegisterCubit(repo, initialRole: UserRole.teacher),
      act: (c) => c.submit(name: 'Dr Nikiema', email: 'nikiema@universite.bf', password: 'secret123'),
      expect: () => [
        const AuthFormState(role: UserRole.teacher, status: FormStatus.submitting),
        const AuthFormState(
          role: UserRole.teacher,
          status: FormStatus.failure,
          fieldErrors: {'email': 'Un compte existe déjà avec cette adresse.'},
        ),
      ],
    );
  });
}
