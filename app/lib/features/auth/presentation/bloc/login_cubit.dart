import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_form_state.dart';

/// Formulaire de connexion (écran 01). Un Cubit suffit : pas de flux
/// d'événements concurrents à transformer, juste des méthodes appelées par l'UI.
class LoginCubit extends Cubit<AuthFormState> {
  LoginCubit(this._repository) : super(const AuthFormState());

  final AuthRepository _repository;

  void roleChanged(UserRole role) => emit(state.copyWith(role: role, status: FormStatus.idle));

  Future<void> submit({required String email, required String password}) async {
    if (state.status == FormStatus.submitting) return;

    final errors = {'email': ?AuthValidators.email(email), 'password': ?AuthValidators.password(password)};
    if (errors.isNotEmpty) {
      emit(state.copyWith(status: FormStatus.failure, fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: FormStatus.submitting, fieldErrors: const {}));
    final result = await _repository.login(email: email.trim(), password: password);

    switch (result) {
      case Ok(value: final user) when user.role != state.role:
        // Le rôle vient du serveur ; le sélecteur sert à éviter les confusions.
        await _repository.logout();
        emit(
          state.copyWith(
            status: FormStatus.failure,
            message:
                'Ce compte est un compte ${user.role.label.toLowerCase()}. '
                'Choisis « ${user.role.label} » ci-dessus.',
          ),
        );
      case Ok(value: final user):
        emit(state.copyWith(status: FormStatus.success, user: user));
      case Err(failure: ValidationFailure(:final fieldErrors, :final message)):
        emit(state.copyWith(status: FormStatus.failure, fieldErrors: fieldErrors, message: message));
      case Err(failure: UnauthorizedFailure()):
        emit(state.copyWith(status: FormStatus.failure, message: 'E-mail ou mot de passe incorrect.'));
      case Err(:final failure):
        emit(state.copyWith(status: FormStatus.failure, message: failure.message));
    }
  }
}
