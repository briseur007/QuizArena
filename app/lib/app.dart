import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

/// Largeur maximale du contenu sur grand écran.
const double maxContentWidth = 480;

class QuizArenaApp extends StatefulWidget {
  const QuizArenaApp({super.key});

  @override
  State<QuizArenaApp> createState() => _QuizArenaAppState();
}

class _QuizArenaAppState extends State<QuizArenaApp> {
  late final AuthBloc _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
  late final GoRouter _router = createRouter(_authBloc);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'QuizArena',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
        // Écran large (web, ordinateur) : l'app garde une largeur de téléphone,
        // centrée, comme dans la maquette (390 px). Sans effet sur mobile.
        builder: (context, child) => ColoredBox(
          color: AppColors.segment,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
