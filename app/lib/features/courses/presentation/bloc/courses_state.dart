part of 'courses_bloc.dart';

enum CoursesStatus { initial, loading, success, failure }

/// État d'une action ponctuelle (rejoindre, créer) affichée par SnackBar.
enum ActionStatus { idle, inProgress, success, failure }

final class CoursesState extends Equatable {
  const CoursesState({
    this.status = CoursesStatus.initial,
    this.courses = const [],
    this.fromCache = false,
    this.action = ActionStatus.idle,
    this.message,
  });

  final CoursesStatus status;
  final List<Course> courses;

  /// Les cours affichés viennent du cache (pas encore confirmés par le serveur).
  final bool fromCache;
  final ActionStatus action;
  final String? message;

  bool get isEmpty => status == CoursesStatus.success && courses.isEmpty;

  CoursesState copyWith({
    CoursesStatus? status,
    List<Course>? courses,
    bool? fromCache,
    ActionStatus? action,
    String? message,
  }) => CoursesState(
    status: status ?? this.status,
    courses: courses ?? this.courses,
    fromCache: fromCache ?? this.fromCache,
    action: action ?? this.action,
    message: message,
  );

  @override
  List<Object?> get props => [status, courses, fromCache, action, message];
}
