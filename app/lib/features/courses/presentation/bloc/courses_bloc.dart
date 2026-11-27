import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/course_repository.dart';

part 'courses_event.dart';
part 'courses_state.dart';

/// Liste des cours de l'utilisateur (écrans 02 et 06).
///
/// Bloc (et non Cubit) pour choisir un transformer par événement :
/// - chargement / rafraîchissement : `droppable` (on ignore un 2e « tirer pour
///   rafraîchir » tant que le premier n'est pas terminé) ;
/// - rejoindre / créer : `droppable` aussi, contre le double appui.
class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  CoursesBloc(this._repository) : super(const CoursesState()) {
    on<CoursesRequested>(_onRequested, transformer: droppable());
    on<CourseJoinRequested>(_onJoin, transformer: droppable());
    on<CourseCreateRequested>(_onCreate, transformer: droppable());
    on<CourseActionAcknowledged>((e, emit) => emit(state.copyWith(action: ActionStatus.idle)));
  }

  final CourseRepository _repository;

  static final _codePattern = RegExp(r'^[A-Z0-9]{4,10}$');

  /// F9 — cache puis réseau : on affiche tout de suite la dernière liste
  /// connue, puis on la remplace par celle du serveur.
  Future<void> _onRequested(CoursesRequested event, Emitter<CoursesState> emit) async {
    if (!event.refresh) {
      emit(state.copyWith(status: CoursesStatus.loading));
      final cached = await _repository.cachedCourses();
      if (cached != null) {
        emit(state.copyWith(status: CoursesStatus.success, courses: cached, fromCache: true));
      }
    }

    final result = await _repository.fetchCourses();
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(status: CoursesStatus.success, courses: value, fromCache: false));
      case Err(:final failure) when state.courses.isNotEmpty || state.status == CoursesStatus.success:
        // On garde les données affichées et on signale juste le problème.
        emit(state.copyWith(status: CoursesStatus.success, fromCache: true, message: failure.message));
      case Err(:final failure):
        emit(state.copyWith(status: CoursesStatus.failure, message: failure.message));
    }
  }

  Future<void> _onJoin(CourseJoinRequested event, Emitter<CoursesState> emit) async {
    final code = event.code.trim().toUpperCase();
    if (!_codePattern.hasMatch(code)) {
      emit(state.copyWith(action: ActionStatus.failure, message: 'Code invalide : 4 à 10 lettres ou chiffres.'));
      return;
    }

    emit(state.copyWith(action: ActionStatus.inProgress));
    final result = await _repository.joinCourse(code);
    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(
            status: CoursesStatus.success,
            courses: [value, ...state.courses.where((c) => c.id != value.id)],
            action: ActionStatus.success,
            message: 'Tu as rejoint « ${value.name} ».',
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(action: ActionStatus.failure, message: failure.message));
    }
  }

  Future<void> _onCreate(CourseCreateRequested event, Emitter<CoursesState> emit) async {
    if (event.name.trim().length < 3) {
      emit(state.copyWith(action: ActionStatus.failure, message: 'Le nom du cours est trop court.'));
      return;
    }

    emit(state.copyWith(action: ActionStatus.inProgress));
    final result = await _repository.createCourse(name: event.name.trim(), level: event.level.trim());
    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(
            status: CoursesStatus.success,
            courses: [value, ...state.courses],
            action: ActionStatus.success,
            message: 'Cours créé. Code d’invitation : ${value.code ?? '—'}',
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(action: ActionStatus.failure, message: failure.message));
    }
  }
}
