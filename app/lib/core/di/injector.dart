import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/attempts/data/datasources/attempt_remote_data_source.dart';
import '../../features/attempts/data/repositories/attempt_repository_impl.dart';
import '../../features/attempts/domain/repositories/attempt_repository.dart';
import '../../features/attempts/presentation/bloc/latest_result_cubit.dart';
import '../../features/attempts/presentation/bloc/leaderboard_cubit.dart';
import '../../features/attempts/presentation/bloc/quiz_play_bloc.dart';
import '../../features/attempts/presentation/bloc/result_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/login_cubit.dart';
import '../../features/courses/data/datasources/course_local_data_source.dart';
import '../../features/courses/data/datasources/course_remote_data_source.dart';
import '../../features/courses/data/repositories/course_repository_impl.dart';
import '../../features/courses/domain/repositories/course_repository.dart';
import '../../features/courses/presentation/bloc/courses_bloc.dart';
import '../../features/quizzes/data/datasources/quiz_remote_data_source.dart';
import '../../features/quizzes/data/repositories/quiz_repository_impl.dart';
import '../../features/quizzes/domain/repositories/quiz_repository.dart';
import '../../features/quizzes/presentation/bloc/quiz_editor_bloc.dart';
import '../../features/quizzes/presentation/bloc/quiz_list_cubit.dart';
import '../../features/quizzes/presentation/bloc/quiz_report_cubit.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../storage/json_cache.dart';
import '../storage/token_storage.dart';

final getIt = GetIt.instance;

/// F4 : point de composition unique. C'est le seul endroit qui connaît
/// les implémentations concrètes ; le reste de l'app dépend des contrats.
void configureDependencies() {
  // --- Stockage & réseau -------------------------------------------------
  getIt
    ..registerLazySingleton(() => TokenStorage(const FlutterSecureStorage()))
    ..registerLazySingleton(() => JsonCache(SharedPreferencesAsync()))
    ..registerLazySingleton<AuthInterceptor>(() {
      final dio = getIt<Dio>();
      return AuthInterceptor(storage: getIt(), refreshClient: ApiClient.create(), retryClient: dio);
    })
    ..registerLazySingleton<Dio>(() => ApiClient.create());

  // L'intercepteur a besoin du Dio principal (pour rejouer) et inversement :
  // on l'attache après la création des deux.
  getIt<Dio>().interceptors.add(getIt<AuthInterceptor>());

  // --- Sources de données -------------------------------------------------
  getIt
    ..registerLazySingleton(() => AuthRemoteDataSource(getIt()))
    ..registerLazySingleton(() => CourseRemoteDataSource(getIt()))
    ..registerLazySingleton(() => CourseLocalDataSource(getIt()))
    ..registerLazySingleton(() => QuizRemoteDataSource(getIt()))
    ..registerLazySingleton(() => AttemptRemoteDataSource(getIt()));

  // --- Repositories (contrat → implémentation) ----------------------------
  getIt
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: getIt(),
        storage: getIt(),
        cache: getIt(),
        sessionExpired: getIt<AuthInterceptor>().sessionExpired,
      ),
    )
    ..registerLazySingleton<CourseRepository>(() => CourseRepositoryImpl(remote: getIt(), local: getIt()))
    ..registerLazySingleton<QuizRepository>(() => QuizRepositoryImpl(getIt()))
    ..registerLazySingleton<AttemptRepository>(() => AttemptRepositoryImpl(getIt()));

  // --- Blocs --------------------------------------------------------------
  // AuthBloc vit aussi longtemps que l'app (le routeur l'écoute) ;
  // les autres sont créés pour chaque écran (factory).
  getIt
    ..registerLazySingleton(() => AuthBloc(getIt()))
    ..registerFactory(() => LoginCubit(getIt()))
    ..registerFactory(() => CoursesBloc(getIt()))
    ..registerFactory(() => QuizListCubit(getIt()))
    ..registerFactory(() => QuizEditorBloc(getIt()))
    ..registerFactory(() => QuizReportCubit(getIt()))
    ..registerFactory(() => QuizPlayBloc(getIt()))
    ..registerFactory(() => ResultCubit(getIt()))
    ..registerFactory(() => LeaderboardCubit(getIt()))
    ..registerFactory(() => LatestResultCubit(getIt()));
}
