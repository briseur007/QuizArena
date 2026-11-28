import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiz_arena/core/error/failure.dart';
import 'package:quiz_arena/core/error/result.dart';
import 'package:quiz_arena/features/auth/domain/entities/user.dart';
import 'package:quiz_arena/features/auth/domain/repositories/auth_repository.dart';
import 'package:quiz_arena/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:quiz_arena/features/auth/presentation/bloc/auth_form_state.dart';
import 'package:quiz_arena/features/auth/presentation/bloc/edit_profile_cubit.dart';

import '../../helpers/fixtures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() => repo = MockAuthRepository());

  const renamed = User(id: 'u2', name: 'Pr Nikiema', email: 'nikiema@universite.bf', role: UserRole.teacher);

  group('saveProfile', () {
    blocTest<EditProfileCubit, EditProfileState>(
      'n’envoie que les champs modifiés, puis succès',
      setUp: () => when(
        () => repo.updateProfile(
          name: any(named: 'name'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => const Ok(renamed)),
      build: () => EditProfileCubit(repo),
      act: (c) => c.saveProfile(current: Fx.teacher, name: 'Pr Nikiema', email: Fx.teacher.email),
      expect: () => [
        const EditProfileState(profileStatus: FormStatus.submitting),
        const EditProfileState(profileStatus: FormStatus.success, user: renamed, message: 'Informations enregistrées.'),
      ],
      verify: (_) => verify(() => repo.updateProfile(name: 'Pr Nikiema')).called(1),
    );

    blocTest<EditProfileCubit, EditProfileState>(
      'aucune modification : pas d’appel réseau',
      build: () => EditProfileCubit(repo),
      act: (c) => c.saveProfile(current: Fx.teacher, name: Fx.teacher.name, email: Fx.teacher.email),
      expect: () => [const EditProfileState(message: 'Aucune modification.')],
      verify: (_) => verifyNever(
        () => repo.updateProfile(
          name: any(named: 'name'),
          email: any(named: 'email'),
        ),
      ),
    );

    blocTest<EditProfileCubit, EditProfileState>(
      'champs invalides : erreurs locales',
      build: () => EditProfileCubit(repo),
      act: (c) => c.saveProfile(current: Fx.teacher, name: 'A', email: 'pas-un-email'),
      expect: () => [
        const EditProfileState(
          profileStatus: FormStatus.failure,
          fieldErrors: {'name': 'Indique ton nom complet.', 'email': 'Adresse e-mail invalide.'},
        ),
      ],
    );

    blocTest<EditProfileCubit, EditProfileState>(
      'e-mail déjà pris (409) : erreur sous le champ',
      setUp: () => when(
        () => repo.updateProfile(
          name: any(named: 'name'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => const Err(ConflictFailure('Existe déjà', code: 'EMAIL_TAKEN'))),
      build: () => EditProfileCubit(repo),
      act: (c) => c.saveProfile(current: Fx.teacher, name: Fx.teacher.name, email: 'amina@universite.bf'),
      expect: () => [
        const EditProfileState(profileStatus: FormStatus.submitting),
        const EditProfileState(
          profileStatus: FormStatus.failure,
          fieldErrors: {'email': 'Un compte existe déjà avec cette adresse.'},
        ),
      ],
    );
  });

  group('changePassword', () {
    void stub(Result<void> result) => when(
      () => repo.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => result);

    blocTest<EditProfileCubit, EditProfileState>(
      'confirmation différente et mot de passe trop court : refusé localement',
      build: () => EditProfileCubit(repo),
      act: (c) => c.changePassword(currentPassword: '', newPassword: '123', confirmPassword: '1234'),
      expect: () => [
        const EditProfileState(
          passwordStatus: FormStatus.failure,
          fieldErrors: {
            'currentPassword': 'Saisis ton mot de passe actuel.',
            'newPassword': 'Au moins 8 caractères.',
            'confirmPassword': 'Les deux mots de passe ne correspondent pas.',
          },
        ),
      ],
    );

    blocTest<EditProfileCubit, EditProfileState>(
      'succès',
      setUp: () => stub(const Ok(null)),
      build: () => EditProfileCubit(repo),
      act: (c) =>
          c.changePassword(currentPassword: 'ancien123', newPassword: 'nouveau123', confirmPassword: 'nouveau123'),
      expect: () => [
        const EditProfileState(passwordStatus: FormStatus.submitting),
        isA<EditProfileState>()
            .having((s) => s.passwordStatus, 'status', FormStatus.success)
            .having((s) => s.message, 'message', startsWith('Mot de passe modifié')),
      ],
    );

    blocTest<EditProfileCubit, EditProfileState>(
      'mot de passe actuel incorrect (422) : erreur sous le champ',
      setUp: () => stub(
        const Err(
          ValidationFailure(
            'Mot de passe actuel incorrect',
            fieldErrors: {'currentPassword': 'Mot de passe actuel incorrect'},
          ),
        ),
      ),
      build: () => EditProfileCubit(repo),
      act: (c) => c.changePassword(currentPassword: 'faux', newPassword: 'nouveau123', confirmPassword: 'nouveau123'),
      expect: () => [
        const EditProfileState(passwordStatus: FormStatus.submitting),
        const EditProfileState(
          passwordStatus: FormStatus.failure,
          fieldErrors: {'currentPassword': 'Mot de passe actuel incorrect'},
          message: 'Mot de passe actuel incorrect',
        ),
      ],
    );
  });

  group('AuthBloc', () {
    late StreamController<void> expired;
    setUp(() {
      expired = StreamController<void>.broadcast();
      when(() => repo.sessionExpired).thenAnswer((_) => expired.stream);
    });
    tearDown(() => expired.close());

    blocTest<AuthBloc, AuthState>(
      'AuthUserUpdated met à jour l’utilisateur de la session',
      build: () => AuthBloc(repo),
      seed: () => const AuthState.authenticated(Fx.teacher),
      act: (b) => b.add(const AuthUserUpdated(renamed)),
      expect: () => [const AuthState.authenticated(renamed)],
    );

    blocTest<AuthBloc, AuthState>(
      'ignoré si personne n’est connecté',
      build: () => AuthBloc(repo),
      seed: () => const AuthState.unauthenticated(),
      act: (b) => b.add(const AuthUserUpdated(renamed)),
      expect: () => <AuthState>[],
    );
  });
}
