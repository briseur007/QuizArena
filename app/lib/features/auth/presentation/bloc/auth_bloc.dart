import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// État de session de toute l'application. Le routeur l'écoute (F5).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoggedIn>((event, emit) => emit(AuthState.authenticated(event.user)));
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>((event, emit) => emit(const AuthState.unauthenticated(sessionExpired: true)));

    _expiredSub = _repository.sessionExpired.listen((_) => add(const AuthSessionExpired()));
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _expiredSub;

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final result = await _repository.currentUser();
    switch (result) {
      case Ok(:final value):
        emit(AuthState.authenticated(value));
      case Err(failure: NetworkFailure()):
        // Hors ligne au démarrage : on ne peut pas vérifier la session.
        emit(const AuthState.unauthenticated(offline: true));
      case Err():
        emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthState.unauthenticated());
  }

  @override
  Future<void> close() {
    _expiredSub.cancel();
    return super.close();
  }
}
