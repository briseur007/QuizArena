import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_form_state.dart';

class RegisterCubit extends Cubit<AuthFormState> {
  RegisterCubit(this._repository, {UserRole initialRole = UserRole.student}) : super(AuthFormState(role: initialRole));

  final AuthRepository _repository;

  void roleChanged(UserRole role) => emit(state.copyWith(role: role, status: FormStatus.idle));

  Future<void> submit({required String name, required String email, required String password}) async {
    if (state.status == FormStatus.submitting) return;

    final errors = {
      'name': ?AuthValidators.name(name),
      'email': ?AuthValidators.email(email),
      'password': ?AuthValidators.password(password, strict: true),
    };
    if (errors.isNotEmpty) {
      emit(state.copyWith(status: FormStatus.failure, fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: FormStatus.submitting, fieldErrors: const {}));
    final result = await _repository.register(
      name: name.trim(),
      email: email.trim(),
      password: password,
      role: state.role,
    );

    switch (result) {
      case Ok(value: final user):
        emit(state.copyWith(status: FormStatus.success, user: user));
      case Err(failure: ValidationFailure(:final fieldErrors, :final message)):
        emit(state.copyWith(status: FormStatus.failure, fieldErrors: fieldErrors, message: message));
      case Err(failure: ConflictFailure()):
        emit(
          state.copyWith(
            status: FormStatus.failure,
            fieldErrors: const {'email': 'Un compte existe déjà avec cette adresse.'},
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(status: FormStatus.failure, message: failure.message));
    }
  }
}
