part of 'courses_bloc.dart';

sealed class CoursesEvent extends Equatable {
  const CoursesEvent();

  @override
  List<Object?> get props => [];
}

/// Premier chargement (cache puis réseau) ou rafraîchissement ([refresh]).
final class CoursesRequested extends CoursesEvent {
  const CoursesRequested({this.refresh = false});
  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class CourseJoinRequested extends CoursesEvent {
  const CourseJoinRequested(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

final class CourseCreateRequested extends CoursesEvent {
  const CourseCreateRequested({required this.name, required this.level});
  final String name;
  final String level;

  @override
  List<Object?> get props => [name, level];
}

/// L'UI a affiché le message de l'action (SnackBar) : on revient à « idle ».
final class CourseActionAcknowledged extends CoursesEvent {
  const CourseActionAcknowledged();
}
