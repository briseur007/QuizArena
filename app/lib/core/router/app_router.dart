import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/attempts/presentation/pages/leaderboard_page.dart';
import '../../features/attempts/presentation/pages/quiz_play_page.dart';
import '../../features/attempts/presentation/pages/result_page.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/edit_profile_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/courses/presentation/pages/home_page.dart';
import '../../features/courses/presentation/pages/student_course_page.dart';
import '../../features/quizzes/presentation/pages/quiz_editor_page.dart';
import '../../features/quizzes/presentation/pages/quiz_report_page.dart';
import '../../features/quizzes/presentation/pages/teacher_results_page.dart';
import '../widgets/state_views.dart';
import 'main_shell.dart';
import 'routes.dart';

/// F5 : navigation déclarative ; la garde [_redirect] dépend de l'état
/// d'authentification et est réévaluée à chaque changement de [AuthBloc].
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _StreamListenable(authBloc.stream),
    redirect: (context, state) => _redirect(authBloc.state, state.matchedLocation),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const Scaffold(body: LoadingView()),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: Routes.register,
        builder: (_, state) => RegisterPage(initialRole: state.extra as UserRole? ?? UserRole.student),
      ),

      // Plein écran, sans barre de navigation (écrans 03 et 07).
      GoRoute(
        path: '/play/:quizId',
        builder: (_, state) => QuizPlayPage(quizId: state.pathParameters['quizId']!),
      ),
      GoRoute(
        path: '/editor/:quizId',
        builder: (_, state) {
          final quizId = state.pathParameters['quizId']!;
          return QuizEditorPage(
            quizId: quizId == 'new' ? null : quizId,
            courseId: state.uri.queryParameters['courseId'] ?? '',
            courseName: state.uri.queryParameters['courseName'] ?? '',
          );
        },
      ),

      // Onglets : chaque branche garde sa propre pile de navigation.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, _) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'course/:courseId',
                    builder: (_, state) => StudentCoursePage(courseId: state.pathParameters['courseId']!),
                  ),
                  GoRoute(
                    path: 'result/:attemptId',
                    builder: (_, state) => ResultPage(attemptId: state.pathParameters['attemptId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.ranking,
                builder: (context, state) => authBloc.state.user?.isTeacher ?? false
                    ? const TeacherResultsPage()
                    : LeaderboardPage(
                        // La clé force un rechargement quand on arrive depuis Résultats.
                        key: ValueKey(state.uri.query),
                        quizId: state.uri.queryParameters['quizId'],
                        courseId: state.uri.queryParameters['courseId'],
                      ),
                routes: [
                  GoRoute(
                    path: 'report/:quizId',
                    builder: (_, state) => QuizReportPage(quizId: state.pathParameters['quizId']!),
                    routes: [
                      GoRoute(
                        path: 'attempt/:attemptId',
                        builder: (_, state) =>
                            ResultPage(attemptId: state.pathParameters['attemptId']!, teacherView: true),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfilePage(),
                routes: [GoRoute(path: 'edit', builder: (_, _) => const EditProfilePage())],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _redirect(AuthState auth, String location) {
  final onAuthPage = location == Routes.login || location == Routes.register;

  switch (auth.status) {
    case AuthStatus.unknown:
      return location == Routes.splash ? null : Routes.splash;
    case AuthStatus.unauthenticated:
      return onAuthPage ? null : Routes.login;
    case AuthStatus.authenticated:
      if (onAuthPage || location == Routes.splash) return Routes.home;
      // Contrôle de confort : le serveur vérifie de toute façon les rôles (A7).
      final isTeacher = auth.user!.isTeacher;
      if (Routes.isTeacherOnly(location) && !isTeacher) return Routes.home;
      if (Routes.isStudentOnly(location) && isTeacher) return Routes.home;
      return null;
  }
}

/// Adapte un Stream (états du bloc) en Listenable pour `refreshListenable`.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
