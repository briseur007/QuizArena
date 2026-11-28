import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_form_state.dart';

final class EditProfileState extends Equatable {
  const EditProfileState({
    this.profileStatus = FormStatus.idle,
    this.passwordStatus = FormStatus.idle,
    this.fieldErrors = const {},
    this.message,
    this.user,
  });

  /// Formulaire « Mes informations ».
  final FormStatus profileStatus;

  /// Formulaire « Mot de passe ».
  final FormStatus passwordStatus;

  /// Erreurs par champ : name, email, currentPassword, newPassword, confirmPassword.
  final Map<String, String> fieldErrors;

  /// Message ponctuel (SnackBar).
  final String? message;

  /// Profil enregistré, à transmettre à l'AuthBloc.
  final User? user;

  EditProfileState copyWith({
    FormStatus? profileStatus,
    FormStatus? passwordStatus,
    Map<String, String>? fieldErrors,
    String? message,
    User? user,
  }) => EditProfileState(
    profileStatus: profileStatus ?? this.profileStatus,
    passwordStatus: passwordStatus ?? this.passwordStatus,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    message: message,
    user: user ?? this.user,
  );

  @override
  List<Object?> get props => [profileStatus, passwordStatus, fieldErrors, message, user];
}

/// Profil (onglet Profil → « Modifier mes informations »).
class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit(this._repository) : super(const EditProfileState());

  final AuthRepository _repository;

  Future<void> saveProfile({required User current, required String name, required String email}) async {
    if (state.profileStatus == FormStatus.submitting) return;

    final errors = {'name': ?AuthValidators.name(name), 'email': ?AuthValidators.email(email)};
    if (errors.isNotEmpty) {
      emit(state.copyWith(profileStatus: FormStatus.failure, fieldErrors: errors));
      return;
    }

    // On n'envoie que ce qui a changé.
    final newName = name.trim() == current.name ? null : name.trim();
    final newEmail = email.trim().toLowerCase() == current.email ? null : email.trim();
    if (newName == null && newEmail == null) {
      emit(state.copyWith(profileStatus: FormStatus.idle, fieldErrors: const {}, message: 'Aucune modification.'));
      return;
    }

    emit(state.copyWith(profileStatus: FormStatus.submitting, fieldErrors: const {}));
    final result = await _repository.updateProfile(name: newName, email: newEmail);
    switch (result) {
      case Ok(value: final user):
        emit(state.copyWith(profileStatus: FormStatus.success, user: user, message: 'Informations enregistrées.'));
      case Err(failure: ValidationFailure(:final fieldErrors, :final message)):
        emit(state.copyWith(profileStatus: FormStatus.failure, fieldErrors: fieldErrors, message: message));
      case Err(failure: ConflictFailure()):
        emit(
          state.copyWith(
            profileStatus: FormStatus.failure,
            fieldErrors: const {'email': 'Un compte existe déjà avec cette adresse.'},
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(profileStatus: FormStatus.failure, message: failure.message));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.passwordStatus == FormStatus.submitting) return;

    final newPasswordError =
        AuthValidators.password(newPassword, strict: true) ??
        (newPassword == currentPassword ? 'Choisis un mot de passe différent de l’actuel.' : null);
    final errors = {
      if (currentPassword.isEmpty) 'currentPassword': 'Saisis ton mot de passe actuel.',
      'newPassword': ?newPasswordError,
      'confirmPassword': ?AuthValidators.confirmation(newPassword, confirmPassword),
    };
    if (errors.isNotEmpty) {
      emit(state.copyWith(passwordStatus: FormStatus.failure, fieldErrors: errors));
      return;
    }

    emit(state.copyWith(passwordStatus: FormStatus.submitting, fieldErrors: const {}));
    final result = await _repository.changePassword(currentPassword: currentPassword, newPassword: newPassword);
    switch (result) {
      case Ok():
        emit(
          state.copyWith(
            passwordStatus: FormStatus.success,
            message: 'Mot de passe modifié. Tes autres appareils ont été déconnectés.',
          ),
        );
      case Err(failure: ValidationFailure(:final fieldErrors, :final message)):
        emit(state.copyWith(passwordStatus: FormStatus.failure, fieldErrors: fieldErrors, message: message));
      case Err(:final failure):
        emit(state.copyWith(passwordStatus: FormStatus.failure, message: failure.message));
    }
  }
}
